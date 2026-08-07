# Paletas, cores e rotulos.

#' Nomes das paletas oferecidas para raster
#'
#' @noRd
.PALETAS_RASTER <- c(
  "terrain.colors", "topo.colors", "heat.colors",
  "cm.colors", "rainbow", "nice.colors"
)

#' Gera as cores de uma paleta
#'
#' As paletas base do R vao do valor alto para o baixo, e por isso sao
#' invertidas: em mapa de adequabilidade o esperado e o valor alto chamar mais
#' atencao. Nome desconhecido cai no default em vez de gerar erro.
#'
#' @param nome Nome da paleta, um dos valores de `.PALETAS_RASTER`.
#' @param n Numero de classes.
#'
#' @return Vetor de `n` cores.
#' @noRd
.cores_paleta <- function(nome, n = 25) {
  switch(
    nome,
    "topo.colors" = rev(topo.colors(n)),
    "heat.colors" = rev(heat.colors(n)),
    "cm.colors"   = rev(cm.colors(n)),
    "rainbow"     = rev(rainbow(n)),
    "nice.colors" = colorRampPalette(
      c("deepskyblue", "green", "yellow", "red")
    )(n),
    rev(terrain.colors(n))
  )
}

#' Cores oferecidas para contorno e preenchimento de vetor
#'
#' @noRd
.CORES <- c(
  "black", "white", "gray",
  "green", "darkgreen",
  "blue", "darkblue",
  "red", "darkred",
  "orange", "yellow"
)

#' Monta a funcao de cores de um raster
#'
#' @param nome Nome da paleta, um dos valores de `.PALETAS_RASTER`.
#' @param dominio Vetor numerico com a faixa de valores do raster.
#'
#' @return Uma funcao de paleta do leaflet.
#' @noRd
.paleta_raster <- function(nome, dominio) {
  colorNumeric(.cores_paleta(nome), domain = dominio, na.color = "transparent")
}

#' Texto do popup dos pontos
#'
#' @param df Data frame com colunas `lon` e `lat`.
#'
#' @return Vetor de caracteres com uma entrada por ponto.
#' @noRd
.popup_pontos <- function(df) {
  rotulo <- if ("sp" %in% names(df)) paste0("<i>", df$sp, "</i><br>") else ""
  paste0(rotulo, "Longitude: ", df$lon, "<br>Latitude: ", df$lat)
}

#' Texto do popup de uma camada vetorial
#'
#' Paliativo do `popup = ~shape[[input$label]]` da versao antiga, que usava
#' indice cru e podia cair na coluna de geometria. Sera trocado por um
#' `selectInput` com os nomes das colunas (item 10 do roadmap).
#'
#' @param v Objeto `sf`.
#' @param indice Posicao da coluna de atributos escolhida pelo usuario.
#'
#' @return Vetor de caracteres, ou `NULL` se a camada nao tiver atributos.
#' @noRd
.popup_vetor <- function(v, indice) {
  cols <- setdiff(names(v), attr(v, "sf_column"))
  if (length(cols) == 0L) return(NULL)
  i <- suppressWarnings(as.integer(indice))
  if (length(i) != 1L || is.na(i)) i <- 1L
  i <- min(max(1L, i), length(cols))
  paste0("<b>", cols[i], ":</b> ", as.character(v[[cols[i]]]))
}
