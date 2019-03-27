server <- function(input,output, session){
  
  observeEvent(input$plot_point, {
    df <- read.csv(
      input$file1$datapath,
      header = input$header,
      sep = input$sep
      )
    
    output$df <- renderTable({
      head(df)
    })
    
    output$mymap <- renderLeaflet({
        m <- leaflet(df) %>% 
          addTiles() %>% 
          addMarkers(~lon, ~lat) %>% 
          addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = F)) %>%
          addProviderTiles(providers$Esri.WorldImagery) %>%
          addMiniMap(tiles = providers$Esri.WorldStreetMap, toggleDisplay = TRUE, position = "bottomright") %>%
          addMeasure(primaryLengthUnit = "meters", secondaryLengthUnit = "kilometers", primaryAreaUnit = "sqmeters",
            secondaryAreaUnit = "hectares", localization = 'pt_BR') %>%
          addDrawToolbar(targetGroup = 'draw',
                         editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions()))  %>%
          addStyleEditor()
      })
    
  })
  
  #plot raster
  observeEvent(input$plot_raster, {
    modelo <- raster(
      input$file2$datapath
    )

    output$mymap <- renderLeaflet({
      pal <- colorNumeric(rev(terrain.colors(25)), values(modelo),
                          na.color = "transparent")
      m <- leaflet() %>% addTiles() %>%
        addRasterImage(modelo, colors = pal, opacity = input$alpha, group = 'model') %>%
        addProviderTiles(providers$Esri.WorldImagery) %>% 
        addLegend(pal = pal, values = values(modelo),
                  title = "Bio_01") %>% 
        addMiniMap(tiles = providers$Esri.WorldStreetMap, toggleDisplay = TRUE, position = "bottomright") %>% 
        addMeasure(primaryLengthUnit = "meters", secondaryLengthUnit = "kilometers",
                   primaryAreaUnit = "sqmeters", secondaryAreaUnit = "hectares", localization = 'pt_BR') %>% 
        addDrawToolbar(
          targetGroup = 'draw',
          editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions()))  %>%
        addLayersControl(overlayGroups = c('draw', "model"), options =
                           layersControlOptions(collapsed = FALSE)) %>%
        addStyleEditor()
    })
    
  })
    
  
     #--------------
  
  
  output$mymap <- renderLeaflet({

    m <- leaflet() %>% 
      addTiles() %>% 
      setView(lng = -40, lat = -20 , zoom = 4) %>% 
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
      )  %>%
      addStyleEditor()
    
    
  })
}