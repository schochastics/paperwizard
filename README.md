
# paperwizard <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/schochastics/paperwizard/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/schochastics/paperwizard/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`paperwizard` is an R package designed to extract readable content (such as news
articles) from webpages using
[Readability.js](https://github.com/mozilla/readability). This package leverages
Node.js to parse webpages and identify the main content of an article, allowing
you to work with cleaner, structured content.

The package is supposed to be an addon for [paperboy](https://github.com/jbgruber/paperboy).

## Installation

You can install the development version of paperwizard like so:

``` r
remotes::install_github("schochastics/paperwizard")
```

## Setup

To use `paperwizard`, you need to have Node.js installed. Download and install Node.js from the [official
website](https://nodejs.org/en/download/package-manager). The page offers
instructions for all major OS. After installing Node.js, you can confirm the
installation by running the
following command in your terminal.
```bash
node -v
```
This should return the version of Node.js installed.

To make sure that the package knows where the command `node` is found, set 
```r
options(paperwizard.node_path = "/path/to/node")
```
if it is not installed in a standard location.

Once Node.js is installed, you need to install the necessary libraries which are
linkedom, Readability.js, puppeteer and axios.

```r
pw_npm_install()
```
## Use

You can use it either by supplying a url

```r
pw_deliver(url)
```

or a data.frame that was created by `paperboy::pb_collect()`
```r
x <- paperboy::pb_collect(list_or_urls)
pw_deliver(x)
```

## Known sites with issues