# Constantes internas do pacote.

#' Teto do raster enviado ao navegador por `addRasterImage`
#'
#' O default do leaflet e 4 MB e o erro derruba a sessao. Com a agregacao de
#' `.reduzir_para_exibir()` nenhum raster deveria chegar perto deste limite; ele
#' fica como rede de seguranca, ja que a checagem e feita sobre o raster
#' reprojetado para Web Mercator, que pode ser maior que o original.
#'
#' @noRd
MAX_RASTER_BYTES <- 32 * 1024^2

#' Numero de celulas a partir do qual o raster e agregado para exibicao
#'
#' Meio milhao de celulas da um PNG de sobra para a tela e mantem a resposta
#' rapida ao mudar estilo, que redesenha a camada.
#'
#' @noRd
MAX_CELULAS_RASTER <- 5e5

#' Sistema de coordenadas usado na exibicao
#'
#' O leaflet trabalha em Web Mercator, mas espera os dados em graus decimais.
#'
#' @noRd
CRS_EXIBICAO <- 4326
