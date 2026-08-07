# Ponto de entrada para deploy (shinyapps.io, Posit Connect, Shiny Server).
#
# Em uso local prefira RGIS::run_app(), que e a API do pacote. Este arquivo
# existe porque as plataformas de deploy procuram um app.R na raiz.

library(RGIS)

run_app()
