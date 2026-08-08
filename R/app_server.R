#' Servidor do RGIS
#'
#' O estado da aplicacao sao tres valores reativos:
#'
#' - `camadas`: a pilha, do topo para a base;
#' - `selecionada`: id da camada cujo estilo esta sendo editado;
#' - `desenhado`: assinaturas do que esta desenhado no mapa agora.
#'
#' O mapa e renderizado uma unica vez. Toda mudanca depois disso passa por
#' `leafletProxy`, comparando `camadas` com `desenhado` e fazendo o minimo de
#' trabalho. E o que permite as camadas coexistirem, coisa que a versao de 2021
#' nao conseguia porque cada botao reconstruia o mapa inteiro.
#'
#' @param input,output,session Objetos do Shiny.
#'
#' @noRd
.app_server <- function(input, output, session) {

  camadas <- reactiveVal(list())
  selecionada <- reactiveVal(NULL)
  desenhado <- reactiveVal(character(0))

  output$mapa <- renderLeaflet(.mapa_base())

  # ---- entrada de dados ------------------------------------------------------

  opcoes_csv <- reactive(list(
    col_lon = input$col_lon,
    col_lat = input$col_lat,
    header = input$header,
    sep = input$sep
  ))

  # Empilha camadas novas, atribuindo ids e avisando o que deu errado.
  absorver <- function(resultado) {
    for (msg in resultado$erros) {
      showNotification(msg, type = "error", duration = 12)
    }
    if (length(resultado$camadas) == 0L) return(invisible(NULL))

    pilha <- camadas()
    ultimo <- NULL
    for (camada in resultado$camadas) {
      camada$id <- .proximo_id(pilha)
      if (isTRUE(camada$crs_assumido)) {
        showNotification(
          paste0("\"", camada$nome, "\" nao declara CRS. Assumi WGS84 / EPSG:4326."),
          type = "warning", duration = 10
        )
      }
      pilha <- .empilhar_camada(pilha, camada)
      ultimo <- camada$id
    }
    camadas(pilha)
    selecionada(ultimo)
    invisible(NULL)
  }

  observeEvent(input$arquivos, {
    req(input$arquivos)
    withProgress(message = "Lendo arquivos", value = 0.5, {
      resultado <- .processar_upload(input$arquivos, opcoes_csv())
    })
    absorver(resultado)
  })

  observeEvent(input$carregar_exemplo, {
    caminhos <- .arquivos_exemplo()
    if (length(caminhos) == 0L) {
      .msg_erro(paste(
        "Os dados de exemplo nao foram encontrados. Eles vem em inst/extdata e",
        "so existem quando o RGIS esta instalado como pacote."
      ))
      return(invisible(NULL))
    }
    upload <- data.frame(
      name = basename(caminhos),
      datapath = caminhos,
      stringsAsFactors = FALSE
    )
    withProgress(message = "Carregando exemplos", value = 0.5, {
      resultado <- .processar_upload(
        upload,
        list(col_lon = "", col_lat = "", header = TRUE, sep = ",")
      )
    })
    absorver(resultado)
  })

  # ---- acoes da lista de camadas ---------------------------------------------

  observeEvent(input$acao_camada, {
    info <- input$acao_camada
    id <- info$id
    pilha <- camadas()
    if (is.na(.indice_camada(pilha, id))) return(invisible(NULL))

    switch(
      info$acao,
      selecionar = selecionada(id),
      visibilidade = camadas(.alterar_camada(pilha, id, function(camada) {
        camada$visivel <- !isTRUE(camada$visivel)
        camada
      })),
      subir = camadas(.mover_camada(pilha, id, -1L)),
      descer = camadas(.mover_camada(pilha, id, 1L)),
      remover = {
        camadas(.remover_camada(pilha, id))
        if (identical(selecionada(), id)) selecionada(NULL)
      },
      enquadrar = {
        caixa <- .extensao_camada(.buscar_camada(pilha, id))
        if (is.null(caixa)) {
          showNotification("Nao consegui calcular a extensao desta camada.",
                           type = "warning")
        } else {
          leafletProxy("mapa", session) |>
            flyToBounds(caixa[["xmin"]], caixa[["ymin"]],
                        caixa[["xmax"]], caixa[["ymax"]])
        }
      }
    )
  })

  # ---- estilo ----------------------------------------------------------------

  # Os inputs de estilo tem o id da camada no nome, entao a lista de dependencias
  # muda junto com a selecao. Um observe() comum resolve isso: ao ler
  # input[[...]] ele se inscreve nos inputs da camada corrente, e so neles.
  observe({
    id <- selecionada()
    if (is.null(id)) return(invisible(NULL))

    entradas <- .entradas_estilo(input, id)
    if (all(vapply(entradas, is.null, logical(1)))) {
      # Painel ainda nao renderizado: nada a aplicar.
      return(invisible(NULL))
    }

    # isolate: ler a pilha de forma reativa faria este observer disparar de novo
    # a cada alteracao que ele mesmo provoca.
    pilha <- isolate(camadas())
    camada <- .buscar_camada(pilha, id)
    if (is.null(camada)) return(invisible(NULL))

    nome <- if (isTRUE(nzchar(entradas$nome))) entradas$nome else camada$nome
    estilo <- .aplicar_entradas(camada$estilo, entradas)
    if (identical(estilo, camada$estilo) && identical(nome, camada$nome)) {
      return(invisible(NULL))
    }
    camadas(.alterar_camada(pilha, id, function(camada) {
      camada$estilo <- estilo
      camada$nome <- nome
      camada
    }))
  })

  # ---- sincronizacao com o mapa ----------------------------------------------

  observe({
    pilha <- camadas()
    proxy <- leafletProxy("mapa", session)
    # isolate: o observer escreve em desenhado, e le-lo de forma reativa criaria
    # um ciclo infinito.
    desenhado(.sincronizar_mapa(proxy, pilha, isolate(desenhado())))
  })

  # ---- paineis ---------------------------------------------------------------

  output$painel_camadas <- renderUI(.lista_camadas(camadas(), selecionada()))

  # isolate em camadas(): o painel so precisa ser remontado quando a selecao
  # muda. Reagir a toda alteracao de estilo faria os controles se recriarem no
  # meio do arrasto do slider.
  output$painel_estilo <- renderUI({
    .painel_estilo(.buscar_camada(isolate(camadas()), selecionada()))
  })
}

#' Le os controles de estilo de uma camada
#'
#' Acessar `input[[nome]]` aqui e o que inscreve o observer nesses inputs, e so
#' nesses. Campo cujo controle nao esta na tela vem como `NULL`.
#'
#' @param input Objeto `input` do Shiny.
#' @param id Id da camada.
#'
#' @return Lista nomeada por `.CAMPOS_ESTILO`.
#' @noRd
.entradas_estilo <- function(input, id) {
  valores <- lapply(.CAMPOS_ESTILO, function(campo) {
    input[[.id_input_estilo(campo, id)]]
  })
  names(valores) <- .CAMPOS_ESTILO
  valores
}

#' Aplica ao estilo os valores lidos da interface
#'
#' So mexe em campos que o estilo atual ja tem, entao um valor sobrando de outro
#' tipo de camada nunca entra.
#'
#' @param estilo Estilo atual da camada.
#' @param entradas Saida de [.entradas_estilo()].
#'
#' @noRd
.aplicar_entradas <- function(estilo, entradas) {
  for (campo in setdiff(names(entradas), "nome")) {
    valor <- entradas[[campo]]
    if (campo %in% names(estilo) && !is.null(valor)) {
      estilo[[campo]] <- valor
    }
  }
  estilo
}
