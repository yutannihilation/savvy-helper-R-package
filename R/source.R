#' Compile Rust Code And Load
#'
#' @param code Rust code to compile.
#' @param use_cache_dir If `TRUE`, reuse and override the cache dir to avoid re-compilation.
#'
#' @export
savvy_source <- function(code, use_cache_dir = FALSE) {
  if (use_cache_dir) {
    dir <- file.path(savvy_cache_dir(), "R-package")
    pkg_name <- "savvyTemporaryPackage"

    # Using cache means reusing the same DLL with overwriting. So, unload it first.
    if (pkg_name %in% names(getLoadedDLLs())) {
      dyn.unload(file.path(dir, "src", sprintf("%s%s", pkg_name, .Platform$dynlib.ext)))
    }
  } else {
    dir <- tempfile()
    pkg_name <- generate_pkg_name()
  }

  # create an empty package
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, "R"), showWarnings = FALSE)
  file.create(file.path(dir, "NAMESPACE"), showWarnings = FALSE)
  writeLines(sprintf(DESCRIPTION, pkg_name), file.path(dir, "DESCRIPTION"))

  if (!dir.exists(file.path(dir, "src"))) {
    savvy_init(dir, verbose = TRUE)
  }

  writeLines(code, file.path(dir, "src", "rust", "src", "lib.rs"))

  savvy_update(dir)

  pkgbuild::compile_dll(dir)

  dyn.load(file.path(dir, "src", sprintf("%s%s", pkg_name, .Platform$dynlib.ext)))

  wrapper_file <- file.path(dir, "R", "wrappers.R")
  tweak_wrappers(wrapper_file, pkg_name)
  source(wrapper_file)
}

DESCRIPTION <- "Package: %s
Version: 0.0.0
Encoding: UTF-8"

# Based on cpp11:::generate_cpp_name
generate_pkg_name <- function() {
  loaded_dlls <- names(getLoadedDLLs())

  i <- 1L
  new_name <- sprintf("savvyTemporaryPackage%i", i)
  while (new_name %in% loaded_dlls) {
    new_name <- sprintf("savvyTemporaryPackage%i", i)
    i <- i + 1
  }

  new_name
}

tweak_wrappers <- function(path, pkg_name) {
  r_code <- readLines(path)

  call_wrapper <- sprintf(".Call_%s", pkg_name)
  r_code <- gsub(".Call", call_wrapper, r_code)
  r_code <- c(
    r_code,
    "",
    sprintf("%s <- function(symbol, ...) {", call_wrapper),
    "  symbol_string <- deparse(substitute(symbol))",
    sprintf('  .Call(symbol_string, ..., PACKAGE = "%s")', pkg_name),
    "}"
  )

  writeLines(r_code, path)
}
