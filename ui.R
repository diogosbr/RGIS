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
               checkboxInput("header", "Tem cabeçalho", TRUE),

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
                        label = "Longitude",
                        value = "lon",
                        width = "100%"
                      ),
                      bsTooltip("lon", "Nome da coluna de longitude")
               ),
               column(width = 5,
                      #nome coluna longitude ----
                      textInput(
                        inputId = "lat",
                        label = "Latitude",
                        value = "lat",
                        width = "100%"
                      ),
                      bsTooltip("lat", "Nome da coluna de latitude")
               ),

               #Botao OK ----
               actionButton("plot_point", "plot", width = "100%",
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
                   "rainbow",
                   "nice.colors"
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
               actionButton("plot_raster", "plot", width = "80%",
                            icon = icon("check-circle")),
               actionButton("add_point", "Add points table", width = "80%",
                            icon = icon("map-marker-alt")),
               bsTooltip("add_point", "Adiciona a tabela que foi carregada na aba CSV")
             ),

             #VETOR (aba) ----
             tabPanel(
               "Vetor",

               #inserir arquivo 0 ----
               #shinyFilesButton("shape_path", "Escolha o shape", "UPload", multiple = FALSE),
               #actionButton("shape_path", "Select file"),

               #inserir arquivo ----
               textInput("shape_path",
                         "Caminho do arquivo",
                         "./Exemplos/biomas.shp"
               ),
               actionButton("shape_path_button", "Escolha o shape",
                            width = "100%",
                            icon = icon("check-circle")),

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
               actionButton("plot_shape", "plot", width = "100%",
                            icon = icon("check-circle")),
               numericInput("label", "Rotulo", '1', 1, 20, width = "15%")
             ),

             #ADD (aba) ----
             tabPanel("ADD",
                      h4("Em construção..."),
                      box(width = "100%",

                          #Inserir csv ----
                          fileInput(
                            "add1",
                            "CSV",
                            multiple = FALSE,
                            accept = c("text/csv",
                                       "text/comma-separated-values,text/plain",
                                       ".csv"),
                            #width = "100%",
                            buttonLabel = "Arquivo",
                            placeholder = "Insira arquivo csv"
                          ),

                          #Inserir raster ----
                          fileInput(
                            "add2",
                            "Raster",
                            multiple = FALSE,
                            accept = c("image/tiff",
                                       ".tiff",
                                       ".asc",
                                       ".bil"),
                            buttonLabel = "Arquivo",
                            placeholder = "Insira o raster"
                          ),

                          #Inserir shape ----
                          textInput("shape_path", "Shape", "./Exemplos/biomas.shp")
                      ),

                      #Botao OK ----
                      actionButton("plot_csv_raster", "Plot csv-raster",
                                   width = "100%",
                                   icon = icon("check-circle")),
                      #Botao OK ----
                      actionButton("plot_csv_shape", "Plot csv-shape",
                                   width = "100%",
                                   icon = icon("check-circle")),
                      #Botao OK ----
                      actionButton("plot_shape_raster", "Plot shape-raster",
                                   width = "100%",
                                   icon = icon("check-circle")),
                      #Botao OK ----
                      actionButton("plot_all", "Plot all", width = "100%",
                                   icon = icon("check-circle"))
             ),

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
