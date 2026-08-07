#' Abre o RGIS no navegador
#'
#' @description
#' Ponto de entrada do aplicativo. Devolve um objeto `shiny.appobj`, o que
#' permite tanto rodar localmente quanto publicar em shinyapps.io, Posit Connect
#' ou Shiny Server.
#'
#' @param max_upload_mb Tamanho maximo de arquivo aceito no upload, em MB. O
#'   limite vale enquanto o app estiver rodando e e restaurado ao encerrar.
#' @param ... Argumentos extras repassados a [shiny::shinyApp()]. Os argumentos
#'   `ui`, `server` e `onStart` sao definidos aqui e nao podem ser sobrescritos.
#'
#' @return Um objeto `shiny.appobj`.
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }
#'
#' @export
run_app <- function(max_upload_mb = 40, ...) {
  if (!is.numeric(max_upload_mb) || length(max_upload_mb) != 1 ||
      is.na(max_upload_mb) || max_upload_mb <= 0) {
    stop("`max_upload_mb` deve ser um numero positivo.", call. = FALSE)
  }
  reservados <- intersect(c("ui", "server", "onStart"), ...names())
  if (length(reservados) > 0L) {
    stop(
      "Estes argumentos sao definidos pelo RGIS e nao podem ser passados: ",
      paste(reservados, collapse = ", "), ".",
      call. = FALSE
    )
  }

  shiny::shinyApp(
    ui = .app_ui(max_upload_mb),
    server = .app_server,
    # Alterar options() e efeito colateral global, entao o valor antigo e
    # restaurado quando o app encerra. Dentro de onStart nao existe sessao
    # corrente, entao shiny::onStop() registra um callback de aplicacao, nao de
    # sessao: mover isso para o server faria a primeira desconexao derrubar o
    # limite de upload das outras sessoes.
    onStart = function() {
      antigo <- options(shiny.maxRequestSize = max_upload_mb * 1024^2)
      shiny::onStop(function() options(antigo))
    },
    ...
  )
}
