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
        #Inserir arquivo ----
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
        
        #box(width = "100%", title = "Nomes das colunas",
            column(width = 5,
        #nome coluna longitude ----
        textInput(
          inputId = "lon",
          label = "column X",
          value = "lon",
          width = "100%"
        )
        ),
        column(width = 5,
        #nome coluna longitude ----
        textInput(
          inputId = "lat",
          label = "column Y",
          value = "lat",
          width = "100%"
        )
        #)
        ),
        
        
        #Botao OK ----
        actionButton("plot_point", "OK", width = "100%", 
                     icon = icon("check-circle")
                     ),
        box(title = "Tabela", 
            width = "100%", 
            collapsible = TRUE, collapsed = TRUE,
            tabPanel("Head da tabela",tableOutput("df")))
      ),
      #RASTER (aba)----
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
        
        #cores do raster ----
        selectInput(
          "col_raster",
          "Cores",
          choices = c(
            'terrain.colors',
            "topo.colors",
            "heat.colors",
            "cm.colors",
            "rainbow"
          ),
          width = "50%"
        ),
        #barra da tranparencia ----
        sliderInput(
          inputId = "alpha",
          label = "Opacidade",
          min = 0,
          max = 100,
          value = 50,
          ticks = F,
          post = "%"
        ),
        #Botao OK ----
        actionButton("plot_raster", "OK", width = "100%", 
                     icon = icon("check-circle"))
        #actionButton("add_point", "Add"),
        
      ),
      
        #VETOR (aba) ----
      tabPanel(
        "Vetor",
        
        #inserir arquivo 0 ----
        #shinyFilesButton("shape_path", "Escolha o shape", "UPload", multiple = FALSE),
        #actionButton("shape_path", "Select file"),
        #inserir arquivo ----
        textInput("shape_path", "Selecionar caminho do arquivo", "./Exemplos/biomas.shp"),
        #fileInput("file3", "Vetor", multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj')),
        
        #cor da linha ----
        selectInput(
          "cor",
          "Contorno",
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
        #Checkbox contorno ----
        checkboxInput("stroke", "Contorno", TRUE),
        #cor do preenchimento ----
        selectInput(
          "col_vec",
          "Preenchimento",
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
        #Checkbox preenchimento ----
        checkboxInput("fill", "Preenchimento", TRUE),
        #barra da tranparencia ----
        sliderInput(
          inputId = "fillopacity",
          label = "Opacidade",
          min = 0,
          max = 100,
          value = 50,
          ticks = F,
          post = "%"
        ),
        #Botao OK ----
        actionButton("plot_shape", "OK", width = "100%", 
                     icon = icon("check-circle"))
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
