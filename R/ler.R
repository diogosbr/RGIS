# Leitura e validacao dos tres tipos de entrada.
#
# Convencao destas funcoes: em caso de problema devolvem uma string com a
# mensagem em portugues, em vez de lancar excecao. Quem sabe avisar o usuario e o
# observer, nao a funcao de leitura. Use `is.character()` para distinguir.

#' Le um CSV de ocorrencias
#'
#' Extrai as coordenadas por indice em vez de renomear as colunas: se o arquivo
#' ja tivesse uma coluna chamada `lon`, a renomeacao criava nomes duplicados e o
#' app lia a coluna errada em silencio.
#'
#' @param caminho Caminho do arquivo.
#' @param col_lon,col_lat Nome das colunas de coordenada.
#' @param header O arquivo tem cabecalho.
#' @param sep Separador de coluna.
#'
#' @return Data frame com as colunas `lon` e `lat` mais os demais atributos, ou
#'   uma string com a mensagem de erro.
#' @noRd
.ler_pontos <- function(caminho, col_lon, col_lat, header = TRUE, sep = ",") {
  if (!isTRUE(nzchar(col_lon)) || !isTRUE(nzchar(col_lat))) {
    return("Informe o nome das colunas de longitude e latitude.")
  }
  if (identical(col_lon, col_lat)) {
    return("As colunas de longitude e latitude nao podem ser a mesma.")
  }

  df <- try(
    utils::read.csv(caminho, header = header, sep = sep),
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
    return(paste(
      "Nenhuma coordenada valida no arquivo: as colunas indicadas nao contem",
      "numeros."
    ))
  }
  if (any(abs(lon[validas]) > 180) || any(abs(lat[validas]) > 90)) {
    return(paste(
      "As coordenadas estao fora do intervalo de graus decimais (longitude entre",
      "-180 e 180, latitude entre -90 e 90). O arquivo pode estar em metros, em",
      "um sistema projetado."
    ))
  }

  manter <- setdiff(names(df), c(col_lon, col_lat, "lon", "lat"))
  out <- df[validas, manter, drop = FALSE]
  out$lon <- lon[validas]
  out$lat <- lat[validas]
  out
}

#' Le um raster
#'
#' @param caminho Caminho do arquivo.
#'
#' @return Um `SpatRaster` de uma unica camada, ou uma string com a mensagem de
#'   erro.
#' @noRd
.ler_raster <- function(caminho) {
  r <- try(terra::rast(caminho), silent = TRUE)
  if (inherits(r, "try-error")) {
    return("Nao consegui abrir o arquivo como raster. Formato aceito: GeoTIFF (.tif).")
  }
  if (terra::nlyr(r) > 1L) {
    # Composicao multibanda e desejo, nao v1.0.
    r <- r[[1]]
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

#' Faixa de valores de um raster
#'
#' Calcula minimo e maximo sob demanda. Substitui a chamada antiga a `values()`,
#' que carregava todas as celulas na memoria so para descobrir a faixa.
#'
#' @param r Um `SpatRaster`.
#'
#' @return Vetor numerico de tamanho 2, ou `NULL` se o raster estiver vazio ou
#'   for constante.
#' @noRd
.faixa_valores <- function(r) {
  faixa <- as.numeric(terra::minmax(r, compute = TRUE)[, 1])
  if (!all(is.finite(faixa)) || faixa[1] == faixa[2]) {
    return(NULL)
  }
  faixa
}

#' Le uma camada vetorial e reprojeta para exibicao
#'
#' Quando o CRS esta ausente, assume `CRS_EXIBICAO` e marca o objeto com o
#' atributo `rgis_crs_assumido`, para o observer poder avisar o usuario. Recusar
#' seria mais correto, mas inviabilizaria shapefiles sem `.prj`, que sao comuns.
#' A escolha explicita de EPSG e o item 7 do roadmap.
#'
#' @param caminho Caminho do arquivo.
#'
#' @return Objeto `sf` em WGS84, ou uma string com a mensagem de erro.
#' @noRd
.ler_vetor <- function(caminho) {
  if (!isTRUE(nzchar(caminho)) || !file.exists(caminho)) {
    return("Arquivo nao encontrado. Confira o caminho informado.")
  }
  v <- try(sf::st_read(caminho, quiet = TRUE), silent = TRUE)
  if (inherits(v, "try-error")) {
    return(paste(
      "Nao consegui abrir o arquivo como vetor. Formatos aceitos: .shp, .gpkg,",
      ".geojson, .kml."
    ))
  }
  if (nrow(v) == 0L) {
    return("A camada esta vazia: nenhuma feicao para desenhar.")
  }

  assumido <- FALSE
  if (is.na(sf::st_crs(v))) {
    sf::st_crs(v) <- CRS_EXIBICAO
    assumido <- TRUE
  } else if (sf::st_crs(v) != sf::st_crs(CRS_EXIBICAO)) {
    v <- sf::st_transform(v, CRS_EXIBICAO)
  }
  attr(v, "rgis_crs_assumido") <- assumido
  v
}

#' Classifica a geometria de uma camada vetorial
#'
#' @param v Objeto `sf`.
#'
#' @return `"poligono"`, `"linha"`, `"ponto"`, ou `NULL` quando a camada mistura
#'   tipos ou traz `GEOMETRYCOLLECTION`.
#' @noRd
.classe_geom <- function(v) {
  tipos <- unique(as.character(sf::st_geometry_type(v)))
  if (all(tipos %in% c("POLYGON", "MULTIPOLYGON"))) return("poligono")
  if (all(tipos %in% c("LINESTRING", "MULTILINESTRING"))) return("linha")
  if (all(tipos %in% c("POINT", "MULTIPOINT"))) return("ponto")
  NULL
}
