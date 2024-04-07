savvy_cache_dir <- function() {
  normalizePath(tools::R_user_dir("savvy", "cache"), mustWork = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
