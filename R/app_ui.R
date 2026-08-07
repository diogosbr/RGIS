#' Interface do RGIS
#'
#' Monta a pagina inteira: painel de abas a esquerda, mapa a direita.
#'
#' As abas "ADD" e "FUN" da versao antiga foram removidas. A primeira existia
#' para combinar camadas manualmente, com um botao por par de camadas, e deixa de
#' fazer sentido quando o mapa passa a manter uma pilha de camadas (item 3 do
#' roadmap). A segunda nunca saiu de "em construcao".
#'
#' @param max_upload_mb Limite de upload, apenas para exibir na aba Ajuda.
#'
#' @return Um objeto de UI do Shiny.
#' @noRd
.app_ui <- function(max_upload_mb = 40) {
  dashboardPage(
    dashboardHeader(title = "RGIS"),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      fluidRow(
        column(width = 3, .painel_abas(max_upload_mb)),
        column(
          width = 9,
          h3("Mapa"),
          leafletOutput("mymap", height = 800)
        )
      )
    )
  )
}

#' Painel lateral com as abas de entrada de dados
#'
#' @noRd
.painel_abas <- function(max_upload_mb) {
  tabsetPanel(
    .aba_csv(),
    .aba_raster(),
    .aba_vetor(),
    .aba_ajuda(max_upload_mb)
  )
}

#' @noRd
.aba_csv <- function() {
  tabPanel(
    "CSV",
    fileInput(
      "file1",
      "Selecionar arquivo",
      multiple = FALSE,
      accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv"),
      buttonLabel = "Arquivo",
      placeholder = "Insira arquivo csv"
    ),
    checkboxInput("header", "Tem cabecalho", TRUE),
    radioButtons(
      "sep",
      "Separador de coluna",
      choices = c(" ; " = ";", " , " = ",", "tab" = "\t"),
      inline = TRUE,
      selected = ","
    ),
    fluidRow(
      column(
        width = 6,
        textInput("lon", "Longitude", value = "lon", width = "100%"),
        bsTooltip("lon", "Nome da coluna de longitude")
      ),
      column(
        width = 6,
        textInput("lat", "Latitude", value = "lat", width = "100%"),
        bsTooltip("lat", "Nome da coluna de latitude")
      )
    ),
    actionButton(
      "plot_point", "plot",
      width = "100%",
      icon = icon("check-circle")
    ),
    box(
      title = "Tabela",
      width = 12,
      collapsible = TRUE,
      collapsed = TRUE,
      tableOutput("df")
    )
  )
}

#' @noRd
.aba_raster <- function() {
  tabPanel(
    "Raster",
    fileInput(
      "file2",
      "Selecionar arquivo",
      multiple = FALSE,
      # .asc e .bil ficaram de fora: nao trazem CRS ou dependem de arquivo
      # companheiro, entao sempre caem em erro. Voltam quando existir escolha
      # manual de EPSG (item 7 do roadmap).
      accept = c("image/tiff", ".tif", ".tiff"),
      buttonLabel = "Arquivo",
      placeholder = "Insira o raster"
    ),
    selectInput(
      "col_raster",
      "Cores",
      choices = .PALETAS_RASTER,
      width = "70%"
    ),
    sliderInput(
      "alpha",
      "Opacidade",
      min = 0,
      max = 100,
      value = 50,
      ticks = FALSE,
      post = "%"
    ),
    actionButton(
      "plot_raster", "plot",
      width = "100%",
      icon = icon("check-circle")
    ),
    # Paliativo enquanto o mapa nao mantem uma pilha de camadas (item 3).
    actionButton(
      "add_point", "Somar os pontos do CSV",
      width = "100%",
      icon = icon("map-marker-alt")
    ),
    bsTooltip("add_point", "Desenha o raster junto com a tabela carregada na aba CSV")
  )
}

#' @noRd
.aba_vetor <- function() {
  tabPanel(
    "Vetor",
    # ATENCAO: caminho digitado e file.choose() so funcionam quando o R roda na
    # mesma maquina do navegador. Sera trocado por upload de verdade, incluindo
    # shapefile em .zip (item 6 do roadmap).
    textInput("shape_path", "Caminho do arquivo", value = ""),
    actionButton(
      "shape_path_button", "Escolher arquivo",
      width = "100%",
      icon = icon("folder-open")
    ),
    selectInput("cor", "Contorno", choices = .CORES, width = "70%"),
    checkboxInput("stroke", "Contorno", TRUE),
    selectInput("col_vec", "Preenchimento", choices = .CORES, width = "70%"),
    checkboxInput("fill", "Preenchimento", TRUE),
    sliderInput(
      "fillopacity",
      "Opacidade",
      min = 0,
      max = 100,
      value = 50,
      ticks = FALSE,
      post = "%"
    ),
    numericInput("label", "Coluna do rotulo", value = 1, min = 1, max = 50,
                 width = "50%"),
    bsTooltip("label", "Posicao da coluna de atributos usada no popup"),
    actionButton(
      "plot_shape", "plot",
      width = "100%",
      icon = icon("check-circle")
    )
  )
}

#' @noRd
.aba_ajuda <- function(max_upload_mb) {
  tabPanel(
    "Ajuda",
    h4("Como usar"),
    tags$ol(
      tags$li("Escolha a aba do tipo de dado: CSV para pontos, Raster ou Vetor."),
      tags$li("Carregue o arquivo, ajuste o estilo e clique em plot.")
    ),
    h4("Formatos aceitos"),
    tags$ul(
      tags$li(tags$b("CSV"), ": uma coluna de longitude e uma de latitude, em graus decimais."),
      tags$li(tags$b("Raster"), ": GeoTIFF continuo, com CRS definido e uma banda."),
      tags$li(tags$b("Vetor"), ": shapefile, GeoPackage, GeoJSON ou KML, com CRS definido.")
    ),
    h4("Limites"),
    tags$ul(
      tags$li(paste0("Upload de ate ", max_upload_mb, " MB por arquivo.")),
      tags$li("Camadas sem CRS definido nao podem ser posicionadas no mapa."),
      tags$li("Por enquanto cada plot substitui o mapa anterior.")
    ),
    tags$p(
      "Documentacao completa em ",
      tags$a(href = "https://github.com/diogosbr/RGIS", "github.com/diogosbr/RGIS"),
      "."
    )
  )
}
