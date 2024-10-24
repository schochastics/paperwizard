#' Run NPM install
#' Run NPM install to install dependencies
#' @return An installed lib
#' @export
pw_npm_install <- function() {
    # Maybe the user has a custom location for the paperwizard package
    sys_paperwizard <- system.file(
        "js",
        package = "paperwizard"
    )
    # If the user has a custom location, copy the files there
    if (Sys.getenv("PAPERWIZARD_HOME") != sys_paperwizard) {
        lapply(
            list.files(sys_paperwizard, full.names = TRUE),
            function(x) {
                file.copy(
                    from = x,
                    to = file.path(Sys.getenv("PAPERWIZARD_HOME"), basename(x))
                )
            }
        )
    }
    node_path <- getOption("paperwizard.node_path", "node")
    processx::run(
        command = node_path,
        args = c("install"),
        wd = Sys.getenv("PAPERWIZARD_HOME", sys_paperwizard)
    )

    return(invisible(node_path))
}
