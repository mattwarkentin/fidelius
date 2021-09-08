#' Encrypted HTML Documents
#'
#' Encrypt and password protect an HTML document.
#'
#' @param input Path to an R Markdown or HTML file.
#' @param password Password to unlock file.
#' @param hint Public password hint.
#' @param output Name of the output file.
#' @param ... Arguments passed on to `rmarkdown::render()`.
#'
#' @return `input`, invisibly.
#'
#' @export

charm <- function(input, password, hint, output = NULL, ...) {
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

  if (missing(password)) {
    if (interactive()) {
      password <- askpass::askpass("Please enter your password")
    } else {
      rlang::abort("`password` is missing and must be supplied.")
    }
  }

  password_raw <- sodium::sha256(charToRaw(password))
  nonce_raw <- sodium::random(24)
  nonce_hex <- sodium::bin2hex(nonce_raw)

  if (needToRender) {
    file_to_encrypt <- tempfile(fileext = ".html")
    rmarkdown::render(
      input = input,
      output_file = file_to_encrypt,
      intermediates_dir = tempdir(),
      ...
    )
  } else {
    file_to_encrypt <- input
  }

  msg <- readr::read_file(file_to_encrypt)
  msg_raw <- charToRaw(msg)
  msg_enc <- sodium::data_encrypt(msg_raw, password_raw, nonce_raw)
  msg_enc_hex <- sodium::bin2hex(msg_enc)

  sodium <- readr::read_file_raw(get_fidelius_file('libsodium/sodium.js'))
  sodium_b64 <- base64enc::base64encode(sodium)

  content <- list(
    fidelius__nonce = nonce_hex,
    fidelius__content = msg_enc_hex,
    fidelius__sodium = inject_script_tag(sodium_b64)
  )

  if (!missing(hint)) {
    micromodal_js <- readr::read_file_raw(get_fidelius_file('micromodal/micromodal.min.js'))
    micromodal_b64 <- base64enc::base64encode(micromodal_js)
    micromodal_css <- readr::read_file(get_fidelius_file('micromodal/micromodal.css'))
    micromodal_html <- readr::read_file(get_fidelius_file('micromodal/micromodal.html'))
    content$fidelius__micromodal__js <- inject_script_tag(micromodal_b64)
    content$fidelius__micromodal__css <- micromodal_css
    content$fidelius__micromodal__html <- micromodal_html
    content$fidelius__hint <- hint
  }

  filled_template <- insert_content(content)

  writeLines(
    text = filled_template,
    con = output,
    sep = "\n"
  )

  invisible(input)
}

insert_content <- function(content) {
  index_html <- get_fidelius_file('fidelius.html')
  template <- readr::read_file(index_html)
  whisker::whisker.render(template = template, data = content)
}

inject_script_tag <- function(enc) {
  htmltools::tags$script(
    src = paste0(
      "data:application/javascript; charset=utf-8;base64,",
      enc
    )
  )
}
