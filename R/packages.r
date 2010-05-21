#' Installed packages.
#'
#' Runs about 10x faster than \code{\link{installed.packages}}
#' @return a list of packages
installed_packages <- function() {
  paths <- unlist(lapply(.libPaths(), dir, full.names = TRUE))
  desc <- file.path(paths, "DESCRIPTION")
  desc <- desc[file.exists(desc)]
  
  dcf <- lapply(desc, read.dcf, fields = c("Package", "Title", "Version"))
  packages <- as.data.frame(do.call("rbind", dcf), stringsAsFactors = FALSE)
  
  packages$status <- ifelse(packages$Package %in% .packages(), 
    "loaded", "installed")
  class(packages) <- c("packages", class(packages))
  packages
}

as.list.packages <- function(x) {
  alply(x, 1, as.list)
}

#' Out of date packages.
#' Local packages that need updating.
old_packages <- function() {
  packages <- installed_packages()
  old <- as.data.frame(old.packages(), stringsAsFactors = FALSE)$Package
  
  packages$status[packages$Package %in% old] <- "old"
  packages
}

#' Update old packages
#' update all packages that are old and currently loaded
#'
#' @author Barret Schloerke \email{bigbear@@iastate.edu}
#'
update_loaded_packs <- function() {
  packs <- loaded_packs()
  packs <- packs[packs %in% old.packages()[,"Package"]]
  install.packages(packs)
  packs
}