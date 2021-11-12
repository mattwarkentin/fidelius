#' Style password landing page
#'
#' @description Use this function to style the appearance of the landing
#'   page for the password-protected HTML file.
#'
#' @param header_text Header text.
#' @param placeholder_text Password input placeholder text.
#' @param button_text Button text.
#' @param font_family Font family.
#' @param font_size Font size.
#' @param title_color Title font color.
#' @param background_color Background color.
#' @param box_color Box color.
#' @param btn_font_color Button font color.
#' @param btn_bg_color Button background color.
#' @param btn_hover_color Button hover color.
#' @param modal_overlay Modal overlay color.
#' @param modal_box_color Modal box color.
#' @param modal_title_color Modal title font color.
#' @param modal_font_color Modal text font color.
#'
#' @return A list with class `fidelius_styling`.
#'
#' @examples
#'
#' stylize(font_family = "Times")
#'
#' @export

stylize <- function(
  header_text = "PLEASE ENTER THE PASSWORD",
  placeholder_text = "",
  button_text = "SUBMIT",
  font_family = "-apple-system",
  font_size = "16px",
  title_color = "#2d3737",
  background_color = "#f2f2f2",
  box_color = "#ffffff",
  btn_font_color = "#ffffff",
  btn_bg_color = "#19A974",
  btn_hover_color = "#137752",
  modal_overlay = "rgba(0, 0, 0, 0.6)",
  modal_box_color = "#ffffff",
  modal_title_color = "#137752",
  modal_font_color = "rgba(0, 0, 0, 0.8)"
) {
  structure(
    list(
      header_text = header_text,
      placeholder_text = placeholder_text,
      button_text = button_text,
      font_family = font_family,
      font_size = font_size,
      title_color = title_color,
      background_color = background_color,
      box_color = box_color,
      btn_font_color = btn_font_color,
      btn_bg_color = btn_bg_color,
      btn_hover_color = btn_hover_color,
      modal_overlay = modal_overlay,
      modal_box_color = modal_box_color,
      modal_title_color = modal_title_color,
      modal_font_color = modal_font_color
    ),
    class = "fidelius_styling"
  )
}
