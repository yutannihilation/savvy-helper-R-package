test_that("savvy_source() works", {
  # Skip tests on R-universe; this uses GitHub API for downloading, but it
  # seems R-universe reaches the API rate limit?
  # cf. https://docs.r-universe.dev/publish/troubleshoot-build.html#how-to-know-whether-tests-are-run-on-r-universe
  skip_if_not(identical(Sys.getenv("MY_UNIVERSE"), ""))

  savvy_source(
    '
use savvy::savvy;

#[savvy]
fn hello() -> savvy::Result<()> {
    savvy::r_println!("Hello");
    Ok(())
}
',
    use_cache_dir = TRUE
  )

  expect_output(hello(), "Hello")

  savvy_source(
    '
use savvy::savvy;

#[savvy]
fn goodbye() -> savvy::Result<()> {
    savvy::r_println!("Goodbye");
    Ok(())
}
',
    use_cache_dir = TRUE
  )

  expect_output(goodbye(), "Goodbye")

  savvy_source(
    '
use savvy::savvy;
use ferris_says::say;

#[savvy]
fn ferris_says() -> savvy::Result<()> {
    let message = String::from("Hello tech-savvies!");
    let width = message.chars().count();

    let mut buf = Vec::new();
    say(&message, width, &mut buf).unwrap();

    let out = unsafe { String::from_utf8_unchecked(buf) };
    savvy::r_println!("{out}");
    Ok(())
}
',
    dependencies = list(`ferris-says` = list(version = "0.3.1")),
    use_cache_dir = TRUE
  )

  expect_output(
    ferris_says(),
    " _____________________
< Hello tech-savvies! >
 ---------------------
        \\
         \\
            _~^~^~_
        \\) /  o o  \\ (/
          '_   -   _'
          / '-----' \\
",
    fixed = TRUE
  )
})

test_that("generate_dependencies_toml() works", {
  # simple case
  x1 <- list(foo = list(version = "*"))
  expect_equal(
    generate_dependencies_toml(x1),
    r"([dependencies.foo]
version = "*"

[dependencies.savvy]
version = "*"
)"
  )

  # features
  x2 <- list(foo = list(version = "1", features = c("a", "b")))
  expect_equal(
    generate_dependencies_toml(x2),
    r"([dependencies.foo]
version = "1"
features = ["a", "b"]

[dependencies.savvy]
version = "*"
)"
  )

  # multiple dependencies
  x3 <- list(foo = list(path = "./../foo"), bar = list(path = "./../bar"))
  expect_equal(
    generate_dependencies_toml(x3),
    r"([dependencies.foo]
path = "./../foo"

[dependencies.bar]
path = "./../bar"

[dependencies.savvy]
version = "*"
)"
  )

  # override savvy
  x4 <- list(
    foo = list(path = "./../foo"),
    savvy = list(git = "https://github.com/yutannihilation/savvy")
  )
  expect_equal(
    generate_dependencies_toml(x4),
    r"([dependencies.foo]
path = "./../foo"

[dependencies.savvy]
git = "https://github.com/yutannihilation/savvy"
)"
  )
})
