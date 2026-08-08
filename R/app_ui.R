#' Interface do RGIS
#'
#' Painel de camadas a esquerda, mapa a direita. A entrada de dados e uma so:
#' um seletor de arquivos que descobre o tipo sozinho. As abas por tipo de dado
#' da versao antiga sumiram junto com a ideia de "um plot por vez".
#'
#' @param max_upload_mb Limite de upload, apenas para exibir na aba Ajuda.
#'
#' @return Um objeto de UI do Shiny.
#' @noRd
.app_ui <- function(max_upload_mb = 40) {
  dashboardPage(
    dashboardHeader(title = "RGIS"),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      .estilo_css(),
      fluidRow(
        column(
          width = 3,
          tabsetPanel(
            tabPanel(
              "Camadas",
              tags$br(),
              .bloco_entrada(),
              tags$hr(),
              uiOutput("painel_camadas"),
              tags$hr(),
              uiOutput("painel_estilo")
            ),
            .aba_ajuda(max_upload_mb)
          )
        ),
        column(
          width = 9,
          leafletOutput("mapa", height = "85vh")
        )
      )
    )
  )
}

#' Folha de estilo do painel de camadas
#'
#' Poucas regras, o suficiente para a lista de camadas parecer uma lista e nao
#' um amontoado de botoes.
#'
#' @noRd
.estilo_css <- function() {
  tags$head(tags$style(HTML("
    .rgis-camada {
      display: flex; align-items: center; gap: 6px;
      padding: 4px 6px; border: 1px solid #e3e3e3; border-radius: 3px;
      margin-bottom: 4px; background: #fff;
    }
    .rgis-camada.rgis-sel { border-color: #3c8dbc; background: #f2f8fb; }
    .rgis-nome {
      flex: 1 1 auto; cursor: pointer; overflow: hidden;
      text-overflow: ellipsis; white-space: nowrap;
    }
    .rgis-tipo { color: #999; font-size: 11px; }
    .rgis-acao { color: #666; cursor: pointer; padding: 0 2px; }
    .rgis-acao:hover { color: #3c8dbc; }
    .rgis-vazio { color: #999; font-style: italic; padding: 8px 0; }
  ")))
}

#' Bloco de entrada de dados
#'
#' @noRd
.bloco_entrada <- function() {
  tagList(
    fileInput(
      "arquivos",
      "Adicionar camadas",
      multiple = TRUE,
      accept = c(".csv", ".txt", ".tif", ".tiff", ".shp", ".shx", ".dbf",
                 ".prj", ".cpg", ".gpkg", ".geojson", ".json", ".kml", ".zip"),
      buttonLabel = "Escolher",
      placeholder = "CSV, GeoTIFF, shapefile, GPKG..."
    ),
    actionLink("carregar_exemplo", "Carregar dados de exemplo",
               icon = icon("flask")),
    tags$br(), tags$br(),
    box(
      title = "Opcoes de CSV",
      width = 12,
      collapsible = TRUE,
      collapsed = TRUE,
      helpText(
        "Deixe os nomes em branco para o RGIS descobrir as colunas de",
        "coordenada sozinho."
      ),
      fluidRow(
        column(6, textInput("col_lon", "Longitude", value = "",
                            placeholder = "automatico")),
        column(6, textInput("col_lat", "Latitude", value = "",
                            placeholder = "automatico"))
      ),
      checkboxInput("header", "Tem cabecalho", TRUE),
      radioButtons(
        "sep", "Separador de coluna",
        choices = c(" , " = ",", " ; " = ";", "tab" = "\t"),
        inline = TRUE, selected = ","
      )
    )
  )
}

#' Aba de ajuda
#'
#' @noRd
.aba_ajuda <- function(max_upload_mb) {
  tabPanel(
    "Ajuda",
    tags$br(),
    h4("Como usar"),
    tags$ol(
      tags$li("Clique em Escolher e selecione um ou mais arquivos."),
      tags$li("Cada arquivo vira uma camada, empilhada no topo da lista."),
      tags$li("Clique no nome da camada para editar o estilo dela."),
      tags$li("Use os icones para esconder, reordenar, enquadrar ou remover.")
    ),
    h4("Formatos aceitos"),
    tags$ul(
      tags$li(tags$b("CSV"), ": uma coluna de longitude e uma de latitude em graus decimais."),
      tags$li(tags$b("GeoTIFF"), ": raster continuo, com CRS definido."),
      tags$li(tags$b("Shapefile"), ": envie o .shp junto com .shx, .dbf e .prj, ou tudo em um .zip."),
      tags$li(tags$b("GeoPackage, GeoJSON, KML"), ": um arquivo so.")
    ),
    h4("Bom saber"),
    tags$ul(
      tags$li(paste0("Upload de ate ", max_upload_mb, " MB por arquivo.")),
      tags$li("Camadas em outro sistema de coordenadas sao reprojetadas automaticamente."),
      tags$li("Camada sem CRS definido e tratada como WGS84, com aviso."),
      tags$li("Raster grande e reamostrado para exibicao, sem alterar o arquivo.")
    ),
    tags$p(
      "Codigo e documentacao em ",
      tags$a(href = "https://github.com/diogosbr/RGIS", "github.com/diogosbr/RGIS"),
      "."
    )
  )
}

#' Uma linha da lista de camadas
#'
#' Os botoes nao sao inputs do Shiny. Criar um input por camada exigiria
#' registrar e desregistrar observers a cada mudanca da lista; em vez disso cada
#' icone dispara `Shiny.setInputValue` em um input unico, `acao_camada`, com o
#' id e a acao. Um observer so, no servidor, cuida de tudo.
#'
#' @param camada A camada.
#' @param selecionada A camada esta selecionada para edicao de estilo.
#'
#' @noRd
.linha_camada <- function(camada, selecionada) {
  acao <- function(nome, icone, titulo) {
    tags$span(
      class = "rgis-acao",
      title = titulo,
      onclick = .js_acao(camada$id, nome),
      icon(icone)
    )
  }
  tags$div(
    class = paste("rgis-camada", if (selecionada) "rgis-sel" else ""),
    acao("visibilidade",
         if (isTRUE(camada$visivel)) "eye" else "eye-slash",
         if (isTRUE(camada$visivel)) "Esconder" else "Mostrar"),
    tags$span(
      class = "rgis-nome",
      onclick = .js_acao(camada$id, "selecionar"),
      title = camada$nome,
      camada$nome,
      tags$span(class = "rgis-tipo", paste0(" (", camada$tipo, ")"))
    ),
    acao("subir", "arrow-up", "Subir"),
    acao("descer", "arrow-down", "Descer"),
    acao("enquadrar", "crosshairs", "Enquadrar no mapa"),
    acao("remover", "trash", "Remover")
  )
}

#' JavaScript que envia uma acao de camada para o servidor
#'
#' `priority: 'event'` faz o Shiny disparar mesmo quando o valor repete, o que e
#' necessario para clicar duas vezes seguidas no mesmo botao.
#'
#' @noRd
.js_acao <- function(id, acao) {
  sprintf(
    "Shiny.setInputValue('acao_camada', {id: '%s', acao: '%s'}, {priority: 'event'});",
    id, acao
  )
}

#' Lista de camadas
#'
#' @param pilha Pilha de camadas.
#' @param selecionada Id da camada selecionada, ou `NULL`.
#'
#' @noRd
.lista_camadas <- function(pilha, selecionada) {
  if (length(pilha) == 0L) {
    return(tags$div(
      class = "rgis-vazio",
      "Nenhuma camada ainda. Carregue um arquivo acima."
    ))
  }
  tagList(
    tags$b("Camadas"),
    tags$div(
      style = "margin-top: 6px;",
      lapply(pilha, function(c) {
        .linha_camada(c, identical(c$id, selecionada))
      })
    )
  )
}

#' Campos de estilo que a interface sabe editar
#'
#' @noRd
.CAMPOS_ESTILO <- c(
  "nome", "paleta", "opacidade", "cor", "raio", "espessura",
  "preenchimento", "coluna_popup"
)

#' Id do input de um campo de estilo, para uma camada especifica
#'
#' Os controles de estilo levam o id da camada no proprio nome, em vez de terem
#' ids fixos mais um campo escondido dizendo a quem pertencem. A diferenca
#' aparece com o `sliderInput`, que envia o valor com atraso de 250 ms: soltar o
#' slider de uma camada e clicar em outra dentro desse intervalo faria o valor
#' atrasado chegar quando a selecao ja mudou, e o estilo de uma camada seria
#' aplicado na outra. Com id por camada, esse valor atrasado simplesmente nao e
#' lido por ninguem.
#'
#' @param campo Nome do campo, um dos valores de `.CAMPOS_ESTILO`.
#' @param id Id da camada.
#'
#' @noRd
.id_input_estilo <- function(campo, id) {
  paste0("est_", campo, "_", id)
}

#' Painel de estilo da camada selecionada
#'
#' @param camada A camada selecionada, ou `NULL`.
#'
#' @noRd
.painel_estilo <- function(camada) {
  if (is.null(camada)) {
    return(tags$div(
      class = "rgis-vazio",
      "Clique no nome de uma camada para editar o estilo."
    ))
  }
  controles <- switch(
    camada$tipo,
    raster = .controles_raster(camada),
    ponto = .controles_ponto(camada),
    linha = .controles_linha(camada),
    poligono = .controles_poligono(camada)
  )
  tagList(
    tags$b("Estilo"),
    textInput(.id_input_estilo("nome", camada$id), "Nome", value = camada$nome),
    controles
  )
}

#' @noRd
.seletor_opacidade <- function(camada) {
  sliderInput(
    .id_input_estilo("opacidade", camada$id), "Opacidade",
    min = 0, max = 100, value = camada$estilo$opacidade,
    ticks = FALSE, post = "%"
  )
}

#' @noRd
.seletor_cor <- function(camada, campo, rotulo) {
  selectInput(
    .id_input_estilo(campo, camada$id), rotulo,
    choices = .CORES, selected = camada$estilo[[campo]]
  )
}

#' @noRd
.seletor_popup <- function(camada) {
  cols <- .colunas_atributo(camada$dado)
  if (length(cols) == 0L) return(NULL)
  atual <- camada$estilo$coluna_popup
  selectInput(
    .id_input_estilo("coluna_popup", camada$id), "Coluna do popup",
    choices = cols,
    selected = if (!is.na(atual) && atual %in% cols) atual else cols[1]
  )
}

#' @noRd
.controles_raster <- function(camada) {
  tagList(
    selectInput(
      .id_input_estilo("paleta", camada$id), "Paleta",
      choices = .PALETAS_RASTER, selected = camada$estilo$paleta
    ),
    .seletor_opacidade(camada)
  )
}

#' @noRd
.controles_ponto <- function(camada) {
  tagList(
    .seletor_cor(camada, "cor", "Cor"),
    sliderInput(
      .id_input_estilo("raio", camada$id), "Tamanho",
      min = 1, max = 20, value = camada$estilo$raio, ticks = FALSE
    ),
    .seletor_opacidade(camada),
    .seletor_popup(camada)
  )
}

#' @noRd
.controles_linha <- function(camada) {
  tagList(
    .seletor_cor(camada, "cor", "Cor"),
    sliderInput(
      .id_input_estilo("espessura", camada$id), "Espessura",
      min = 1, max = 10, value = camada$estilo$espessura, ticks = FALSE
    ),
    .seletor_opacidade(camada),
    .seletor_popup(camada)
  )
}

#' @noRd
.controles_poligono <- function(camada) {
  tagList(
    .seletor_cor(camada, "cor", "Contorno"),
    sliderInput(
      .id_input_estilo("espessura", camada$id), "Espessura do contorno",
      min = 0, max = 10, value = camada$estilo$espessura, ticks = FALSE
    ),
    .seletor_cor(camada, "preenchimento", "Preenchimento"),
    .seletor_opacidade(camada),
    .seletor_popup(camada)
  )
}
