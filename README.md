
# paperwizard

<!-- badges: start -->
<!-- badges: end -->

*(The current status of this package is "it works on my machine")*

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

To use `paperwizard`, you need to have Node.js installed. 

Download and install Node.js from the [official
website](https://nodejs.org/en/download/package-manager). The page offers
instructions for all major OS.

After installing Node.js, you can confirm the installation by running the
following command in your terminal.
```bash
node -v
```

This should return the version of Node.js installed.

Once Node.js is installed, you need to install the necessary libraries which are
JSDOM, Readability.js, puppeteer and axios.

```bash
npm install jsdom @mozilla/readability puppeteer axios
```

To make sure that the package knows where the command `node` is found, set 
```r
options(paperwizard.node_path = "/path/to/node")
```

## Use

```r
pw_deliver(url)
```

## pages that do not work

- spiegel.de [#1](https://github.com/schochastics/paperwizard/issues/1)