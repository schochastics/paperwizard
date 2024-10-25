url <- "https://rss.feedspot.com/world_news_rss_feeds/"
doc <- rvest::read_html(url)

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

res <- paperboy::pb_collect(feeds$link, ignore_fails = TRUE)
res <- res |> dplyr::filter(status == 200)
articles <- pw_deliver(res)
pb_report(articles)
