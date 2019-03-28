# ui <- fluidPage(
#   leafletOutput("mymap",height = 1000)
# )

# Define a interface do usuário para o app que gera um histograma.
ui <- fluidPage(
  
  # Título do app.
  titlePanel("RGIS"),
  
  # Barra lateral com as definições do input e do output.
  sidebarLayout(
    
    # Barra lateral para os inputs.
    sidebarPanel(width = 3,
      #inserindo arquivo:
      fileInput(
        "file1",
        "Tabela (.csv)",
        multiple = TRUE,
        accept = c("text/csv",
                   "text/comma-separated-values,text/plain",
                   ".csv")
      ),
      # Input: Checkbox if file has header ----
      checkboxInput("header", "Cabeçalho", TRUE),
      
      # Input: Select separator ----
      radioButtons(
        "sep",
        "Separador",
        choices = c(
          "Ponto e vírgula" = ";",
          "Vígula" = ",",
          "Tabulação" = "\t"
        ),
        selected = ","
      ),
      
      actionButton("plot_point", "OK"),
      
      # Horizontal line ----
      tags$hr(), 
      
      # Main panel for displaying outputs ----
      tabPanel("Head da tabela",tableOutput("df"))
      ,
      
      # Horizontal line ----
      tags$hr(),
      
      #inserindo arquivo:
      fileInput("file3", "Vetor", multiple = FALSE, accept = c(".shp")),
      actionButton("plot_shape", "OK"),
      
      # Horizontal line
      tags$hr(),
      
      #inserindo arquivo:
      fileInput(
        "file2",
        "Raster",
        multiple = FALSE,
        accept = c("image/tiff",
                   ".tiff",
                   ".asc",
                   ".bil")
      ),
      actionButton("plot_raster", "OK"),
      actionButton("add_point", "Add"),
      
      # Input: número de classes do histograma.
      sliderInput(inputId = "alpha",
                  label = "Transparencia",
                  min = 0,
                  max = 1,
                  value = 0.5)
      
    ),
    
    

    # Painel principal para mostrar os outputs.
    mainPanel(
      
      # Output: MAPA
      leafletOutput("mymap",height = 800)

    )
  )
)