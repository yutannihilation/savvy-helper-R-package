#' Compile Rust Code And Load
#'
#' @param code Rust code to compile.
#' @param use_cache_dir If `TRUE`, reuse and override the cache dir to avoid
#' re-compilation. This is an expert-only option.
#' @param env The R environment where the R wrapping functions should be defined.
#' @param clean If `TRUE`, remove the temporary R package used for compilation
#' @param dependencies List of dependencies. (e.g. `list(once_cell = list(version = "1"))`)
#' at the end of the R session.
#'
#' @export
savvy_source <- function(code, use_cache_dir = FALSE, env = parent.frame(), dependencies = list(), clean = NULL) {
  check_savvy_cli()

  pkg_name <- generate_pkg_name()

  if (isTRUE(use_cache_dir)) {
    # By default, do not remove the directory
    clean <- clean %||% FALSE

    dir <- file.path(savvy_cache_dir(), "R-package")

    # Using cache means reusing the same DLL with overwriting. So, unload it first.
    for (pkg_name_prev in names(getLoadedDLLs())) {
      if (startsWith(pkg_name_prev, SAVVY_PACKAGE_PREFIX)) {
        dyn.unload(file.path(dir, "src", sprintf("%s%s", pkg_name_prev, .Platform$dynlib.ext)))
      }
    }
  } else {
    # By default, remove the directory
    clean <- clean %||% TRUE

    dir <- tempfile()
  }

  # create an empty package
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  if (isTRUE(clean)) {
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  }

  dir.create(file.path(dir, "R"), showWarnings = FALSE)
  file.create(file.path(dir, "NAMESPACE"), showWarnings = FALSE)
  writeLines(sprintf(DESCRIPTION, pkg_name), file.path(dir, "DESCRIPTION"))

  if (!dir.exists(file.path(dir, "src"))) {
    savvy_init(dir, verbose = FALSE)
  }

  writeLines(code, file.path(dir, "src", "rust", "src", "lib.rs"))

  tweak_cargo_toml(file.path(dir, "src", "rust", "Cargo.toml"), dependencies)

  savvy_update(dir)

  pkgbuild::compile_dll(dir)

  dyn.load(file.path(dir, "src", sprintf("%s%s", pkg_name, .Platform$dynlib.ext)))

  wrapper_file <- file.path(dir, "R", "wrappers.R")
  tweak_wrappers(wrapper_file, pkg_name)
  source(wrapper_file, local = env)
}

SAVVY_PACKAGE_PREFIX <- "savvyTemporaryPackage"

DESCRIPTION <- "Package: %s
Version: 0.0.0
Encoding: UTF-8"

tmp_pkg_count <- new.env(parent = emptyenv())
tmp_pkg_count$i <- 0L

# Based on cpp11:::generate_cpp_name
generate_pkg_name <- function() {
  loaded_dlls <- names(getLoadedDLLs())

  i <- tmp_pkg_count$i
  i <- i + 1L
  new_name <- sprintf("%s%i", SAVVY_PACKAGE_PREFIX, i)
  while (new_name %in% loaded_dlls) {
    new_name <- sprintf("%s%i", SAVVY_PACKAGE_PREFIX, i)
    i <- i + 1
  }

  tmp_pkg_count$i <- i

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

generate_dependencies_toml <- function(dependencies) {
  # Make sure savvy is in dependencies
  if (!"savvy" %in% names(dependencies)) {
    dependencies$savvy <- list(version = "*")
  }

  crate_names <- names(dependencies)

  x <- vapply(seq_along(dependencies), \(i) {
    dep <- dependencies[[i]]
    name <- crate_names[i]

    keys <- names(dep)
    values <- vapply(dep, \(x) {
      if (length(x) > 1L) {
        sprintf("[%s]", paste(sprintf('"%s"', x), collapse = ", "))
      } else {
        sprintf('"%s"', as.character(x))
      }
    }, character(1L))

    specifications <- paste(keys, "=", values, collapse = "\n")
    sprintf("[dependencies.%s]\n%s\n", name, specifications)
  }, character(1L))

  paste(x, collapse = "\n")
}

tweak_cargo_toml <- function(path, dependencies) {
  spec <- readLines(path)

  # cut out the [dependencies] section
  idx <- which(startsWith(spec, "[dependencies"))[1]
  if (is.na(idx)) {
    stop("No [depndencies] section found in Cargo.toml")
  }
  spec <- spec[1:idx]

  spec <- c(
    spec,
    generate_dependencies_toml(dependencies)
  )

  writeLines(spec, path)
}
