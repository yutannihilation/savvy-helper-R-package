test_that("savvy_source() works", {
  savvy_source('
use savvy::savvy;

#[savvy]
fn hello() -> savvy::Result<()> {
    savvy::r_println!("Hello");
    Ok(())
}
', use_cache_dir = TRUE)

  expect_output(hello(), "Hello")

  savvy_source('
use savvy::savvy;

#[savvy]
fn goodbye() -> savvy::Result<()> {
    savvy::r_println!("Goodbye");
    Ok(())
}
', use_cache_dir = TRUE)

  expect_output(goodbye(), "Goodbye")
})
