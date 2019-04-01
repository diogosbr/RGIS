# instalando pacotes
packages = c("shiny", "shinydashboard", "leaflet", "randomForest", 'leaflet.extras', "dplyr", "raster", "rgdal", "shinyBS", "shinyFiles", "shinyalert")
for (p in setdiff(packages, installed.packages()[, "Package"])) {
  install.packages(p, dependencies = T)
}

library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(raster)
library(rgdal)
library(shinyBS)
library(shinyFiles)
library(shinyalert)

library(crosstalk)
library(DT)
