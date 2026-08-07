# Construcao do mapa e feedback ao usuario.

#' Mapa base, sem camadas de dados
#'
#' @return Um objeto `leaflet`.
#' @noRd
.mapa_base <- function() {
  leaflet() |>
    addTiles() |>
    setView(lng = -50, lat = -12, zoom = 4) |>
    addScaleBar(
      position = "bottomleft",
      options = scaleBarOptions(imperial = FALSE)
    ) |>
    addProviderTiles(providers$Esri.WorldImagery, group = "Satelite") |>
    addProviderTiles(providers$Esri.WorldStreetMap, group = "Streetmap") |>
    addProviderTiles(providers$Esri.WorldTerrain, group = "Terrain") |>
    addProviderTiles(providers$Esri.WorldPhysical, group = "Physical") |>
    addMiniMap(
      tiles = providers$Esri.WorldStreetMap,
      toggleDisplay = TRUE,
      position = "bottomright"
    ) |>
    addMeasure(
      primaryLengthUnit = "meters",
      secondaryLengthUnit = "kilometers",
      primaryAreaUnit = "sqmeters",
      secondaryAreaUnit = "hectares",
      localization = "pt_BR"
    ) |>
    addDrawToolbar(
      targetGroup = "draw",
      editOptions = editToolbarOptions(
        selectedPathOptions = selectedPathOptions()
      ),
      polylineOptions = drawShapeOptions(),
      polygonOptions = drawShapeOptions(),
      circleOptions = drawShapeOptions(),
      rectangleOptions = drawShapeOptions()
    )
}

#' Adiciona o controle de camadas
#'
#' @param map Objeto `leaflet`.
#' @param extras Nomes dos grupos de dados presentes no mapa.
#'
#' @noRd
.controle_camadas <- function(map, extras = character(0)) {
  addLayersControl(
    map,
    baseGroups = c("Satelite", "Streetmap", "Terrain", "Physical"),
    overlayGroups = c("draw", extras),
    options = layersControlOptions(collapsed = FALSE)
  )
}

#' Mostra um erro ao usuario
#'
#' @param msg Texto da mensagem.
#' @param titulo Titulo da caixa.
#'
#' @noRd
.msg_erro <- function(msg, titulo = "Nao foi possivel continuar") {
  shinyalert(
    titulo, msg,
    type = "error",
    confirmButtonCol = "darkgreen",
    closeOnClickOutside = TRUE
  )
}

#' Desenha o mapa capturando erros do leaflet
#'
#' `addRasterImage` lanca erro quando o PNG estoura `MAX_RASTER_BYTES` ou quando
#' a reprojecao para Web Mercator falha. Sem este envelope o usuario ve a tela
#' vermelha do Shiny em vez da mensagem em portugues usada nos outros caminhos.
#'
#' @param output Objeto `output` do Shiny.
#' @param expr Expressao que devolve o mapa. Avaliada aqui dentro.
#'
#' @noRd
.render_mapa <- function(output, expr) {
  mapa <- tryCatch(
    expr,
    error = function(e) {
      .msg_erro(conditionMessage(e), "Erro ao desenhar o mapa")
      NULL
    }
  )
  if (!is.null(mapa)) {
    output$mymap <- renderLeaflet(mapa)
  }
  invisible(NULL)
}
