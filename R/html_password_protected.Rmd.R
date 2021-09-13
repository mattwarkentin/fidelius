#' Password Protected HTML Document
#'
#' An R Markdown document format to encrypt and password protect any HTML
#' document using `charm()`.
#'
#' @param output_format An R Markdown format that renders to HTML. By default,
#'   will render to the standard `rmarkdown::html_document()` format.
#' @param style Any number of style options that are configurable via
#'   `stylize()`. For example:
#'
#'   ```
#'   output:
#'     fidelius::html_password_protected:
#'       style:
#'         button_text: "Open Sesame!"
#'   ```
#'
#' @param preview Logical. Set to `FALSE` to bypass the encryption and
#'   password protection to render the HTML document specified by
#'   `output_format`. See Notes for more details.
#' @param ... Not currently used.
#'
#' @inheritParams charm
#'
#' @note
#'
#' Using `html_password_protected` format requires you to hard-code your
#'   `password` into the YAML header of the document. As such, the
#'   R Markdown file should never be checked into a public version control
#'   repository (e.g. git or GitHub) where the password is stored and visible
#'   in plain-text. Please use this format carefully.
#'
#' @note
#'
#' Try using `xaringan::infinite_moon_reader()` with `preview = TRUE` to
#'   preview your document with automatic reloading of slides on change. When
#'   you are done developing your document, set `preview = FALSE` or remove it
#'   from the YAML header entirely to encrypt and password protect your
#'   document.
#'
#' @seealso
#' \code{\link{charm}} for more information on the password protection and
#'   encryption.
#'
#' @return
#' R Markdown output format based on `output_format` to pass to
#'   `rmarkdown::render()`.
#'
#' @export

html_password_protected <- function(
  output_format = "rmarkdown::html_document",
  password,
  hint = NULL,
  style = list(),
  bundle = FALSE,
  minified = TRUE,
  preview = FALSE,
  ...
) {
  if (missing(password)) {
    if (rstudioapi::isAvailable(child_ok = TRUE)) {
      password <- rstudioapi::askForPassword()
    } else {
      rlang::abort("`password` must be provided.")
    }
  }
  if (inherits(output_format, "character")) {
    format_fun <- rlang::parse_expr(output_format)
    format <- rlang::exec(.fn = format_fun)
  } else {
    format_fun <- rlang::parse_expr(names(output_format)[[1]])
    format_args <- output_format[[1]]
    format <- rlang::exec(format_fun, !!!format_args)
  }

  if (!gregexpr(format$pandoc$to, "^html")[[1]]) {
    rlang::abort("`output_format` must render to an HTML document.")
  }

  initial_post_process <- format$post_processor
  if (!preview) {
    format$post_processor <- function(metadata, input_file, output_file,
                                      clean, verbose) {
      on.exit(
        charm(
          input = output_file,
          password = password,
          hint = hint,
          style = rlang::inject(stylize(!!!style)),
          bundle = bundle,
          minified = minified
        )
      )
      initial_post_process(metadata, input_file, output_file, clean, verbose)
    }
  }
  format
}
