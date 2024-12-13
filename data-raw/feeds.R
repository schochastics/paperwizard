library(dplyr)
url <- c(
    "https://rss.feedspot.com/world_news_rss_feeds/",
    "https://rss.feedspot.com/german_news_rss_feeds/",
    "https://rss.feedspot.com/uk_news_rss_feeds/",
    "https://rss.feedspot.com/usa_news_rss_feeds/",
    "https://rss.feedspot.com/french_news_rss_feeds/",
    "https://rss.feedspot.com/italian_news_rss_feeds/",
    "https://rss.feedspot.com/european_news_rss_feeds/"
)

get_links <- function(x) {
    doc <- rvest::read_html(x)

    feeds <- tibble::tibble(
        name = doc |>
            rvest::html_elements("h3 a") |>
            rvest::html_text(),
        link = doc |>
            rvest::html_elements(".trow.trow-wrap") |>
            rvest::html_elements("a.ext:not(.extdomain)") |>
            rvest::html_attr("href")
    ) |>
        dplyr::filter(link != "")
    return(feeds)
}

feeds <- purrr::map_dfr(url, get_links)

feeds <- feeds |> dplyr::distinct(link, .keep_all = TRUE)

res <- vector("list", nrow(feeds))
for (i in seq_len(nrow(feeds))) res[[i]] <- tryCatch(paperboy::pb_collect(feeds$link[i], ignore_fails = TRUE), error = function(e) NULL)

res_tbl <- do.call("rbind", res) |> dplyr::filter(status == 200)
articles <- pw_deliver(res_tbl)
pw_report(articles, n = 1000)

articles |>
    dplyr::summarise(
        .by = domain,
        tot_date = sum(is.na(datetime)),
        frac_date = tot_date / dplyr::n()
    ) |>
    dplyr::arrange(desc(frac_date), desc(tot_date))

articles |>
    dplyr::mutate(parsed = purrr::map_chr(misc, function(x) x$publishedTime)) |>
    dplyr::select(domain, datetime, parsed) |>
    dplyr::filter(is.na(datetime) & parsed != "")

qs::qsave(articles, "data-raw/pw_deliver.qs")
