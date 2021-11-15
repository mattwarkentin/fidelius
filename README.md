
# fidelius

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/mattwarkentin/fidelius/workflows/R-CMD-check/badge.svg)](https://github.com/mattwarkentin/fidelius/actions)
<!-- badges: end -->

> “An immensely complex spell involving the magical concealment of a
> secret inside a single, living soul. The information is hidden inside
> the chosen person, or Secret-Keeper, and is henceforth impossible to
> find - unless, of course, the Secret-Keeper chooses to divulge it.”

The goal of `fidelius` is to provide a simple interface for encrypting
and password-protecting your static HTML files, and supporting secure
and (optionally) self-contained in-browser authentication and
decryption.

This package sits on the shoulders of the cryptography library,
[`sodium`](https://doc.libsodium.org/), to provide secure methods for
encryption, decryption, and password hashing - both by it’s `R`
interface via [`{sodium}`](https://github.com/jeroen/sodium) and its
[JavaScript API](https://github.com/jedisct1/libsodium.js) for
in-browser decryption.

This package drew inspiration from the
[`staticrypt`](https://github.com/robinmoisson/staticrypt),
[`rmdprotectr`](https://github.com/favstats/rmdprotectr), and
[`encryptedRmd`](https://github.com/dirkschumacher/encryptedRmd)
projects.

## Installation

You can install the released version of fidelius from CRAN with:

``` r
install.packages('fidelius')
```

You can install the development version of fidelius from GitHub with:

``` r
remotes::install_github("mattwarkentin/fidelius")
```

If you notice any bugs or would like to request new features, please
feel free to file an
[Issue](https://github.com/mattwarkentin/fidelius/issues).

## Usage

``` r
library(fidelius)
```

There are two main functions that you will use:

1.  [`charm()`](#charm) - Use this function to render an existing R
    Markdown or HTML document into a `fidelius` password-protected HTML
    document.

2.  [`html_password_protected()`](#html_password_protected) - An R
    Markdown `output` format that can be used directly in the YAML
    frontmatter to create password-protected files rendered to other
    HTML formats.

In both cases, the desired HTML document format is rendered and then
securely encrypted using `sodium::data_encrypt()`, based on the
user-provided `password` and a nonce. The `output` file is an HTML
document that contains the encrypted content, the nonce, and the
machinery to perform secure in-browser authentication and decryption.
The correct password is required to reveal the hidden content. The
output file can be hosted on any static site hosting service
(e.g. GitHub Pages) for browser-side password-protection.

By default, the name of the output file is the name of the input file
with an HTML extension, but this can be configured using the `output`
argument.

### `charm()`

As its main input, `charm()` accepts an R Markdown file (that must be
rendered to an HTML format) or an existing HTML file.

When calling `charm()`, you must either supply the password in the
function call, like `charm("index.Rmd", password = "pw1234!")`, or, if
`password` is not supplied, you will be prompted to supply the password
in a pop-up (only if the function is invoked in an interactive `R`
session). The password can be any set of characters that can be hashed
using the `sodium::hash()` algorithm.

``` r
# To supply the password interactively
charm("index.Rmd")
```

If an R Markdown file is provided as `input`, the HTML document produced
by `rmarkdown::render(input)` is saved to a temporary directory that is
destroyed when the `R` session ends.

See [Styling](#styling) and [Password Hint](#password-hint) for more
details on how to style your landing page and how to include a helpful
password hint!

### `html_password_protected()`

Use `html_password_protected` by supplying it as the `output` in the
YAML frontmatter of an R Markdown file.

``` yaml
---
output: fidelius::html_password_protected
---
```

By default, this will render your content as an
`rmarkdown::html_document()` before encrypting and password protecting
the document.

To render to a different format, specify the `output_format` (you may
pass any additional arguments to the desired `output_format` as you
normally would):

``` yaml
---
output:
  fidelius::html_password_protected:
    output_format: 
      rmarkdown::html_document:
        toc: true
---
```

`fidelius` is compatible with most existing HTML output formats. See
website for examples. At the moment, `{bookdown}` formats are not
supported due to their unique rendering process (this may change in the
future).

In both of the above examples, if you try to render the document by
using the “Knit” button in RStudio or using `rmarkdown::render()` in an
interactive session, you will be prompted to supply a `password`. In a
non-interactive session, the rendering will fail.

You may include the `password` directly in the YAML frontmatter, but be
sure not to store the R Markdown file in a public repository as the
password will be visible in plain-text.

``` yaml
---
output:
  fidelius::html_password_protected:
    password: "pw1234!"
    output_format: rmarkdown::html_document
---
```

During development, you may wish to set `preview = TRUE` to bypass the
encryption and password-protection steps in order to view the document
more quickly. This option pairs very nicely with
`xaringan::infinite_moon_reader()` to view changes in real time.

``` yaml
---
output:
  fidelius::html_password_protected:
    password: "pw1234!"
    preview: true
---
```

## Styling

You may wish to style the aesthetics and text of the password landing
page to your own preferences. This can be done simply by passing the
`stylize()` function to the `style` argument, or by specifying `style`
arguments directly in the YAML frontmatter.

``` r
charm("index.Rmd", style = stylize(button_text = "Open Sesame!"))
```

or

``` yaml
---
output:
  fidelius::html_password_protected:
    style:
      button_text: "Open Sesame!"
---
```

See `?fidelius::stylize` to find out more about which aspects of the
landing page can be styled.

## Password Hint

Optionally, you may wish to provide a helpful hint for anyone (or
yourself) trying to remember the password and gain access to the
document. You can do this by passing a string to the `hint` argument:

``` r
charm("index.Rmd", password = "pw1234!", hint = "A very bad password!")
```

or

``` yaml
---
title: "My Protected Document"
output:
  fidelius::html_password_protected:
    password: "pw1234!"
    hint: "A very bad password!"
---
```

Providing a `hint` will include the lightweight
[`Micromodal`](https://github.com/ghosh/Micromodal) JavaScript library
to provide a simple modal pop-up that contains your password hint.

## Portability

You may specify `bundle = TRUE` (or `bundle: true`) to bundle all of the
`fidelius` dependencies for offline use. If the `input` file (or
`output_format`) is also self-contained (such as with
`self_contained = TRUE`), the `fidelius` HTML document is entirely
self-contained and can easily be shared with others (e.g. via email) as
a standalone document. See `?charm` for more details.

## Password Manager

I have tried to make sure that `fidelius` is compatible with common
password management tools (e.g. 1Pass, LastPass, etc.). If your password
manager is not detecting the password field on the `fidelius` landing
page, please [file an
issue](https://github.com/mattwarkentin/fidelius/issues) that includes
which browser and password manager you use, and I will work to support
it.

## Code of Conduct

Please note that the fidelius project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
