#' Scrape using Readability.js
#'
#' @param x Either a vector of urls or a data.frame returned by [paperboy::pb_collect()].
#' @param type either "static" or "dynamic" if articles are scraped
#' @return A tibble similar to the output of [paperboy::pb_deliver()].
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
    parse_articles(
        inputs = x,
        js_type = type,
        is_data_frame = FALSE,
        parse_function = .parse_remote
    )
}

#' @export
pw_deliver.data.frame <- function(x, type = c("static", "dynamic")) {
    if (!"content_raw" %in% colnames(x)) {
        stop("x must be a character vector of URLs or a data.frame returned by paperboy::pb_collect.")
    }
    parse_articles(
        inputs = x,
        js_type = "local",
        is_data_frame = TRUE,
        parse_function = .parse_local
    )
}

parse_articles <- function(inputs, js_type, is_data_frame = FALSE, parse_function) {
    # Determine JS file and Node path
    js_file <- paste0("extractor_", js_type, ".js")
    node_script <- system.file("js", js_file, package = "paperwizard")
    node_path <- getOption("paperwizard.node_path", "node")
    n <- ifelse(is_data_frame, nrow(inputs), length(inputs))
    # Set up results and progress bar
    res <- vector("list", length = n)
    cli::cli_progress_bar("Parsing ", total = n)
    parsing_errors <- 0

    if (is_data_frame) {
        dat <- inputs[i, ]
    } else {
        dat <- inputs[i]
    }

    # Iterate over each input
    for (i in seq_len(n)) {
        cli::cli_progress_update()

        # Handle character vs data.frame specifics
        if (is_data_frame && is.na(inputs$content_raw[i])) {
            res[[i]] <- .empty_obj(dat)
            next()
        }

        file <- tempfile(pattern = "article_", fileext = "json")

        # For data frames, write HTML content to a temporary file
        if (is_data_frame) {
            htmlfile <- tempfile(pattern = "article_", fileext = "html")
            write(inputs$content_raw[i], htmlfile)
            args <- c(node_script, htmlfile, file)
        } else {
            args <- c(node_script, inputs[i], file)
        }

        # Run the node script
        result <- processx::run(node_path, args)

        # Handle any errors in parsing
        if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
            parsing_errors <- parsing_errors + 1
            next()
        }

        # Parse result if file exists
        if (file.exists(file)) {
            article_content <- jsonlite::fromJSON(file)
            res[[i]] <- if (is.null(article_content)) {
                .empty_obj(dat)
            } else {
                parse_function(dat, article_content)
            }
        } else {
            warning("No output found. Check if the script ran correctly.")
        }

        # Clean up temporary files
        unlink(c(file, if (is_data_frame) htmlfile))
    }

    cli::cli_progress_done()

    # Warning if there were parsing errors
    if (parsing_errors > 0) {
        cli::cli_alert_warning("Failed to parse {parsing_errors} url{?s}")
    }

    return(do.call("rbind", res))
}

.parse_remote <- function(url, json) {
    json[sapply(json, is.null)] <- ""
    if (json$publishedTime == "") {
        datetime <- as.POSIXct(NA)
    } else {
        datetime <- .safe_date(json$publishedTime)
    }
    tibble::tibble(
        url = url,
        expanded_url = url, # TODO better handling
        domain = adaR::ada_get_domain(url),
        status = 200, # TODO: better handling
        datetime = datetime,
        author = json$byline,
        headline = json$title,
        text = .clean_text(json$textContent),
        misc = list(json) # dump all
    )
}

.parse_local <- function(x, json) {
    json[sapply(json, is.null)] <- ""
    if (json$publishedTime == "") {
        datetime <- as.POSIXct(NA)
    } else {
        datetime <- .safe_date(json$publishedTime)
    }
    tibble::tibble(
        url = x$url,
        expanded_url = x$expanded_url,
        domain = x$domain,
        status = x$status,
        datetime = datetime,
        author = json$byline,
        headline = json$title,
        text = .clean_text(json$textContent),
        misc = list(json) # dump all
    )
}
