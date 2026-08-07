# RGIS: visualizador de camadas geoespaciais
#
# Dependencias e checagem de ambiente.
#
# O app NAO instala pacotes por conta propria: ele apenas informa, de forma
# explicita, o que falta e como instalar. Instalar sem pedir era o
# comportamento anterior e e inadequado tanto em uso local quanto em deploy.
#
# rgdal, raster e sp foram removidos. rgdal saiu do CRAN em out/2023; o
# backend espacial agora e sf (vetor) + terra (raster).

.rgis_deps <- c(
  shiny          = "1.7.0",
  shinydashboard = "0.7.0",
  shinyBS        = "0.61",
  shinyalert     = "3.0.0",
  leaflet        = "2.2.0",  # a partir daqui addRasterImage aceita SpatRaster
  leaflet.extras = "1.0.0",
  sf             = "1.0.0",
  terra          = "1.6.17", # a partir daqui minmax() tem o argumento compute
  magrittr       = "2.0.0"
)

.rgis_checar_deps <- function(deps = .rgis_deps) {
  faltando <- names(deps)[
    !vapply(names(deps), requireNamespace, logical(1), quietly = TRUE)
  ]
  presentes <- setdiff(names(deps), faltando)
  velhos <- presentes[
    vapply(presentes, function(p) utils::packageVersion(p) < deps[[p]], logical(1))
  ]

  if (length(faltando) == 0L && length(velhos) == 0L) {
    return(invisible(TRUE))
  }

  alvos <- c(faltando, velhos)
  stop(
    "O RGIS nao pode iniciar. Pacotes ausentes ou em versao antiga:\n  ",
    paste(sprintf("%s (>= %s)", alvos, deps[alvos]), collapse = "\n  "),
    "\n\nPara resolver, rode:\n  install.packages(c(",
    paste0('"', alvos, '"', collapse = ", "),
    "))\n",
    call. = FALSE
  )
}

.rgis_checar_deps()

library(shiny)
library(shinydashboard)
library(shinyBS)
library(shinyalert)
library(leaflet)
library(leaflet.extras)
library(magrittr)
library(sf)
library(terra)

# Limite de upload: 40 MB
options(shiny.maxRequestSize = 40 * 1024^2)

# Teto para o raster enviado ao navegador por addRasterImage.
# Paliativo: o default do leaflet (4 MB) rejeita em silencio os rasters de
# exemplo. A solucao correta e agregar o raster antes de exibir (fase 3, item 12).
.rgis_max_raster_bytes <- 32 * 1024^2
