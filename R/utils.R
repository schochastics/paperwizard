#' Summary of delivered articles
#' @param x result from [pw_deliver()]
#' @param n integer cutoff when articles are considered too short (default 100)
#' @return nothing. called for side effects
#' @export
pw_report <- function(x, n = 100) {
    expect_cols <- c(
        "url", "expanded_url", "domain", "status", "datetime",
        "author", "headline", "text"
    )
    name_bool <- expect_cols %in% names(x)
    if (all(name_bool)) {
        cli::cli_alert_success("all expected columns present")
    } else {
        missing <- expect_cols[!name_bool]
        cli::cli_alert_warning("could not find {.val {missing}}", wrap = TRUE)
    }
    for (col in expect_cols) {
        .missing(x, col)
    }
    if ("text" %in% names(x)) {
        text_len <- sapply(x$text, nchar)
        short <- sum(text_len <= n)
        if (short == 0) {
            cli::cli_alert_success("all articles are longer than {n} characters .")
        } else {
            percent <- round(short / nrow(x) * 100, 2)
            cli::cli_alert_warning("{short} ({percent}%) articles have less than {n} characters.")
        }
    }
    return(invisible(NULL))
}

.missing <- function(x, col) {
    if (col %in% names(x)) {
        err <- sum(is.na(x[[col]]) | as.character(x[[col]]) == "")
        if (err == 0) {
            cli::cli_alert_success("no missing values for {col}.")
        } else {
            percent <- round(err / nrow(x) * 100, 2)
            cli::cli_alert_warning("{err} ({percent}%) missing values for {col}.")
        }
    } else {
        cli::cli_alert_danger("could not find column {col}")
    }
}

.clean_text <- function(x) {
    x <- gsub("\\s*\\n\\s*", "\n", x)
    x <- gsub("^\\s+|\\s+$", "", x)
    x <- gsub("\\n{2,}", "\n", x)
    trimws(x)
}

.empty_obj <- function(y) {
    tibble::tibble(
        url = y$url,
        expanded_url = y$expanded_url,
        domain = y$domain,
        status = y$status,
        datetime = as.POSIXct(NA),
        author = "",
        headline = "",
        text = "",
        misc = list(NA_character_)
    )
}

.safe_date <- function(x) {
    tryCatch(anytime::anytime(x), error = function(e) as.POSIXct(NA))
}
