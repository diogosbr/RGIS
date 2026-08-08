# Mapa base, desenho das camadas e sincronizacao incremental.

#' Mapa base, sem camadas de dados
#'
#' Renderizado uma unica vez por sessao. Tudo que vem depois passa por
#' `leafletProxy`, e nunca por um novo `renderLeaflet`: e isso que faz as
#' camadas coexistirem.
#'
#' @return Um objeto `leaflet`.
#' @noRd
.mapa_base <- function() {
  leaflet() |>
    addTiles(group = "OpenStreetMap") |>
    setView(lng = -50, lat = -12, zoom = 4) |>
    addProviderTiles(providers$Esri.WorldImagery, group = "Satelite") |>
    addProviderTiles(providers$Esri.WorldStreetMap, group = "Streetmap") |>
    addProviderTiles(providers$Esri.WorldTerrain, group = "Relevo") |>
    addScaleBar(
      position = "bottomleft",
      options = scaleBarOptions(imperial = FALSE)
    ) |>
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
      targetGroup = "desenho",
      editOptions = editToolbarOptions(
        selectedPathOptions = selectedPathOptions()
      ),
      polylineOptions = drawShapeOptions(),
      polygonOptions = drawShapeOptions(),
      circleOptions = drawShapeOptions(),
      rectangleOptions = drawShapeOptions()
    ) |>
    addLayersControl(
      baseGroups = c("OpenStreetMap", "Satelite", "Streetmap", "Relevo"),
      overlayGroups = "desenho",
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

#' Identificador do controle de legenda de uma camada
#'
#' @noRd
.id_legenda <- function(id) {
  paste0("legenda_", id)
}

#' Apaga uma camada do mapa
#'
#' @noRd
.apagar_camada <- function(proxy, id) {
  proxy |>
    clearGroup(id) |>
    removeControl(.id_legenda(id))
}

#' Desenha uma camada no mapa
#'
#' Camada invisivel nao e desenhada: e o mesmo caminho de remover, e evita
#' manter no navegador dado que ninguem esta vendo.
#'
#' @param proxy Objeto de `leafletProxy()`.
#' @param camada A camada.
#'
#' @noRd
.desenhar_camada <- function(proxy, camada) {
  if (!isTRUE(camada$visivel)) return(invisible(proxy))
  # Sem esta captura, um erro do leaflet (maxBytes estourado, falha de
  # reprojecao) sobe antes de o estado desenhado ser atualizado, e a
  # sincronizacao passa a comparar com um estado velho em toda acao seguinte.
  resultado <- try(
    switch(
      camada$tipo,
      raster = .desenhar_raster(proxy, camada),
      ponto = .desenhar_ponto(proxy, camada),
      linha = .desenhar_linha(proxy, camada),
      poligono = .desenhar_poligono(proxy, camada)
    ),
    silent = TRUE
  )
  if (inherits(resultado, "try-error")) {
    showNotification(
      paste0("Nao consegui desenhar \"", camada$nome, "\": ",
             conditionMessage(attr(resultado, "condition"))),
      type = "error",
      duration = 12
    )
  }
  invisible(proxy)
}

#' @noRd
.desenhar_raster <- function(proxy, camada) {
  faixa <- camada$faixa
  if (is.null(faixa)) return(invisible(proxy))
  pal <- .paleta_raster(camada$estilo$paleta, faixa)
  proxy |>
    addRasterImage(
      camada$dado,
      colors = pal,
      opacity = camada$estilo$opacidade / 100,
      group = camada$id,
      maxBytes = MAX_RASTER_BYTES
    ) |>
    addLegend(
      pal = pal,
      values = faixa,
      title = camada$nome,
      layerId = .id_legenda(camada$id),
      position = "bottomright"
    )
}

#' @noRd
.desenhar_ponto <- function(proxy, camada) {
  addCircleMarkers(
    proxy,
    data = camada$dado,
    radius = camada$estilo$raio,
    stroke = FALSE,
    fillColor = camada$estilo$cor,
    fillOpacity = camada$estilo$opacidade / 100,
    group = camada$id,
    popup = .popup_camada(camada$dado, camada$estilo$coluna_popup),
    popupOptions = popupOptions(closeButton = TRUE)
  )
}

#' @noRd
.desenhar_linha <- function(proxy, camada) {
  addPolylines(
    proxy,
    data = camada$dado,
    weight = camada$estilo$espessura,
    color = camada$estilo$cor,
    opacity = camada$estilo$opacidade / 100,
    group = camada$id,
    popup = .popup_camada(camada$dado, camada$estilo$coluna_popup),
    highlightOptions = highlightOptions(
      weight = camada$estilo$espessura + 3,
      color = "red",
      bringToFront = TRUE
    )
  )
}

#' @noRd
.desenhar_poligono <- function(proxy, camada) {
  addPolygons(
    proxy,
    data = camada$dado,
    smoothFactor = 1,
    weight = camada$estilo$espessura,
    color = camada$estilo$cor,
    opacity = 1,
    fillColor = camada$estilo$preenchimento,
    fillOpacity = camada$estilo$opacidade / 100,
    group = camada$id,
    popup = .popup_camada(camada$dado, camada$estilo$coluna_popup),
    highlightOptions = highlightOptions(
      weight = camada$estilo$espessura + 3,
      color = "red",
      fillOpacity = 0.7,
      bringToFront = TRUE
    )
  )
}

#' Poe o mapa em dia com a pilha de camadas
#'
#' Compara as assinaturas de antes e de agora e faz o minimo de trabalho:
#'
#' - se a sequencia de ids nao mudou, redesenha so as camadas cuja assinatura
#'   mudou (estilo ou visibilidade);
#' - se camadas novas apareceram no topo e o resto continua igual, desenha so as
#'   novas, que por serem desenhadas depois ficam por cima;
#' - em qualquer outro caso (remocao, reordenacao), apaga tudo e redesenha na
#'   ordem, que e a unica forma de acertar a sobreposicao.
#'
#' @param proxy Objeto de `leafletProxy()`.
#' @param pilha Pilha de camadas, do topo para a base.
#' @param antes Assinaturas do estado desenhado.
#'
#' @return As assinaturas do novo estado.
#' @noRd
.sincronizar_mapa <- function(proxy, pilha, antes) {
  agora <- .assinaturas(pilha)
  # names() de um vetor vazio e NULL, e NULL nao e identico a character(0):
  # sem normalizar, o primeiro upload cairia no caminho errado.
  ids_antes <- if (is.null(names(antes))) character(0) else names(antes)
  ids_agora <- if (is.null(names(agora))) character(0) else names(agora)
  # A pilha guarda do topo para a base, e desenhar por ultimo poe por cima.
  ordem_desenho <- rev(seq_along(pilha))

  if (identical(ids_antes, ids_agora)) {
    mudaram <- ids_agora[antes[ids_agora] != agora[ids_agora]]
    if (length(mudaram) == 0L) return(agora)
    # Redesenhar anexa a camada no fim do painel de sobreposicao, ou seja, por
    # cima de tudo. Entao nao basta refazer a que mudou: e preciso refazer
    # tambem todas as que estao acima dela, ou a mais funda passa na frente.
    fundo <- max(which(ids_agora %in% mudaram))
    for (i in rev(seq_len(fundo))) {
      .apagar_camada(proxy, pilha[[i]]$id)
      .desenhar_camada(proxy, pilha[[i]])
    }
    return(agora)
  }

  novas_no_topo <- length(ids_agora) > length(ids_antes) &&
    identical(utils::tail(ids_agora, length(ids_antes)), ids_antes) &&
    identical(unname(antes), unname(agora[ids_antes]))

  if (novas_no_topo) {
    n <- length(ids_agora) - length(ids_antes)
    for (i in rev(seq_len(n))) {
      .desenhar_camada(proxy, pilha[[i]])
    }
    return(agora)
  }

  for (id in ids_antes) {
    .apagar_camada(proxy, id)
  }
  for (i in ordem_desenho) {
    .desenhar_camada(proxy, pilha[[i]])
  }
  agora
}
