# Paletas, cores e estilo por camada.

#' Nomes das paletas oferecidas para raster
#'
#' @noRd
.PALETAS_RASTER <- c(
  "terrain.colors", "topo.colors", "heat.colors",
  "cm.colors", "rainbow", "nice.colors"
)

#' Cores oferecidas para vetor
#'
#' @noRd
.CORES <- c(
  "black", "white", "gray",
  "green", "darkgreen",
  "blue", "darkblue",
  "red", "darkred",
  "orange", "yellow", "purple"
)

#' Gera as cores de uma paleta
#'
#' As paletas base do R vao do valor alto para o baixo, e por isso sao
#' invertidas: em mapa de adequabilidade o esperado e o valor alto chamar mais
#' atencao. Nome desconhecido cai no default em vez de gerar erro.
#'
#' @param nome Nome da paleta, um dos valores de `.PALETAS_RASTER`.
#' @param n Numero de classes.
#'
#' @return Vetor de `n` cores.
#' @noRd
.cores_paleta <- function(nome, n = 25) {
  switch(
    nome,
    "topo.colors" = rev(topo.colors(n)),
    "heat.colors" = rev(heat.colors(n)),
    "cm.colors"   = rev(cm.colors(n)),
    "rainbow"     = rev(rainbow(n)),
    "nice.colors" = colorRampPalette(
      c("deepskyblue", "green", "yellow", "red")
    )(n),
    rev(terrain.colors(n))
  )
}

#' Funcao de cores do leaflet para um raster
#'
#' @param nome Nome da paleta.
#' @param dominio Vetor numerico com a faixa de valores.
#'
#' @noRd
.paleta_raster <- function(nome, dominio) {
  colorNumeric(.cores_paleta(nome), domain = dominio, na.color = "transparent")
}

#' Colunas de atributo de uma camada vetorial
#'
#' Exclui a coluna de geometria, que nunca deve virar rotulo.
#'
#' @noRd
.colunas_atributo <- function(v) {
  setdiff(names(v), attr(v, "sf_column"))
}

#' Estilo inicial de uma camada
#'
#' @param tipo Tipo da camada.
#' @param dado Dado da camada, usado para escolher a coluna de popup.
#'
#' @noRd
.estilo_padrao <- function(tipo, dado) {
  coluna <- if (tipo == "raster") NA_character_ else {
    cols <- .colunas_atributo(dado)
    if (length(cols) == 0L) NA_character_ else cols[1]
  }
  switch(
    tipo,
    raster = list(paleta = "terrain.colors", opacidade = 80),
    ponto = list(
      cor = "blue", raio = 5, opacidade = 90, coluna_popup = coluna
    ),
    linha = list(
      cor = "darkblue", espessura = 2, opacidade = 90, coluna_popup = coluna
    ),
    poligono = list(
      cor = "black", preenchimento = "green", espessura = 1,
      opacidade = 50, coluna_popup = coluna
    )
  )
}

#' Texto do popup de uma camada vetorial
#'
#' @param v Objeto `sf`.
#' @param coluna Nome da coluna de atributo, ou `NA`.
#'
#' @return Vetor de caracteres, ou `NULL` quando nao ha coluna utilizavel.
#' @noRd
.popup_camada <- function(v, coluna) {
  if (is.null(coluna) || is.na(coluna) || !coluna %in% names(v)) return(NULL)
  paste0("<b>", coluna, ":</b> ", as.character(v[[coluna]]))
}
