# Leitura e validacao dos dados.
#
# Convencao destas funcoes: em caso de problema devolvem uma string com a
# mensagem em portugues, em vez de lancar excecao. Quem sabe avisar o usuario e
# quem chamou, nao a funcao de leitura. Use `is.character()` para distinguir.

#' Nomes de coluna comumente usados para coordenada
#'
#' Cobre o que aparece em exportacoes do GBIF, do speciesLink e de planilhas
#' feitas a mao.
#'
#' @noRd
.CANDIDATOS_LON <- c(
  "lon", "long", "lng", "longitude", "x", "coordx", "xcoord",
  "decimallongitude", "longitudedecimal"
)

#' Nomes de coluna comumente usados para latitude
#'
#' @noRd
.CANDIDATOS_LAT <- c(
  "lat", "latitude", "y", "coordy", "ycoord",
  "decimallatitude", "latitudedecimal"
)

#' Descobre a coluna de coordenada pelo nome
#'
#' A comparacao ignora caixa e pontuacao, entao `decimalLongitude`,
#' `decimal_longitude` e `DECIMALLONGITUDE` caem no mesmo lugar.
#'
#' @param nomes Nomes das colunas do arquivo.
#' @param candidatos Vetor de nomes aceitos, em minusculas.
#'
#' @return O nome original da coluna, ou `NA_character_`.
#' @noRd
.detectar_coluna <- function(nomes, candidatos) {
  normalizados <- tolower(gsub("[^a-z]", "", tolower(nomes)))
  pos <- match(candidatos, normalizados)
  pos <- pos[!is.na(pos)]
  if (length(pos) == 0L) return(NA_character_)
  nomes[pos[1]]
}

#' Le um CSV de ocorrencias e devolve pontos
#'
#' As coordenadas sao extraidas por indice e o resultado e montado do zero, em
#' vez de renomear colunas: se o arquivo ja tivesse uma coluna chamada `lon`, a
#' renomeacao criava nomes duplicados e o app lia a coluna errada em silencio.
#'
#' @param caminho Caminho do arquivo.
#' @param col_lon,col_lat Nome das colunas de coordenada. Vazio ou `NA` pede
#'   deteccao automatica.
#' @param header O arquivo tem cabecalho.
#' @param sep Separador de coluna.
#'
#' @return Objeto `sf` de pontos em EPSG:4326, ou uma string com o erro.
#' @noRd
.ler_pontos <- function(caminho, col_lon = NA, col_lat = NA,
                        header = TRUE, sep = ",") {
  df <- try(
    utils::read.csv(caminho, header = header, sep = sep,
                    stringsAsFactors = FALSE),
    silent = TRUE
  )
  if (inherits(df, "try-error") || nrow(df) == 0L || ncol(df) < 2L) {
    return("Nao consegui ler o CSV. Confira o separador de coluna e o cabecalho.")
  }

  if (!isTRUE(nzchar(col_lon)) || is.na(col_lon)) {
    col_lon <- .detectar_coluna(names(df), .CANDIDATOS_LON)
  }
  if (!isTRUE(nzchar(col_lat)) || is.na(col_lat)) {
    col_lat <- .detectar_coluna(names(df), .CANDIDATOS_LAT)
  }
  if (is.na(col_lon) || is.na(col_lat)) {
    return(paste0(
      "Nao identifiquei as colunas de coordenada. Informe os nomes na caixa ",
      "\"Opcoes de CSV\". Colunas do arquivo: ",
      paste(names(df), collapse = ", "), "."
    ))
  }
  if (identical(col_lon, col_lat)) {
    return("As colunas de longitude e latitude nao podem ser a mesma.")
  }
  faltando <- setdiff(c(col_lon, col_lat), names(df))
  if (length(faltando) > 0L) {
    return(paste0(
      "Coluna nao encontrada: ", paste(faltando, collapse = ", "),
      ". Colunas do arquivo: ", paste(names(df), collapse = ", "), "."
    ))
  }

  lon <- suppressWarnings(as.numeric(df[[col_lon]]))
  lat <- suppressWarnings(as.numeric(df[[col_lat]]))
  validas <- is.finite(lon) & is.finite(lat)
  if (!any(validas)) {
    return(paste0(
      "Nenhuma coordenada valida: as colunas \"", col_lon, "\" e \"", col_lat,
      "\" nao contem numeros."
    ))
  }
  if (any(abs(lon[validas]) > 180) || any(abs(lat[validas]) > 90)) {
    return(paste(
      "As coordenadas estao fora do intervalo de graus decimais (longitude de",
      "-180 a 180, latitude de -90 a 90). O arquivo pode estar em metros, em um",
      "sistema projetado."
    ))
  }

  atributos <- setdiff(names(df), c(col_lon, col_lat))
  pontos <- df[validas, atributos, drop = FALSE]
  pontos$lon <- lon[validas]
  pontos$lat <- lat[validas]
  sf::st_as_sf(pontos, coords = c("lon", "lat"), crs = CRS_EXIBICAO)
}

#' Le um raster e o prepara para exibicao
#'
#' O raster e agregado na leitura, e nao a cada desenho, porque a agregacao e a
#' parte cara e o resultado nao muda quando o estilo muda.
#'
#' @param caminho Caminho do arquivo.
#'
#' @return Um `SpatRaster` de uma unica camada, ou uma string com o erro.
#' @noRd
.ler_raster <- function(caminho) {
  r <- try(terra::rast(caminho), silent = TRUE)
  if (inherits(r, "try-error")) {
    return("Nao consegui abrir o arquivo como raster. Formato aceito: GeoTIFF.")
  }
  if (terra::nlyr(r) > 1L) {
    # Composicao multibanda esta na lista de desejos, nao no v1.0.
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
      "implementado."
    ))
  }
  .reduzir_para_exibir(r)
}

#' Reduz a resolucao de um raster grande
#'
#' O leaflet transforma o raster em um PNG e manda para o navegador. Sem reduzir,
#' um raster de modelagem estoura `MAX_RASTER_BYTES`, e mesmo abaixo disso o
#' navegador engasga. O fator de agregacao e escolhido para chegar perto de
#' `MAX_CELULAS_RASTER` celulas.
#'
#' @param r Um `SpatRaster`.
#'
#' @noRd
.reduzir_para_exibir <- function(r) {
  n <- terra::ncell(r)
  if (n <= MAX_CELULAS_RASTER) return(r)
  fator <- ceiling(sqrt(n / MAX_CELULAS_RASTER))
  terra::aggregate(r, fact = fator, fun = "mean", na.rm = TRUE)
}

#' Faixa de valores de um raster
#'
#' Calcula minimo e maximo sob demanda, sem carregar todas as celulas na
#' memoria.
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
#' atributo `rgis_crs_assumido`, para quem chamou poder avisar o usuario.
#' Recusar seria mais correto, mas inviabilizaria shapefiles sem `.prj`, que sao
#' comuns.
#'
#' @param caminho Caminho do arquivo.
#'
#' @return Objeto `sf` em EPSG:4326, ou uma string com o erro.
#' @noRd
.ler_vetor <- function(caminho) {
  if (!isTRUE(nzchar(caminho)) || !file.exists(caminho)) {
    return("Arquivo nao encontrado.")
  }
  v <- try(sf::st_read(caminho, quiet = TRUE), silent = TRUE)
  if (inherits(v, "try-error")) {
    return(paste(
      "Nao consegui abrir o arquivo como vetor. Formatos aceitos: shapefile,",
      "GeoPackage, GeoJSON e KML."
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
    v <- try(sf::st_transform(v, CRS_EXIBICAO), silent = TRUE)
    if (inherits(v, "try-error")) {
      return("Nao consegui reprojetar a camada para WGS84.")
    }
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
