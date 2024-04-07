# savvy (R package)

<!-- badges: start -->
[![R-CMD-check](https://github.com/yutannihilation/savvy-helper-R-package/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yutannihilation/savvy-helper-R-package/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->


This is a simple wrapper R package around `savvy-cli` command.

## Installation

You can install this package from R-universe.

``` r
install.packages("savvy", repos = c("https://yutannihilation.r-universe.dev", "https://cloud.r-project.org"))
```

## Usage

``` r
# Run savvy_init() to do the initial setup for using savvy framework
savvy::savvy_init()

# Run savvy_update() to re-generate the C and R wrapper files from the Rust files.
savvy::savvy_update()

# To update savvy, please Run this command to overwrite the existing savvy-cli binary.
savvy::download_savvy_cli()
```


Also, on-the-fly Rust code compliation is experimentally supported.

``` r
savvy::savvy_source('
use savvy::savvy;

#[savvy]
fn hello() -> savvy::Result<()> {
    savvy::r_println!("Hello!!!!!!");
    Ok(())
}
')

hello()
#> Hello!!!!!!
```

