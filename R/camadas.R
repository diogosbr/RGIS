# A pilha de camadas.
#
# Uma camada e uma lista com:
#   id       identificador unico, usado como `group` no leaflet
#   nome     rotulo mostrado ao usuario, editavel
#   tipo     "raster", "ponto", "linha" ou "poligono"
#   dado     SpatRaster (raster) ou objeto sf em EPSG:4326 (demais)
#   estilo   lista de parametros visuais, especifica do tipo
#   visivel  logico
#   versao   inteiro, incrementado a cada mudanca de estilo ou visibilidade
#
# A pilha e um list() ordenado do topo para a base, como no painel do QGIS: o
# primeiro elemento e o que aparece por cima. O desenho percorre a lista ao
# contrario, para que o topo seja adicionado por ultimo.
#
# `versao` existe para a sincronizacao com o mapa saber, sem comparar objetos
# grandes, se uma camada precisa ser redesenhada.

#' Cria uma camada
#'
#' @param id,nome,tipo,dado,estilo Ver descricao no topo do arquivo.
#' @param faixa Para raster, o vetor `c(min, max)` calculado na leitura. Fica
#'   guardado para a legenda e a paleta nao recalcularem a cada desenho.
#'
#' @noRd
.nova_camada <- function(id, nome, tipo, dado, estilo, faixa = NULL) {
  list(
    id = id,
    nome = nome,
    tipo = tipo,
    dado = dado,
    estilo = estilo,
    faixa = faixa,
    visivel = TRUE,
    versao = 1L
  )
}

#' Posicao de uma camada na pilha
#'
#' @return Indice inteiro, ou `NA_integer_` se o id nao existir.
#' @noRd
.indice_camada <- function(pilha, id) {
  # match(NULL, x) devolve integer(0), nao NA, e `if (logical(0))` e erro. Sem
  # esta guarda, remover a camada selecionada quebra o painel de estilo.
  if (length(pilha) == 0L || length(id) != 1L || is.na(id)) return(NA_integer_)
  as.integer(match(id, vapply(pilha, `[[`, character(1), "id")))
}

#' Recupera uma camada pelo id
#'
#' @return A camada, ou `NULL` se o id nao existir.
#' @noRd
.buscar_camada <- function(pilha, id) {
  i <- .indice_camada(pilha, id)
  if (is.na(i)) NULL else pilha[[i]]
}

#' Insere uma camada no topo da pilha
#'
#' @noRd
.empilhar_camada <- function(pilha, camada) {
  c(list(camada), pilha)
}

#' Remove uma camada
#'
#' @noRd
.remover_camada <- function(pilha, id) {
  i <- .indice_camada(pilha, id)
  if (is.na(i)) return(pilha)
  pilha[-i]
}

#' Troca uma camada de posicao
#'
#' @param direcao `-1` sobe (mais perto do topo), `1` desce.
#'
#' @noRd
.mover_camada <- function(pilha, id, direcao) {
  i <- .indice_camada(pilha, id)
  j <- i + direcao
  if (is.na(i) || j < 1L || j > length(pilha)) return(pilha)
  pilha[c(i, j)] <- pilha[c(j, i)]
  pilha
}

#' Aplica uma mudanca a uma camada e incrementa a versao
#'
#' @param altera Funcao que recebe a camada e devolve a camada modificada.
#'
#' @noRd
.alterar_camada <- function(pilha, id, altera) {
  i <- .indice_camada(pilha, id)
  if (is.na(i)) return(pilha)
  camada <- altera(pilha[[i]])
  camada$versao <- camada$versao + 1L
  pilha[[i]] <- camada
  pilha
}

#' Gera um id novo, garantidamente ausente da pilha
#'
#' O id vira o `group` do leaflet, entao precisa ser estavel e sem espaco.
#'
#' @noRd
.proximo_id <- function(pilha) {
  usados <- vapply(pilha, `[[`, character(1), "id")
  n <- length(pilha) + 1L
  repeat {
    id <- paste0("camada_", n)
    if (!id %in% usados) return(id)
    n <- n + 1L
  }
}

#' Assinatura de uma camada para fins de sincronizacao
#'
#' Duas camadas com a mesma assinatura estao desenhadas do mesmo jeito.
#'
#' @noRd
.assinatura <- function(camada) {
  paste(camada$id, camada$versao, camada$visivel, sep = "|")
}

#' Assinaturas da pilha inteira, na ordem de desenho
#'
#' @return Vetor de caracteres nomeado pelos ids.
#' @noRd
.assinaturas <- function(pilha) {
  if (length(pilha) == 0L) return(character(0))
  assinaturas <- vapply(pilha, .assinatura, character(1))
  names(assinaturas) <- vapply(pilha, `[[`, character(1), "id")
  assinaturas
}

#' Extensao geografica de uma camada, em WGS84
#'
#' @return Vetor nomeado com `xmin`, `ymin`, `xmax` e `ymax`, ou `NULL` quando
#'   a extensao nao pode ser calculada.
#' @noRd
.extensao_camada <- function(camada) {
  caixa <- try(
    if (camada$tipo == "raster") {
      e <- as.vector(terra::project(
        terra::ext(camada$dado),
        from = terra::crs(camada$dado),
        to = "EPSG:4326"
      ))
      c(xmin = e[["xmin"]], ymin = e[["ymin"]],
        xmax = e[["xmax"]], ymax = e[["ymax"]])
    } else {
      b <- sf::st_bbox(camada$dado)
      c(xmin = b[["xmin"]], ymin = b[["ymin"]],
        xmax = b[["xmax"]], ymax = b[["ymax"]])
    },
    silent = TRUE
  )
  if (inherits(caixa, "try-error") || !all(is.finite(caixa))) return(NULL)
  caixa
}
