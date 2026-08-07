# RGIS: logica do servidor
#
# Backend espacial: sf (vetor) + terra (raster).
#
# NOTA DE ARQUITETURA: cada observeEvent abaixo ainda reconstroi o mapa inteiro
# a partir de m_base, o que faz uma camada apagar a outra. Isso e intencionalmente
# preservado neste passo, que trata apenas da troca de backend espacial.
# A correcao (lista de camadas reativa + leafletProxy) e o item 3 da fase 1
# do ROADMAP.md e vai reescrever este arquivo.

# ---- helpers -----------------------------------------------------------------
# Mudam de casa para R/ quando o projeto virar pacote (fase 1, item 2).

# Paletas para raster. Cada entrada recebe n e devolve n cores.
.rgis_paletas <- list(
  "terrain.colors" = function(n) rev(grDevices::terrain.colors(n)),
  "topo.colors"    = function(n) rev(grDevices::topo.colors(n)),
  "heat.colors"    = function(n) rev(grDevices::heat.colors(n)),
  "cm.colors"      = function(n) rev(grDevices::cm.colors(n)),
  "rainbow"        = function(n) rev(grDevices::rainbow(n)),
  "nice.colors"    = function(n) {
    grDevices::colorRampPalette(c("deepskyblue", "green", "yellow", "red"))(n)
  }
)

.rgis_paleta_raster <- function(nome, dominio) {
  fun <- .rgis_paletas[[nome]]
  if (is.null(fun)) fun <- .rgis_paletas[["terrain.colors"]]
  leaflet::colorNumeric(fun(25), domain = dominio, na.color = "transparent")
}

.rgis_erro <- function(msg, titulo = "Nao foi possivel continuar") {
  shinyalert::shinyalert(
    titulo, msg,
    type = "error",
    confirmButtonCol = "darkgreen",
    closeOnClickOutside = TRUE
  )
}

#' Desenha o mapa capturando erros do leaflet.
#'
#' addRasterImage lanca erro quando o PNG estoura maxBytes ou quando a
#' reprojecao para Web Mercator falha. Sem isso o usuario ve a tela vermelha do
#' Shiny em vez da mensagem em portugues usada nos outros caminhos.
.rgis_render_mapa <- function(output, expr) {
  mapa <- tryCatch(
    expr,
    error = function(e) {
      .rgis_erro(conditionMessage(e), "Erro ao desenhar o mapa")
      NULL
    }
  )
  if (!is.null(mapa)) {
    output$mymap <- leaflet::renderLeaflet(mapa)
  }
  invisible(NULL)
}

#' Le um raster e devolve um SpatRaster de uma unica camada, ou uma string de erro.
#'
#' Devolver a mensagem em vez de lancar excecao mantem o tratamento de erro no
#' observer, que e quem sabe avisar o usuario.
.rgis_ler_raster <- function(caminho) {
  r <- try(terra::rast(caminho), silent = TRUE)
  if (inherits(r, "try-error")) {
    return("Nao consegui abrir o arquivo como raster. Formato aceito: GeoTIFF (.tif).")
  }
  if (terra::nlyr(r) > 1L) {
    r <- r[[1]]  # composicao multibanda e desejo, nao v1.0
  }
  if (!nzchar(terra::crs(r))) {
    return(paste(
      "O raster nao tem sistema de coordenadas (CRS) definido, entao nao da para",
      "posiciona-lo no mapa. Defina o CRS no arquivo de origem e tente de novo."
    ))
  }
  if (any(terra::is.factor(r))) {
    return(paste(
      "Este raster e categorico. O suporte a rasters categoricos ainda nao foi",
      "implementado (item 12 do roadmap)."
    ))
  }
  r
}

#' Faixa de valores do raster, calculada sob demanda.
#'
#' Substitui a chamada antiga a values(), que carregava todas as celulas na
#' memoria so para descobrir minimo e maximo.
.rgis_faixa <- function(r) {
  faixa <- as.numeric(terra::minmax(r, compute = TRUE)[, 1])
  if (!all(is.finite(faixa)) || faixa[1] == faixa[2]) {
    return(NULL)
  }
  faixa
}

#' Le um vetor com sf, reprojeta para WGS84 e devolve o objeto ou string de erro.
#'
#' Quando o CRS esta ausente, assume EPSG:4326 e marca o objeto com o atributo
#' `rgis_crs_assumido`, para o observer poder avisar o usuario. Recusar seria
#' mais correto, mas quebraria os proprios shapefiles de exemplo (que nao tem
#' .prj). A escolha explicita de EPSG e o item 7 do roadmap.
.rgis_ler_vetor <- function(caminho) {
  if (!isTRUE(nzchar(caminho)) || !file.exists(caminho)) {
    return("Arquivo nao encontrado. Confira o caminho informado.")
  }
  v <- try(sf::st_read(caminho, quiet = TRUE), silent = TRUE)
  if (inherits(v, "try-error")) {
    return("Nao consegui abrir o arquivo como vetor. Formatos aceitos: .shp, .gpkg, .geojson, .kml.")
  }
  assumido <- FALSE
  if (is.na(sf::st_crs(v))) {
    sf::st_crs(v) <- 4326
    assumido <- TRUE
  } else if (sf::st_crs(v) != sf::st_crs(4326)) {
    v <- sf::st_transform(v, 4326)
  }
  attr(v, "rgis_crs_assumido") <- assumido
  v
}

#' Classifica a geometria em poligono, linha ou ponto.
#'
#' Devolve NULL quando a camada mistura tipos ou traz GEOMETRYCOLLECTION.
.rgis_classe_geom <- function(v) {
  tipos <- unique(as.character(sf::st_geometry_type(v)))
  if (all(tipos %in% c("POLYGON", "MULTIPOLYGON"))) return("poligono")
  if (all(tipos %in% c("LINESTRING", "MULTILINESTRING"))) return("linha")
  if (all(tipos %in% c("POINT", "MULTIPOINT"))) return("ponto")
  NULL
}

#' Rotulo de popup a partir do indice de coluna escolhido pelo usuario.
#'
#' Paliativo do `popup = ~shape[[input$label]]` original, que usava indice cru e
#' podia cair na coluna de geometria. Sera trocado por um selectInput com os
#' nomes das colunas (fase 3, item 10).
.rgis_popup_vetor <- function(v, indice) {
  cols <- setdiff(names(v), attr(v, "sf_column"))
  if (length(cols) == 0L) return(NULL)
  i <- suppressWarnings(as.integer(indice))
  if (length(i) != 1L || is.na(i)) i <- 1L
  i <- min(max(1L, i), length(cols))
  paste0("<b>", cols[i], ":</b> ", as.character(v[[cols[i]]]))
}

.rgis_controle_camadas <- function(map, extras = character(0)) {
  leaflet::addLayersControl(
    map,
    baseGroups = c("Satelite", "Streetmap", "Terrain", "Physical"),
    overlayGroups = c("draw", extras),
    options = leaflet::layersControlOptions(collapsed = FALSE)
  )
}

# ---- server ------------------------------------------------------------------

server <- function(input, output, session) {

  # Selecao do shape pelo disco.
  # ATENCAO: file.choose() abre o dialogo na maquina onde o R esta rodando, ou
  # seja, funciona local e quebra em deploy web. Sera substituido pela entrada
  # unica de arquivos (fase 2, item 6).
  observeEvent(input$shape_path_button, {
    caminho <- try(file.choose(), silent = TRUE)
    if (!inherits(caminho, "try-error")) {
      updateTextInput(session, "shape_path", value = caminho)
    }
  })

  # MAPA base ####
  m_base <- leaflet() %>%
    addTiles() %>%
    setView(lng = -50, lat = -12, zoom = 4) %>%
    addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = FALSE)) %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satelite") %>%
    addProviderTiles(providers$Esri.WorldStreetMap, group = "Streetmap") %>%
    addProviderTiles(providers$Esri.WorldTerrain, group = "Terrain") %>%
    addProviderTiles(providers$Esri.WorldPhysical, group = "Physical") %>%
    addMiniMap(
      tiles = providers$Esri.WorldStreetMap,
      toggleDisplay = TRUE,
      position = "bottomright"
    ) %>%
    addMeasure(
      primaryLengthUnit = "meters",
      secondaryLengthUnit = "kilometers",
      primaryAreaUnit = "sqmeters",
      secondaryAreaUnit = "hectares",
      localization = "pt_BR"
    ) %>%
    addDrawToolbar(
      targetGroup = "draw",
      editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions()),
      polylineOptions = drawShapeOptions(),
      polygonOptions = drawShapeOptions(),
      circleOptions = drawShapeOptions(),
      rectangleOptions = drawShapeOptions()
    )

  output$mymap <- renderLeaflet({
    m_base %>%
      .rgis_controle_camadas() %>%
      addStyleEditor()
  })

  # Leitura do CSV de pontos ####
  # Devolve um data.frame com colunas lon/lat padronizadas, ou string de erro.
  # As colunas sao extraidas por indice e reanexadas, em vez de renomeadas: se o
  # arquivo ja tivesse uma coluna chamada lon, a renomeacao criava nomes
  # duplicados e df$lon devolvia a coluna errada em silencio.
  ler_pontos <- function() {
    if (is.null(input$file1)) {
      return("Nenhum arquivo CSV foi carregado na aba CSV.")
    }
    col_lon <- input$lon
    col_lat <- input$lat
    if (!isTRUE(nzchar(col_lon)) || !isTRUE(nzchar(col_lat))) {
      return("Informe o nome das colunas de longitude e latitude.")
    }
    if (identical(col_lon, col_lat)) {
      return("As colunas de longitude e latitude nao podem ser a mesma.")
    }
    df <- try(
      utils::read.csv(input$file1$datapath, header = input$header, sep = input$sep),
      silent = TRUE
    )
    if (inherits(df, "try-error") || nrow(df) == 0L) {
      return("Nao consegui ler o CSV. Confira o separador de coluna e o cabecalho.")
    }
    faltando <- setdiff(c(col_lon, col_lat), names(df))
    if (length(faltando) > 0L) {
      return(paste0(
        "Coluna nao encontrada: ", paste(faltando, collapse = ", "),
        ". Colunas disponiveis no arquivo: ", paste(names(df), collapse = ", "), "."
      ))
    }
    lon <- suppressWarnings(as.numeric(df[[col_lon]]))
    lat <- suppressWarnings(as.numeric(df[[col_lat]]))
    validas <- is.finite(lon) & is.finite(lat)
    if (!any(validas)) {
      return("Nenhuma coordenada valida no arquivo: as colunas indicadas nao contem numeros.")
    }
    manter <- setdiff(names(df), c(col_lon, col_lat, "lon", "lat"))
    out <- df[validas, manter, drop = FALSE]
    out$lon <- lon[validas]
    out$lat <- lat[validas]
    out
  }

  popup_pontos <- function(df) {
    rotulo <- if ("sp" %in% names(df)) paste0("<i>", df$sp, "</i><br>") else ""
    paste0(rotulo, "Longitude: ", df$lon, "<br>Latitude: ", df$lat)
  }

  # plot points ####
  observeEvent(input$plot_point, {
    df <- ler_pontos()
    if (is.character(df)) {
      .rgis_erro(df)
      return(invisible(NULL))
    }

    output$df <- renderTable(head(df))

    .rgis_render_mapa(output, {
      m_base %>%
        addMarkers(
          data = df, ~lon, ~lat,
          group = "points",
          popup = popup_pontos(df),
          popupOptions = popupOptions(closeButton = TRUE)
        ) %>%
        .rgis_controle_camadas("points") %>%
        addStyleEditor()
    })
  })

  # Raster escolhido na aba Raster, ja validado. Devolve list(r, faixa, pal) ou
  # uma string de erro.
  preparar_raster <- function() {
    if (is.null(input$file2)) {
      return("Nenhum raster foi carregado na aba Raster.")
    }
    r <- .rgis_ler_raster(input$file2$datapath)
    if (is.character(r)) return(r)
    faixa <- .rgis_faixa(r)
    if (is.null(faixa)) {
      return("O raster nao tem valores validos para colorir: esta vazio ou e constante.")
    }
    list(r = r, faixa = faixa, pal = .rgis_paleta_raster(input$col_raster, faixa))
  }

  # plot raster ####
  observeEvent(input$plot_raster, {
    ras <- preparar_raster()
    if (is.character(ras)) {
      .rgis_erro(ras)
      return(invisible(NULL))
    }

    .rgis_render_mapa(output, {
      m_base %>%
        addRasterImage(
          ras$r,
          colors = ras$pal,
          opacity = input$alpha / 100,
          group = "raster",
          maxBytes = .rgis_max_raster_bytes
        ) %>%
        addLegend(pal = ras$pal, values = ras$faixa, title = "Legenda") %>%
        .rgis_controle_camadas("raster") %>%
        addStyleEditor()
    })
  })

  # add points ####
  observeEvent(input$add_point, {
    df <- ler_pontos()
    if (is.character(df)) {
      .rgis_erro(df)
      return(invisible(NULL))
    }
    ras <- preparar_raster()
    if (is.character(ras)) {
      .rgis_erro(ras)
      return(invisible(NULL))
    }

    .rgis_render_mapa(output, {
      m_base %>%
        addRasterImage(
          ras$r,
          colors = ras$pal,
          opacity = input$alpha / 100,
          group = "raster",
          maxBytes = .rgis_max_raster_bytes
        ) %>%
        addLegend(pal = ras$pal, values = ras$faixa, title = "Legenda") %>%
        addMarkers(
          data = df, ~lon, ~lat,
          group = "points",
          popup = popup_pontos(df),
          popupOptions = popupOptions(closeButton = TRUE)
        ) %>%
        .rgis_controle_camadas(c("raster", "points")) %>%
        addStyleEditor()
    })
  })

  # plot shape ####
  observeEvent(input$plot_shape, {
    v <- .rgis_ler_vetor(input$shape_path)
    if (is.character(v)) {
      .rgis_erro(v)
      return(invisible(NULL))
    }
    classe <- .rgis_classe_geom(v)
    if (is.null(classe)) {
      .rgis_erro(paste0(
        "Esta camada mistura tipos de geometria ou traz GEOMETRYCOLLECTION, ",
        "que ainda nao e suportado. Geometrias encontradas: ",
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

    popup <- .rgis_popup_vetor(v, input$label)

    .rgis_render_mapa(output, {
      mapa <- switch(
        classe,
        poligono = addPolygons(
          m_base,
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
          m_base,
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
          m_base,
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
      mapa %>%
        .rgis_controle_camadas("vetor") %>%
        addStyleEditor()
    })
  })
}
