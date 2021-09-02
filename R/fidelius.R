#' Encrypted HTML Documents
#'
#' Encrypt and password protect an HTML document.
#'
#' @param input Path to an R Markdown or HTML file.
#' @param output Name of output file.
#' @param password Password to unlock file.
#' @param ... Arguments passed on to `rmarkdown::render()`.
#'
#' @return `input`, invisibly.
#'
#' @export

fidelius <- function(input, output = NULL, password, ...) {
  input <- fs::path_real(input)
  input_ext <- tolower(fs::path_ext(input))

  if (!input_ext %in% c('rmd', 'html')) {
    rlang::abort(
      paste0("`input` must be an R Markdown file (`.Rmd`) or ",
             "an HTML file (`.html`).")
    )
  }

  needToRender <- switch(input_ext,
    'rmd' = TRUE,
    'html' = FALSE
  )

  output <- if (is.null(output)) {
    output_dir <- fs::path_dir(input)
    new_file <- fs::path_ext_set(fs::path_file(input), 'html')
    paste0(output_dir, '/', new_file)
  } else {
    fs::path_real(output)
  }

  if (missing(password) & interactive()) {
    password <- askpass::askpass("Please enter your password")
  } else {
    rlang::abort("`password` is missing and must be supplied.")
  }

  password_raw <- sodium::sha256(charToRaw(password))
  nonce_raw <- sodium::random(24)
  nonce_hex <- sodium::bin2hex(nonce_raw)

  if (needToRender) {
    file_to_encrypt <- tempfile(fileext = ".html")
    rmarkdown::render(
      input = input,
      output_file = file_to_encrypt,
      ...
    )
  } else {
    file_to_encrypt <- input
  }

  msg <- readr::read_file(file_to_encrypt)
  msg_raw <- charToRaw(msg)
  msg_enc <- sodium::data_encrypt(msg_raw, password_raw, nonce_raw)
  msg_enc_hex <- sodium::bin2hex(msg_enc)

  content <- list(
    nonce = nonce_hex,
    encrypted = msg_enc_hex
  )

  insert_content(output, content)

  invisible(input)
}

insert_content <- function(path, content) {
  index_html <- get_fidelius_file('fidelius.html')
  template <- readr::read_file(index_html)
  filled <- whisker::whisker.render(
    template = template,
    data = content
  )
  writeLines(
    text = filled,
    con = path,
    sep = "\n"
  )
}
