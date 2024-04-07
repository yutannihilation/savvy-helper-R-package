test_that("savvy_source() works", {
  savvy_source('
use savvy::savvy;

#[savvy]
fn hello() -> savvy::Result<()> {
    savvy::r_println!("Hello");
    Ok(())
}
')

  expect_output(hello(), "Hello")

  # overwrite
  savvy_source('
use savvy::savvy;

#[savvy]
fn goodbye() -> savvy::Result<()> {
    savvy::r_println!("Goodbye");
    Ok(())
}
')

  expect_true(exists("hello"))
  expect_output(goodbye(), "Goodbye")
})
