
<!-- README.md is generated from README.Rmd. Please edit that file -->

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

The goal of `fidelius` is to provide a simple way to encrypt and
password-protect your static HTML files and provide lightweight, secure,
and self-contained in-browser decryption.

This package sits on the shoulders of the cryptography library,
`sodium`, to provide secure methods for encryption, decryption, and
password hashing - both by it’s `R` interface via
[`sodium`](https://github.com/jeroen/sodium) and its JavaScript API for
in-browser decryption.

## Installation

Currently, you can only the development version of this package from
GitHub by running the following command:

``` r
remotes::install_github("mattwarkentin/fidelius")
```

If you notice any bugs or would like to request new features, please
feel free to file an
[Issue](https://github.com/mattwarkentin/fidelius/issues).

## Usage

You will generally only use a single function from this package, the
eponymously named `fidelius()` function. As its main input, this
function will accept an R Markdown file, that can be rendered to any
HTML format, or an existing HTML file.

``` r
library(fidelius)
```

When calling `fidelius()`, you must either supply the password in the
function call, like `fidelius("index.Rmd", password = "pw1234!")`, or,
if `password` is not supplied, you will be prompted to supply the
password in a pop-up (only if the function is invoked in an interactive
`R` session). The password can be any set of characters that can be
hashed using the `sodium::sha256()` algorithm.

``` r
# To supply the password interactively
fidelius("index.Rmd")
```

The HTML document produced by `rmarkdown::render("index.Rmd")` is saved
to a temporary directory (which is destroyed when the `R` session ends),
and then read into `R` and securely encrypted using
`sodium::data_encrypt()`, based on the user-provided password and a
nonce.

The output file is a self-contained HTML document, that contains the
encrypted content, the nonce, and the machinery to perform secure
in-browser decryption, if provided with the correct password. By
default, the name of the output file is the name of the input file with
an HTML extension, but can be configured using the `output` argument to
`fidelius()`.

This package drew heavy inspiration from the
[`staticrypt`](https://github.com/robinmoisson/staticrypt),
[`rmdprotectr`](https://github.com/favstats/rmdprotectr), and
[`encryptedRmd`](https://github.com/dirkschumacher/encryptedRmd)
projects.

## Themeing

TODO

## Code of Conduct

Please note that the fidelius project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
