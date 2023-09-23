#' A Simple Wrapper of 'savvy-cli' Command
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

.onLoad <- function(libname, pkgname) {
  dir.create(savvy_cache_dir(), recursive = TRUE, showWarnings = FALSE)
}
