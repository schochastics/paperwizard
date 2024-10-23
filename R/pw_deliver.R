#' Scrape using Readability.js
#'
#' @param x Either a url or a data.frame returned by \link{paperboy::pb_collect}.
#' @param type either "static" or "dynamic" if articles are scraped
#' @return The article content as a list (title and content).
#' @export
pw_deliver <- function(x, type = c("static", "dynamic")) {
    UseMethod("pw_deliver")
}

#' @export
pw_deliver.default <- function(x, type = c("static", "dynamic")) {
    stop("No method for class ", class(x), ".")
}

#' @export
pw_deliver.character <- function(x, type = c("static", "dynamic")) {
    type <- match.arg(type)

    js_file <- paste0("extractor_", type, ".js")
    file <- tempfile(pattern = "article", fileext = "json")

    node_script <- system.file("js", js_file, package = "paperwizard")
    node_path <- getOption("paperwizard.node_path", "node")
    result <- processx::run(node_path, c(node_script, x, file))

    if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
        stop("Error occurred during execution: ", result$stderr)
    }

    if (file.exists(file)) {
        article_content <- jsonlite::fromJSON(file)
        return(.parse_remote(x, article_content))
    } else {
        stop("No output found. Check if the script ran correctly.")
    }
    on.exit(unlink(file))
}

#' @export
pw_deliver.data.frame <- function(x, type = c("static", "dynamic")) {
    if (!"content_raw" %in% colnames(x)) {
        stop("x must be a character vector of URLs or a data.frame returned by paperboy::pb_collect.")
    }

    js_file <- paste0("extractor_", "local", ".js")
    file <- tempfile(pattern = "article_", fileext = "json")
    htmlfile <- tempfile(pattern = "article_", fileext = "html")
    write(x$content_raw, htmlfile)
    node_script <- system.file("js", js_file, package = "paperwizard")
    node_path <- getOption("paperwizard.node_path", "node")
    result <- processx::run(node_path, c(node_script, htmlfile, file))

    if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
        stop("Error occurred during execution: ", result$stderr)
    }

    if (file.exists(file)) {
        article_content <- jsonlite::fromJSON(file)
        return(.parse_local(x, article_content))
    } else {
        stop("No output found. Check if the script ran correctly.")
    }
    on.exit(unlink(c(file, htmlfile)))
}

.parse_remote <- function(url, json) {
    json[sapply(json, is.null)] <- NA
    if (is.na(json$publishedTime)) {
        datetime <- NA
    } else {
        datetime <- lubridate::as_datetime(json$publishedTime)
    }
    tibble::tibble(
        url = url,
        expanded_url = url, # TODO better handling
        domain = adaR::ada_get_domain(url),
        status = 200, # TODO: better handling
        datetime = datetime,
        author = json$byline,
        headline = json$title,
        text = json$textContent,
        misc = list(json) # dump all
    )
}

.parse_local <- function(x, json) {
    json[sapply(json, is.null)] <- NA
    if (is.na(json$publishedTime)) {
        datetime <- NA
    } else {
        datetime <- lubridate::as_datetime(json$publishedTime)
    }
    tibble::tibble(
        url = x$url,
        expanded_url = x$url,
        domain = x$domain,
        status = x$status,
        datetime = datetime,
        author = json$byline,
        headline = json$title,
        text = json$textContent,
        misc = list(json) # dump all
    )
}
