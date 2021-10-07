#!/usr/local/bin/Rscript --vanilla

if (fs::dir_exists(here::here('docs/articles/examples'))) {
  fs::dir_delete(here::here('docs/articles/examples'))
}

pkgdown::clean_site()
pkgdown::build_site()

examples <- fs::dir_ls(
  path = here::here('inst/examples'),
  recurse = TRUE,
  glob = "*.Rmd",
  type = "file"
)

purrr::walk(
  .x = examples,
  .f = rmarkdown::render
)

if (!fs::dir_exists(here::here('docs/'))) {
  rlang::abort('No `pkgdown` website found.')
}

fs::dir_create(
  here::here('docs/articles')
)

fs::dir_copy(
  path = here::here('inst/examples'),
  new_path = here::here('docs/articles/')
)

pkgdown::build_site()
