options(shiny.maxRequestSize=40*1024^2)
server <- function(input, output, session){
  
  #MAPA base ####
  m_base <- leaflet() %>% 
    addTiles() %>% 
    setView(lng = -50, lat = -12 , zoom = 4) %>% 
    addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = F)) %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satelite") %>%
    addProviderTiles(providers$Esri.WorldStreetMap, group = "Streetmap") %>%
    addProviderTiles(providers$Esri.WorldTerrain, group = "Terrain") %>%
    addProviderTiles(providers$Esri.WorldPhysical, group = "Physical") %>%
    addMiniMap(tiles = providers$Esri.WorldStreetMap,toggleDisplay = TRUE,position = "bottomright") %>%
    addMeasure(
      primaryLengthUnit = "meters",
      secondaryLengthUnit = "kilometers",
      primaryAreaUnit = "sqmeters",
      secondaryAreaUnit = "hectares",
      localization = 'pt_BR'
    ) %>%
    addDrawToolbar(
      targetGroup = 'draw',
      editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions()),
      polylineOptions = drawShapeOptions(),
      polygonOptions = drawShapeOptions(),
      circleOptions = drawShapeOptions(),
      rectangleOptions = drawShapeOptions()
    )
  
  output$mymap <- renderLeaflet({
    m_base %>%
      addLayersControl(baseGroups = c("Satelite", 'Streetmap', "Terrain", "Physical"),
                       overlayGroups = c('draw'),
                       options = layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    })
  
  observeEvent(input$mymap_shape_click,{
    print(input$mymap_shape_click)
  })
 
  observeEvent(input$mymap_click,{
    #print(input$mymap_click)
  })

  
  #plot points ####
  observeEvent(input$plot_point, {
    if (is(try(read.csv(input$file1$datapath, header = input$header,sep = input$sep), silent = T),"try-error")) {
      shinyalert("Oops!", "Something went wrong.", type = "error", confirmButtonCol = "darkgreen", 
                 closeOnClickOutside = TRUE)
      #showNotification("Insira a tabela com os registros", type = "error")
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
      addLayersControl(baseGroups = c("Satelite", 'Streetmap', "Terrain", "Physical"),
                       overlayGroups = c('draw', "points"), 
                       options = layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_points})
    }
  })
  
  #plot raster ####
  observeEvent(input$plot_raster, {
    if (is(try(raster::raster(input$file2$datapath), silent = T),"try-error")) {
      shinyalert("Oops!", "Something went wrong.", type = "error")
      #showNotification("Insira o raster", type = "error")
    }else {
    modelo <- raster::raster(input$file2$datapath)
    
    pal <- colorNumeric(rev(terrain.colors(25)), values(modelo),
                        na.color = "transparent")
    m_raster <- m_base %>% 
      addRasterImage(modelo, colors = pal, opacity = input$alpha, group = 'raster') %>%
      addLegend(pal = pal, values = values(modelo),
                title = "Legend") %>% 
      addLayersControl(baseGroups = c("Satelite", 'Streetmap', "Terrain", "Physical"),
                       overlayGroups = c('draw', "raster"),
                       options = layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_raster})
    }
    
  })
  
  
  #add points ####
  observeEvent(input$add_point, {
    if (is(try(read.csv(input$file1$datapath, header = input$header,sep = input$sep), silent = T),"try-error") | is(try(raster::raster(input$file2$datapath), silent = T),"try-error")) {
      shinyalert("Oops!", "Something went wrong.", type = "error")
      #showNotification("Insira a tabela com os registros", type = "error")
    }else {
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
      addLayersControl(baseGroups = c("Satelite", 'Streetmap', "Terrain", "Physical"),
                       overlayGroups = c('draw', "raster", 'points'), 
                       options = layersControlOptions(collapsed = FALSE))  %>%
      addStyleEditor()
    
    output$mymap <- renderLeaflet({m_add_pts})
    }
    
  })
  #plot shape ####
  observeEvent(input$plot_shape, {
    if (is(try(rgdal::readOGR(input$shape_path), silent = T),"try-error")) {
      shinyalert("Oops!", "Something went wrong.", type = "error")
      #showNotification("ERRO: Insira um shape válido", type = "error")
    }else {
    #shape <- rgdal::readOGR(input$file3$datapath)
    shape <- rgdal::readOGR(input$shape_path)

    m_shape <- m_base %>% 
      addPolygons(
        data = shape,
        stroke = T,
        smoothFactor = 0.2,
        #fillOpacity = 0.9,
        weight = 1,
        fill = F,
        opacity = 1,
        color = "black",
        group = "vetor",
        highlightOptions = highlightOptions(weight = 5,
                                            color = "red",
                                            fillOpacity = 0.7,
                                            bringToFront = T),
        label = ~BIOMA
      ) %>%
      addLayersControl(baseGroups = c("Satelite", 'Streetmap', "Terrain", "Physical"),
                       overlayGroups = c('draw', "vetor"),
                       options = layersControlOptions(collapsed = FALSE)
      )
    
    output$mymap <- renderLeaflet({m_shape})
    }
  })
}
