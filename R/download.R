SAVVY_BASE_URL <- "https://github.com/yutannihilation/savvy/releases/download/"

SAVVY_CLI_NAME <- "savvy-cli"

savvy_cache_dir <- function() {
  normalizePath(tools::R_user_dir("savvy", "cache"), mustWork = FALSE)
}

savvy_cli_path <- function() {
  file.path(savvy_cache_dir(), SAVVY_CLI_NAME)
}

#' Update 'savvy-cli'
#'
#' @param force If `TRUE`, download the savvy CLI even if it's up-to-date.
#' @export
update_savvy_cli <- function(force = FALSE) {
  cache_dir <- tools::R_user_dir("savvy", "cache")
}
