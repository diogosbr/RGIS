# Paletas, cores e rotulos.

#' Paletas disponiveis para raster
#'
#' Cada entrada recebe o numero de classes e devolve esse numero de cores. As
#' paletas base do R vao do valor alto para o baixo, e por isso sao invertidas:
#' em mapa de adequabilidade o esperado e o valor alto chamar mais atencao.
#'
#' @noRd
.PALETAS_RASTER <- list(
  "terrain.colors" = function(n) rev(grDevices::terrain.colors(n)),
  "topo.colors"    = function(n) rev(grDevices::topo.colors(n)),
  "heat.colors"    = function(n) rev(grDevices::heat.colors(n)),
  "cm.colors"      = function(n) rev(grDevices::cm.colors(n)),
  "rainbow"        = function(n) rev(grDevices::rainbow(n)),
  "nice.colors"    = function(n) {
    grDevices::colorRampPalette(c("deepskyblue", "green", "yellow", "red"))(n)
  }
)

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
#' @param nome Nome da paleta, uma das chaves de `.PALETAS_RASTER`.
#' @param dominio Vetor numerico com a faixa de valores do raster.
#'
#' @return Uma funcao de paleta do leaflet.
#' @noRd
.paleta_raster <- function(nome, dominio) {
  fun <- .PALETAS_RASTER[[nome]]
  if (is.null(fun)) fun <- .PALETAS_RASTER[["terrain.colors"]]
  colorNumeric(fun(25), domain = dominio, na.color = "transparent")
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
