#' Password protect a document
#'
#' Encrypt and password protect an HTML document.
#'
#' @param input Path to an R Markdown or HTML file.
#' @param password Private password to unlock file. If not provided, you will
#'   be asked to supply a password by a prompt if you are working from an
#'   interactive session.
#' @param hint Optional public password hint.
#' @param output Override the name of the output file.
#' @param style Object returned from `stylize()`.
#' @param bundle Logical. Should all of the decryption machinery and
#'   dependencies be bundled into the HTML document? Default is `FALSE`.
#' @param minified Logical. Should minified versions of JavaScript dependencies
#'   be included? Default is `TRUE`.
#' @param ... Arguments passed on to `rmarkdown::render()`.
#'
#' @note Using `bundle = TRUE` only applies to bundling the
#'   decryption machinery and dependencies for the document generated
#'   by `charm()`. It is still the users responsibility to decide on whether
#'   `input` is self-contained by passing `self_contained = TRUE` to
#'   `rmarkdown::render()` using `...`, or by specifying
#'   `self_contained: true` in the YAML header of `input`.
#'
#' @return `input`, invisibly.
#'
#' @examples
#' \dontrun{
#' charm("input.Rmd")
#'
#' charm("input.Rmd", password = "pw1234!")
#' }
#'
#' @export

charm <- function(
  input,
  password,
  hint = NULL,
  output = NULL,
  style = stylize(),
  bundle = FALSE,
  minified = TRUE,
  ...
) {
  input <- fs::path_real(input)
  input_ext <- tolower(fs::path_ext(input))

  if (!input_ext %in% c('rmd', 'html')) {
    rlang::abort(
      paste0("`input` must be an R Markdown file (`.Rmd`) or ",
             "an HTML file (`.html`).")
    )
  }

  if (!rlang::is_logical(bundle)) {
    rlang::abort(
      paste0("`bundle` must be logical, not ", class(bundle), ".")
    )
  }

  if (!rlang::is_logical(minified)) {
    rlang::abort(
      paste0("`minified` must be logical, not ", class(minified), ".")
    )
  }

  if (!inherits(style, 'fidelius_styling')) {
    rlang::abort("`style` must be an object returned from `stylize()`.")
  }

  need_to_render <- switch(input_ext,
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

  password_raw <- sodium::hash(charToRaw(password))
  nonce_raw <- sodium::random(24)
  nonce_hex <- sodium::bin2hex(nonce_raw)

  if (need_to_render) {
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

  if (bundle) {
    sodium_js <- readr::read_file(
      get_fidelius_file(
        ifelse(minified, 'libsodium/sodium.min.js', 'libsodium/sodium.js')
      )
    )
    fidelius__sodium = inject_minified_script_tag(
      id = "fidelius__sodium",
      code = sodium_js
    )
  } else {
    fidelius__sodium = inject_remote_script_tag(
      id = "fidelius__sodium",
      src = sodiumjs_remote(minified)
    )
  }

  content <- list(
    fidelius__nonce = nonce_hex,
    fidelius__content = msg_enc_hex,
    fidelius__sodium = fidelius__sodium
  )

  if (!rlang::is_null(hint)) {
    micromodal_css <- readr::read_file(
      get_fidelius_file('micromodal/micromodal.css')
    )
    micromodal_html <- readr::read_file(
      get_fidelius_file('micromodal/micromodal.html')
    )
    content$fidelius__micromodal__css <- micromodal_css
    content$fidelius__micromodal__html <- micromodal_html
    content$fidelius__hint <- hint

    if (bundle) {
      micromodal_js <- readr::read_file(
        get_fidelius_file(
          ifelse(minified, 'micromodal/micromodal.min.js',
                 'micromodal/micromodal.js')
        )
      )
      content$fidelius__micromodal__js <-
        inject_minified_script_tag(id = "fidelius__micromodal", micromodal_js)
    } else {
      content$fidelius__micromodal__js <-
        inject_remote_script_tag(
          id = "fidelius__micromodal",
          src = micromodaljs_remote(minified)
        )
    }
  }

  content <- c(content, style)

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

inject_minified_script_tag <- function(id, code) {
  htmltools::tags$script(
    id = id,
    type = "text/javascript",
    htmltools::HTML(code)
  )
}

inject_remote_script_tag <- function(id, src) {
  htmltools::tags$script(id = id, src = src)
}

sodiumjs_remote <- function(minified = TRUE) {
  if (minified) {
    return("https://cdnjs.cloudflare.com/ajax/libs/libsodium-wrappers/0.5.4/sodium.min.js")
  }
  "https://cdnjs.cloudflare.com/ajax/libs/libsodium-wrappers/0.5.4/sodium.js"
}

micromodaljs_remote <- function(minified = TRUE) {
  if (minified) {
    return("https://cdnjs.cloudflare.com/ajax/libs/micromodal/0.4.6/micromodal.min.js")
  }
  "https://cdnjs.cloudflare.com/ajax/libs/micromodal/0.4.6/micromodal.js"
}
