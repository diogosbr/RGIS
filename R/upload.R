# Entrada unica de arquivos: detecta o tipo e monta camadas.
#
# O Shiny grava cada upload com um nome temporario sem extensao, o que quebra
# shapefile (que precisa dos arquivos irmaos lado a lado, com o mesmo nome base)
# e confunde o GDAL, que decide o driver pela extensao. Por isso o primeiro
# passo e sempre copiar tudo para uma pasta temporaria com os nomes originais.

#' Extensoes que, sozinhas, viram uma camada
#'
#' @noRd
.EXT_PRINCIPAIS <- c("csv", "txt", "tif", "tiff", "shp", "gpkg", "geojson", "json", "kml", "zip")

#' Extensoes que acompanham um shapefile e nao viram camada
#'
#' @noRd
.EXT_COMPANHEIRAS <- c("dbf", "shx", "prj", "sbn", "sbx", "cpg", "qix", "qpj", "xml")

#' Extensao de um caminho, em minusculas e sem o ponto
#'
#' @noRd
.extensao <- function(caminho) {
  tolower(sub(".*\\.", "", basename(caminho)))
}

#' Copia os arquivos enviados para uma pasta temporaria com os nomes originais
#'
#' @param upload Data frame devolvido por `fileInput`, com `name` e `datapath`.
#'
#' @return Vetor de caminhos na pasta temporaria, na mesma ordem.
#' @noRd
.materializar_upload <- function(upload) {
  pasta <- file.path(tempdir(), paste0("rgis_", as.integer(Sys.time()), "_",
                                       sample.int(1e6, 1)))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  destinos <- file.path(pasta, basename(upload$name))
  file.copy(upload$datapath, destinos, overwrite = TRUE)
  destinos
}

#' Descompacta os .zip e devolve a lista de arquivos a considerar
#'
#' @param caminhos Arquivos ja materializados.
#'
#' @noRd
.expandir_zips <- function(caminhos) {
  zips <- caminhos[.extensao(caminhos) == "zip"]
  if (length(zips) == 0L) return(caminhos)
  extraidos <- character(0)
  for (z in zips) {
    destino <- file.path(dirname(z), paste0("zip_", sub("\\.[^.]*$", "", basename(z))))
    dir.create(destino, recursive = TRUE, showWarnings = FALSE)
    conteudo <- try(utils::unzip(z, exdir = destino), silent = TRUE)
    if (!inherits(conteudo, "try-error")) {
      extraidos <- c(extraidos, conteudo)
    }
  }
  c(setdiff(caminhos, zips), extraidos)
}

#' Transforma um upload em camadas
#'
#' Cada arquivo de tipo principal vira uma camada. Arquivos companheiros de
#' shapefile ficam no disco mas nao viram camada. Um `.zip` e descompactado e
#' seu conteudo passa pela mesma regra.
#'
#' @param upload Data frame devolvido por `fileInput`.
#' @param opcoes_csv Lista com `col_lon`, `col_lat`, `header` e `sep`.
#'
#' @return Lista com dois elementos: `camadas`, uma lista de camadas prontas
#'   menos o id (atribuido por quem empilha), e `erros`, um vetor de mensagens.
#' @noRd
.processar_upload <- function(upload, opcoes_csv) {
  caminhos <- .expandir_zips(.materializar_upload(upload))
  extensoes <- .extensao(caminhos)

  desconhecidas <- setdiff(extensoes, c(.EXT_PRINCIPAIS, .EXT_COMPANHEIRAS))
  principais <- caminhos[extensoes %in% setdiff(.EXT_PRINCIPAIS, "zip")]

  erros <- character(0)
  if (length(desconhecidas) > 0L) {
    erros <- c(erros, paste0(
      "Ignorei arquivo com extensao nao reconhecida: ",
      paste(unique(desconhecidas), collapse = ", "), "."
    ))
  }
  if (length(principais) == 0L) {
    erros <- c(erros, paste(
      "Nenhum arquivo utilizavel. Aceito CSV, GeoTIFF, shapefile (envie o .shp",
      "junto com .shx, .dbf e .prj, ou tudo em um .zip), GeoPackage, GeoJSON e",
      "KML."
    ))
    return(list(camadas = list(), erros = erros))
  }

  camadas <- list()
  for (caminho in principais) {
    resultado <- .camada_de_arquivo(caminho, opcoes_csv)
    if (is.character(resultado)) {
      erros <- c(erros, paste0(basename(caminho), ": ", resultado))
    } else {
      camadas <- c(camadas, list(resultado))
    }
  }
  list(camadas = camadas, erros = erros)
}

#' Le um arquivo e monta a camada correspondente
#'
#' @return Uma camada sem id, ou uma string com o erro.
#' @noRd
.camada_de_arquivo <- function(caminho, opcoes_csv) {
  nome <- basename(caminho)
  ext <- .extensao(caminho)

  if (ext %in% c("tif", "tiff")) {
    r <- .ler_raster(caminho)
    if (is.character(r)) return(r)
    faixa <- .faixa_valores(r)
    if (is.null(faixa)) {
      return("o raster nao tem valores validos para colorir: esta vazio ou e constante.")
    }
    return(.nova_camada(
      id = NA_character_, nome = nome, tipo = "raster", dado = r,
      estilo = .estilo_padrao("raster", r), faixa = faixa
    ))
  }

  dado <- if (ext %in% c("csv", "txt")) {
    .ler_pontos(
      caminho,
      col_lon = opcoes_csv$col_lon,
      col_lat = opcoes_csv$col_lat,
      header = opcoes_csv$header,
      sep = opcoes_csv$sep
    )
  } else {
    .ler_vetor(caminho)
  }
  if (is.character(dado)) return(dado)

  tipo <- .classe_geom(dado)
  if (is.null(tipo)) {
    return(paste0(
      "a camada mistura tipos de geometria ou traz GEOMETRYCOLLECTION, que ",
      "ainda nao e suportado. Geometrias encontradas: ",
      paste(unique(as.character(sf::st_geometry_type(dado))), collapse = ", "), "."
    ))
  }

  camada <- .nova_camada(
    id = NA_character_, nome = nome, tipo = tipo, dado = dado,
    estilo = .estilo_padrao(tipo, dado)
  )
  camada$crs_assumido <- isTRUE(attr(dado, "rgis_crs_assumido"))
  camada
}

#' Caminhos dos dados de exemplo que acompanham o pacote
#'
#' A ordem importa: cada arquivo e empilhado por cima do anterior, entao a lista
#' vai do fundo para o topo. Rasters embaixo, pontos em cima.
#'
#' @noRd
.arquivos_exemplo <- function() {
  arquivos <- c(
    "estados_albers.tif", "adequabilidade.tif",
    "cerrado.gpkg", "rodovias_go_df.gpkg", "ocorrencias.csv"
  )
  caminhos <- system.file("extdata", arquivos, package = "RGIS")
  caminhos[nzchar(caminhos)]
}
