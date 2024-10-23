#' Scrape using Readability.js
#'
#' @param url The URL of the webpage to extract the article from.
#' @param type either "static" or "dynamic". Dynamic uses puppeteer
#' @return The article content as a list (title and content).
#' @export
pw_deliver <- function(url, type = c("static", "dynamic")) {
    type <- match.arg(type)
    js_file <- paste0("extractor_", type, ".js")
    file <- tempfile(pattern = "article", fileext = "json")

    node_script <- system.file("js", js_file, package = "paperwizard")
    node_path <- getOption("paperwizard.node_path", "node")
    result <- processx::run(node_path, c(node_script, url, file))

    if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
        stop("Error occurred during execution: ", result$stderr)
    }

    if (file.exists(file)) {
        article_content <- jsonlite::fromJSON(file)
        return(.parse(url, article_content))
    } else {
        stop("No output found. Check if the script ran correctly.")
    }
    on.exit(unlink(file))
}

.parse <- function(url, json) {
    json[sapply(json, is.null)] <- NA
    if (is.na(json$publishedTime)) {
        datetime <- NA
    } else {
        datetime <- lubridate::as_datetime(json$publishedTime)
    }
    tibble::tibble(
        url = url,
        expanded_url = "TODO",
        domain = adaR::ada_get_domain(url),
        status = 200, # TODO: better handling
        datetime = datetime,
        author = json$byline,
        headline = json$title,
        text = json$textContent,
        misc = list(json) # dump all
    )
}
