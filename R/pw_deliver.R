#' Scrape using Readability.js
#'
#' @param url The URL of the webpage to extract the article from.
#' @param file The name of the file where the article will be saved (e.g., 'my_article.json').
#' @param type either "static" or "dynamic". Dynamic uses puppeteer
#' @return The article content as a list (title and content).
#' @export
pw_deliver <- function(url, file = "article.json", type = c("static", "dynamic")) {
    type <- match.arg(type)
    # Find the location of the Node.js script within the package
    node_script <- system.file("js", "extractReadability.js", package = "paperwizard")

    node_path <- "node"

    result <- processx::run(node_path, c(node_script, url, file), error_on_status = TRUE, echo_cmd = TRUE)

    # Check for any error in the process
    if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
        stop("Error occurred during execution: ", result$stderr)
    }

    # Read the generated JSON output from the specified file
    if (file.exists(file)) {
        article_content <- jsonlite::fromJSON(file)
        return(article_content)
    } else {
        stop("No output file found. Check if the script ran correctly.")
    }
}
