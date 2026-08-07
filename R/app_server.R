#' Servidor do RGIS
#'
#' NOTA DE ARQUITETURA: cada observer abaixo reconstroi o mapa a partir de
#' `.mapa_base()`, o que faz uma camada apagar a outra. E o defeito central
#' herdado da versao de 2021 e sera corrigido no item 3 do roadmap, com uma lista
#' de camadas reativa e `leafletProxy`. Esta versao mantem o comportamento antigo
#' de proposito: o passo atual foi virar pacote, nao mudar o modelo de camadas.
#'
#' @param input,output,session Objetos do Shiny.
#'
#' @noRd
.app_server <- function(input, output, session) {

  # Selecao do shape pelo disco.
  # ATENCAO: file.choose() abre o dialogo na maquina onde o R esta rodando, ou
  # seja, funciona local e quebra em deploy web. Sera substituido pela entrada
  # unica de arquivos (item 6 do roadmap).
  observeEvent(input$shape_path_button, {
    caminho <- try(file.choose(), silent = TRUE)
    if (!inherits(caminho, "try-error")) {
      updateTextInput(session, "shape_path", value = caminho)
    }
  })

  output$mymap <- renderLeaflet({
    .mapa_base() |>
      .controle_camadas() |>
      addStyleEditor()
  })

  # Pontos do CSV, ja validados. Devolve data frame ou string de erro.
  pontos <- function() {
    if (is.null(input$file1)) {
      return("Nenhum arquivo CSV foi carregado na aba CSV.")
    }
    .ler_pontos(
      caminho = input$file1$datapath,
      col_lon = input$lon,
      col_lat = input$lat,
      header = input$header,
      sep = input$sep
    )
  }

  # Raster da aba Raster, ja validado. Devolve list(r, faixa, pal) ou string de
  # erro.
  raster_pronto <- function() {
    if (is.null(input$file2)) {
      return("Nenhum raster foi carregado na aba Raster.")
    }
    r <- .ler_raster(input$file2$datapath)
    if (is.character(r)) return(r)
    faixa <- .faixa_valores(r)
    if (is.null(faixa)) {
      return("O raster nao tem valores validos para colorir: esta vazio ou e constante.")
    }
    list(r = r, faixa = faixa, pal = .paleta_raster(input$col_raster, faixa))
  }

  camada_pontos <- function(map, df) {
    addMarkers(
      map,
      data = df, ~lon, ~lat,
      group = "points",
      popup = .popup_pontos(df),
      popupOptions = popupOptions(closeButton = TRUE)
    )
  }

  camada_raster <- function(map, ras) {
    map |>
      addRasterImage(
        ras$r,
        colors = ras$pal,
        opacity = input$alpha / 100,
        group = "raster",
        maxBytes = MAX_RASTER_BYTES
      ) |>
      addLegend(pal = ras$pal, values = ras$faixa, title = "Legenda")
  }

  # Pontos ####
  observeEvent(input$plot_point, {
    df <- pontos()
    if (is.character(df)) {
      .msg_erro(df)
      return(invisible(NULL))
    }

    output$df <- renderTable(utils::head(df))

    .render_mapa(output, {
      .mapa_base() |>
        camada_pontos(df) |>
        .controle_camadas("points") |>
        addStyleEditor()
    })
  })

  # Raster ####
  observeEvent(input$plot_raster, {
    ras <- raster_pronto()
    if (is.character(ras)) {
      .msg_erro(ras)
      return(invisible(NULL))
    }

    .render_mapa(output, {
      .mapa_base() |>
        camada_raster(ras) |>
        .controle_camadas("raster") |>
        addStyleEditor()
    })
  })

  # Raster somado aos pontos ####
  # Paliativo ate a pilha de camadas existir (item 3 do roadmap).
  observeEvent(input$add_point, {
    df <- pontos()
    if (is.character(df)) {
      .msg_erro(df)
      return(invisible(NULL))
    }
    ras <- raster_pronto()
    if (is.character(ras)) {
      .msg_erro(ras)
      return(invisible(NULL))
    }

    .render_mapa(output, {
      .mapa_base() |>
        camada_raster(ras) |>
        camada_pontos(df) |>
        .controle_camadas(c("raster", "points")) |>
        addStyleEditor()
    })
  })

  # Vetor ####
  observeEvent(input$plot_shape, {
    v <- .ler_vetor(input$shape_path)
    if (is.character(v)) {
      .msg_erro(v)
      return(invisible(NULL))
    }
    classe <- .classe_geom(v)
    if (is.null(classe)) {
      .msg_erro(paste0(
        "Esta camada mistura tipos de geometria ou traz GEOMETRYCOLLECTION, que ",
        "ainda nao e suportado. Geometrias encontradas: ",
        paste(unique(as.character(sf::st_geometry_type(v))), collapse = ", "), "."
      ))
      return(invisible(NULL))
    }
    if (isTRUE(attr(v, "rgis_crs_assumido"))) {
      showNotification(
        "O arquivo nao tem CRS definido (falta o .prj). Assumi WGS84 / EPSG:4326.",
        type = "warning",
        duration = 8
      )
    }

    popup <- .popup_vetor(v, input$label)

    .render_mapa(output, {
      mapa <- switch(
        classe,
        poligono = addPolygons(
          .mapa_base(),
          data = v,
          stroke = input$stroke,
          smoothFactor = 1,
          weight = 1,
          fill = input$fill,
          fillOpacity = input$fillopacity / 100,
          fillColor = input$col_vec,
          opacity = 1,
          color = input$cor,
          group = "vetor",
          highlightOptions = highlightOptions(
            weight = 4,
            color = "red",
            fillOpacity = 0.7,
            bringToFront = TRUE
          ),
          popup = popup
        ),
        linha = addPolylines(
          .mapa_base(),
          data = v,
          weight = 2,
          opacity = 1,
          color = input$cor,
          group = "vetor",
          highlightOptions = highlightOptions(
            weight = 5,
            color = "red",
            bringToFront = TRUE
          ),
          popup = popup
        ),
        ponto = addCircleMarkers(
          .mapa_base(),
          data = v,
          radius = 4,
          stroke = input$stroke,
          weight = 1,
          color = input$cor,
          fill = input$fill,
          fillColor = input$col_vec,
          fillOpacity = input$fillopacity / 100,
          group = "vetor",
          popup = popup
        )
      )
      mapa |>
        .controle_camadas("vetor") |>
        addStyleEditor()
    })
  })
}
