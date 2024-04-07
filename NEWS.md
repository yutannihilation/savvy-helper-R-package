# savvy 0.0.3

* Fix the download URL of `download_savvy_cli()` on Linux and macOS.
* New function `savvy_source()` compiles Rust code and makes it temporarily
  available on the R session.

``` r
savvy_source('
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
