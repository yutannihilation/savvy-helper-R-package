SAVVY_CLI_URL_BASE <- "https://github.com/yutannihilation/savvy/releases/download"

SAVVY_CLI_NAME <- "savvy-cli"

savvy_cli_path <- function() {
  bin <- if (Sys.info()[["sysname"]] == "Windows") {
    paste0(SAVVY_CLI_NAME, ".exe")
  } else {
    SAVVY_CLI_NAME
  }

  if (isTRUE(getOption("savvy.use_installed_cli"))) {
    bin
  } else {
    file.path(savvy_cache_dir(), bin)
  }
}

get_latest_release <- function() {
  jsonlite::read_json("https://api.github.com/repos/yutannihilation/savvy/releases/latest")[["tag_name"]]
}

get_download_url <- function() {
  latest_release <- get_latest_release()

  os <- Sys.info()[["sysname"]]
  arch <- Sys.info()[["machine"]]

  binary <- switch(os,
    Windows = "savvy-cli-x86_64-pc-windows-msvc.zip",
    Linux   = if (arch == "x86_64") "savvy-cli-x86_64-unknown-linux-gnu.tar.xz" else "savvy-cli-aarch64-unknown-linux-gnu.tar.xz",
    Darwin  = if (arch == "x86_64") "savvy-cli-x86_64-apple-darwin.tar.xz" else "savvy-cli-aarch64-apple-darwin.tar.xz"
  )

  paste(SAVVY_CLI_URL_BASE, latest_release, binary, sep = "/")
}

#' Update 'savvy-cli'
#'
#' @export
download_savvy_cli <- function() {
  download_tmp_dir <- tempfile()
  extract_tmp_dir <- tempfile()
  on.exit(unlink(download_tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(unlink(extract_tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # download
  dir.create(download_tmp_dir)
  download_url <- get_download_url()
  archive_file <- file.path(download_tmp_dir, basename(download_url))
  utils::download.file(download_url, destfile = archive_file, mode = "wb")

  # extract and copy
  if (Sys.info()[["sysname"]] == "Windows") {
    utils::unzip(archive_file, exdir = extract_tmp_dir)
    file.copy(file.path(extract_tmp_dir, "savvy-cli.exe"), savvy_cli_path(), overwrite = TRUE)
  } else {
    utils::untar(archive_file, exdir = extract_tmp_dir, extras = "--strip-components=1")
    file.copy(file.path(extract_tmp_dir, "savvy-cli"), savvy_cli_path(), overwrite = TRUE)
  }

  invisible(NULL)
}

check_savvy_cli <- function() {
  use_downloaded <- !isTRUE(getOption("savvy.use_installed_cli"))
  if (use_downloaded && !file.exists(savvy_cli_path())) {
    cat("Downloading savvy-cli binary")
    download_savvy_cli()
  }
}

#' Execute `savvy-cli update``
#'
#' @param path Path to the root of an R package
#' @param verbose If `TRUE`, show all the output from savvy-cli.
#' @export
savvy_update <- function(path = ".", verbose = TRUE) {
  check_savvy_cli()

  out <- if (verbose) "" else FALSE
  system2(savvy_cli_path(), args = c("update", path), stdout = out, stderr = out)
}

#' Execute `savvy-cli init``
#'
#' @param path Path to the root of an R package
#' @param verbose If `TRUE`, show all the output from savvy-cli.
#' @export
savvy_init <- function(path = ".", verbose = TRUE) {
  check_savvy_cli()

  out <- if (verbose) "" else FALSE
  system2(savvy_cli_path(), args = c("init", path), stdout = out, stderr = out)
}

#' Execute `savvy-cli extract-tests`
#'
#' @param path Path to the root of a Rust crate.
#' @export
savvy_extract_tests <- function(path = "./src/rust/") {
  check_savvy_cli()

  system2(savvy_cli_path(), args = c("extract-tests", path), stdout = TRUE, stderr = FALSE)
}

#' Execute `savvy-cli --version``
#'
#' @export
savvy_version <- function() {
  check_savvy_cli()

  system2(savvy_cli_path(), args = c("--version"))
}
