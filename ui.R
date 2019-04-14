ui <- fluidPage(
  useShinyalert(),
  
  # Título do app. ####
  titlePanel("RGIS"),
  
  # Barra lateral com as definições do input e do output. ####
  sidebarLayout(
    
    # Barra lateral para os inputs. ####
    sidebarPanel(width = 3,

    #inserindo arquivo csv ####
    fileInput(
        "file1",
        "Tabela (.csv)",
        multiple = FALSE,
        accept = c("text/csv",
                   "text/comma-separated-values,text/plain",
                   ".csv"),
        width = "100%",
        buttonLabel = "Arquivo",
        placeholder = "Insira arquivo csv"
      ),
    
    textInput(inputId="lon", label = "lon", value = "lon", width = "25%"),
    textInput(inputId="lat", label = "lat", value = "lat", width = "25%"),
      # Input: Checkbox if file has header ####
      checkboxInput("header", "Cabeçalho", TRUE),
      
      # Input: Select separator ####
      radioButtons(
        "sep",
        "Separador de coluna",
        choices = c(
          " ; " = ";",
          " , " = ",",
          "tab" = "\t"
        ),
        inline = T,
        selected = ","
      ),
      
      actionButton("plot_point", "OK"),
      
      # Horizontal line
      tags$hr(), 
      
      # Main panel for displaying outputs
      tabPanel("Head da tabela",tableOutput("df")),
    
      # Horizontal line
      tags$hr(),
      
      #inserindo arquivo shape ####
      textInput("shape_path", "Shape path", "./Exemplos/biomas.shp"),
      #fileInput("file3", "Vetor", multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj')),
      selectInput("cor", "Cor", choices = c('black', "green", "blue", "red", "white", "darkgreen", "darkblue", "darkred"), width = "50%"),
      actionButton("plot_shape", "OK"),
      
      # Horizontal line
      tags$hr(),
      
      #inserindo arquivo raster ####
      fileInput(
        "file2",
        "Raster",
        multiple = FALSE,
        accept = c("image/tiff",
                   ".tiff",
                   ".asc",
                   ".bil"),
        buttonLabel = "Arquivo",
        placeholder = "Insira o raster"
      ),
      actionButton("plot_raster", "OK"),
      actionButton("add_point", "Add"),
      
      #barra da tranparencia ####
      sliderInput(inputId = "alpha",
                  label = "Transparencia do raster",
                  min = 0,
                  max = 1,
                  value = 0.5)
    ),
    
    # Painel principal para mostrar os outputs.####
    mainPanel(
      h3("Mapa"),
      # Output: MAPA
      leafletOutput("mymap",height = 800)
    )
  )
)  