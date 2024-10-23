.onLoad <- function(libname, pkgname) {
    op <- options()
    op.paperwizard <- list(
        paperwizard.node_path = "node"
    )
    toset <- !(names(op.paperwizard) %in% names(op))
    if (any(toset)) options(op.paperwizard[toset])

    invisible()
}
