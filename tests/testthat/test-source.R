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

    savvy_source('
use savvy::savvy;
use ferris_says::say;
use std::io::{stdout, BufWriter};

#[savvy]
fn ferris_says() -> savvy::Result<()> {
    let stdout = stdout();
    let message = String::from("Hello fellow Rustaceans!");
    let width = message.chars().count();

    let mut writer = BufWriter::new(stdout.lock());
    say(&message, width, &mut writer).unwrap();
    Ok(())
}
',
    dependencies = list(`ferris-says` = "0.3.1"),
    use_cache_dir = TRUE
  )

  expect_output(goodbye(), "Goodbye")
})

test_that("generate_dependencies_toml() works", {
  x1 <- list(foo = list(version = "*"))
  expect_equal(
    generate_dependencies_toml(x1),
    r"([dependencies.foo]
version = "*"
)"
  )

  x2 <- list(foo = list(version = "1", features = c("a", "b")))
  expect_equal(
    generate_dependencies_toml(x2),
    r"([dependencies.foo]
version = "1"
features = ["a", "b"]
)"
  )

  x3 <- list(foo = list(path = "./../foo"), bar = list(path = "./../bar"))
  expect_equal(
    generate_dependencies_toml(x3),
    r"([dependencies.foo]
path = "./../foo"

[dependencies.bar]
path = "./../bar"
)"
  )
})
