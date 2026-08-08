#' RGIS: visualizador de camadas geoespaciais
#'
#' @description
#' O RGIS abre um mapa interativo no navegador e permite carregar ocorrencias em
#' CSV, rasters continuos e camadas vetoriais, reprojetando tudo para WGS84.
#'
#' Ponto de entrada: [RGIS::run_app()].
#'
#' @keywords internal
#' @import shiny
#' @import leaflet
#' @importFrom shinydashboard dashboardPage dashboardHeader dashboardSidebar dashboardBody box
#' @importFrom shinyalert shinyalert
#' @importFrom leaflet.extras addDrawToolbar drawShapeOptions editToolbarOptions selectedPathOptions
#' @importFrom grDevices terrain.colors topo.colors heat.colors cm.colors rainbow colorRampPalette
"_PACKAGE"
