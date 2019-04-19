#Titulo ----
header <- dashboardHeader(title = "RGIS")

#corpo ----
body <- dashboardBody(
  fluidRow(
  useShinyalert(),
  #barra lateral (abas) ----
  column(width = 3,
    #config. abas ----
    tabsetPanel(
      #CSV (aba) ----
      tabPanel(
        "CSV",
        #inserir arquivo ----
        fileInput(
          "file1",
          "Selecionar arquivo",
          multiple = FALSE,
          accept = c("text/csv",
                     "text/comma-separated-values,text/plain",
                     ".csv"),
          #width = "100%",
          buttonLabel = "Arquivo",
          placeholder = "Insira arquivo csv"
        ),
        #nome coluna longitude ----
        textInput(
          inputId = "lon",
          label = "lon",
          value = "lon",
          width = "25%"
        ),
        #nome coluna longitude ----
        textInput(
          inputId = "lat",
          label = "lat",
          value = "lat",
          width = "25%"
        ),
        
        #Checkbox cabeçalho ----
        checkboxInput("header", "Cabeçalho", TRUE),
        
        #Separador coluna ----
        radioButtons(
          "sep",
          "Separador de coluna",
          choices = c(" ; " = ";",
                      " , " = ",",
                      "tab" = "\t"),
          inline = T,
          selected = ","
        ),
        #Botao OK ----
        actionButton("plot_point", "OK")
      ),
      #Raster (aba)----
      tabPanel(
        "Raster",
        #inserir arquivo ----
        fileInput(
          "file2",
          "Selecionar arquivo",
          multiple = FALSE,
          accept = c("image/tiff",
                     ".tiff",
                     ".asc",
                     ".bil"),
          buttonLabel = "Arquivo",
          placeholder = "Insira o raster"
        ),
        #Botao OK e ADD
        actionButton("plot_raster", "OK"),
        actionButton("add_point", "Add"),
        
        #barra da tranparencia ----
        sliderInput(
          inputId = "alpha",
          label = "Opacidade",
          min = 0,
          max = 1,
          value = 0.5
        )
      ),
        #Vetor (aba) ----
      tabPanel(
        "Vetor",
        #inserir arquivo
        textInput("shape_path", "Selecionar caminho do arquivo", "./Exemplos/biomas.shp"),
        #fileInput("file3", "Vetor", multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj')),
        
        #cor da linha ----
        selectInput(
          "cor",
          "Cor",
          choices = c(
            'black',
            "green",
            "blue",
            "red",
            "white",
            "darkgreen",
            "darkblue",
            "darkred"
          ),
          width = "50%"
        ),
        #Botao OK
        actionButton("plot_shape", "OK")
      ),
      #ADD (aba) ----
      tabPanel("ADD", 
               h3("Em construção...")),
      #FUN (aba) ----
      tabPanel("FUN",
               h3("Em construção...")),
      #Help (aba) ----
      tabPanel("help", 
               h3("Em construção..."))
    )
  ),
  #MAPA ----
  mainPanel(h3("Mapa"),
            # Output: MAPA
            leafletOutput("mymap", height = 800))
))

#?
dashboardPage(header,
              dashboardSidebar(disable = TRUE),
              body)
