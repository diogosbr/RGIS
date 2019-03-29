server <- function(input, output, session){
  
  #MAPA base ####
  m_base <- leaflet() %>% 
    addTiles() %>% 
    setView(lng = -50, lat = -12 , zoom = 4) %>% 
    addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = F)) %>%
    addProviderTiles(providers$Esri.WorldImagery) %>%
    addMiniMap(
      tiles = providers$Esri.WorldStreetMap,
      toggleDisplay = TRUE,
      position = "bottomright"
    ) %>%
    addMeasure(
      primaryLengthUnit = "meters",
      secondaryLengthUnit = "kilometers",
      primaryAreaUnit = "sqmeters",
      secondaryAreaUnit = "hectares",
      localization = 'pt_BR'
    ) %>%
    addDrawToolbar(
      targetGroup = 'draw',
      editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions())
    )
  
  output$mymap <- renderLeaflet({m_base})
  
  #plot points ####
  observeEvent(input$plot_point, {
    if (!exists("input$file1$datapath")) {
      showNotification("Insira a tabela com os registros", type = "error")
    }else {
    df <- read.csv(
      input$file1$datapath,
      header = input$header,
      sep = input$sep
    )
    
    output$df <- renderTable({
      head(df)
    })
    
    m_points <- 
      m_base %>% 
      addMarkers(data = df, ~lon, ~lat, group = "points", popup = paste("<i>", df$sp,"</i>","<br>","Longitude", df$lon,"<br>", "Latitude" , df$lat), 
                 popupOptions = popupOptions(closeButton = TRUE)) %>% 
      addLayersControl(overlayGroups = c('draw', "points"), options = layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_points})
    }
  })
  
  #plot raster ####
  observeEvent(input$plot_raster, {
    
    modelo <- raster::raster(input$file2$datapath)
    
    pal <- colorNumeric(rev(terrain.colors(25)), values(modelo),
                        na.color = "transparent")
    m_raster <- m_base %>% 
      addRasterImage(modelo, colors = pal, opacity = input$alpha, group = 'raster') %>%
      addLegend(pal = pal, values = values(modelo),
                title = "Legend") %>% 
      addLayersControl(overlayGroups = c('draw', "raster"), options =
                         layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_raster})
    
  })
  
  
  #add points ####
  observeEvent(input$add_point, {
    df <- read.csv(
      input$file1$datapath,
      header = input$header,
      sep = input$sep
    )
    modelo <- raster::raster(input$file2$datapath)
    pal <- colorNumeric(rev(terrain.colors(25)), values(modelo),
                        na.color = "transparent")
    
    m_add_pts <- m_base %>% 
      addRasterImage(modelo, colors = pal, opacity = input$alpha, group = 'raster') %>%
      addLegend(pal = pal, values = values(modelo),
                title = "Legend") %>% 
      addMarkers(data = df, ~lon, ~lat, group = "points", popup = paste("<i>", df$sp,"</i>","<br>","Longitude", df$lon,"<br>", "Latitude" , df$lat), popupOptions = popupOptions(closeButton = TRUE)) %>% 
      addLayersControl(overlayGroups = c('draw', "raster", 'points'), options =
                         layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_add_pts})
    
  })
  
  #plot shape ####
  observeEvent(input$plot_shape, {
    #shape <- rgdal::readOGR(input$file3$datapath)
    abc <<- input$shape_path
    shape <- rgdal::readOGR(input$shape_path)

    m_shape <- m_base %>% 
      addPolygons(data = shape,
        stroke = T,
        smoothFactor = 0.2,
        #fillOpacity = 0.9,
        weight = 1,
        fill = F,
        opacity = 1,
        color = "black",
        group = "vetor"
      ) %>%
      addLayersControl(
        overlayGroups = c('draw', "vetor"),
        options =
          layersControlOptions(collapsed = FALSE)
      )
    
    output$mymap <- renderLeaflet({m_shape})
  })
}