# Constantes internas do pacote.

#' Teto do raster enviado ao navegador por `addRasterImage`.
#'
#' O default do leaflet (4 MB) rejeita rasters de tamanho comum em modelagem, e
#' o erro derruba a sessao. Elevar o teto e paliativo: o limite e aplicado ao
#' raster ja reprojetado para Web Mercator, que pode ser maior que o original.
#' A solucao e agregar antes de exibir (item 12 do roadmap).
#'
#' @noRd
MAX_RASTER_BYTES <- 32 * 1024^2

#' Sistema de coordenadas usado na exibicao.
#'
#' O leaflet trabalha em Web Mercator, mas espera dados em graus decimais.
#'
#' @noRd
CRS_EXIBICAO <- 4326
