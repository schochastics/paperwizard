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

    js_file <- paste0("extractor_", type, ".js")
    node_script <- system.file("js", js_file, package = "paperwizard")
    node_path <- getOption("paperwizard.node_path", "node")
    res <- vector("list", length = length(x))
    cli::cli_progress_bar("Parsing ", total = length(x))
    parsing_errors <- 0
    for (i in seq_along(x)) {
        cli::cli_progress_update()
        file <- tempfile(pattern = "article_", fileext = "json")
        result <- processx::run(node_path, c(node_script, x[i], file))

        if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
            parsing_errors <- parsing_errors + 1
            next()
        }

        if (file.exists(file)) {
            article_content <- jsonlite::fromJSON(file)
            res[[i]] <- .parse_remote(x[i], article_content)
        } else {
            warning("No output found. Check if the script ran correctly.")
        }
        unlink(file)
    }
    cli::cli_progress_done()
    on.exit(unlink(file))
    if (parsing_errors > 0) {
        cli::cli_alert_warning("failed to parse {parsing_errors} url{?s}")
    }
    return(do.call("rbind", res))
}

#' @export
pw_deliver.data.frame <- function(x, type = c("static", "dynamic")) {
    if (!"content_raw" %in% colnames(x)) {
        stop("x must be a character vector of URLs or a data.frame returned by paperboy::pb_collect.")
    }

    js_file <- paste0("extractor_", "local", ".js")
    node_script <- system.file("js", js_file, package = "paperwizard")
    res <- vector("list", length = nrow(x))
    cli::cli_progress_bar("Parsing ", total = nrow(x))
    parsing_errors <- 0
    for (i in seq_len(nrow(x))) {
        cli::cli_progress_update()
        if (is.na(x$content_raw[i])) {
            res[[i]] <- .empty_obj(x[i, ])
            next()
        }
        file <- tempfile(pattern = "article_", fileext = "json")
        htmlfile <- tempfile(pattern = "article_", fileext = "html")
        write(x$content_raw[i], htmlfile)

        node_path <- getOption("paperwizard.node_path", "node")
        result <- processx::run(node_path, c(node_script, htmlfile, file))

        if (!is.null(result$stderr) && nchar(result$stderr) > 0) {
            parsing_errors <- parsing_errors + 1
            next()
        }

        if (file.exists(file)) {
            article_content <- jsonlite::fromJSON(file)
            if (is.null(article_content)) {
                res[[i]] <- .empty_obj(x[i, ])
                next()
            }
            res[[i]] <- .parse_local(x[i, ], article_content)
        } else {
            warning("No output found. Check if the script ran correctly.")
        }
        unlink(c(file, htmlfile))
    }
    cli::cli_progress_done()
    # on.exit(unlink(c(file, htmlfile)))
    if (parsing_errors > 0) {
        cli::cli_alert_warning("failed to parse {parsing_errors} url{?s}")
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
