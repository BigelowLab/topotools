#' topotools - R tools for use topography/bathymetry datasets.
#'
#' @name topotools
#' @aliases etopo etopo1 gebco
#' @docType package
NULL


#' Mask a raster of topo data
#'
#' @export
#' @param x raster, as per \code{read_etopo} or \code{read_gebco}
#' @param value numeric, the value around which to threshold
#' @param where character, indicates what gets masked relative to 0
#' \itemize{
#' \item{above, values at or above \code{value} are assigned NA, all others assigned 1 - this masks area at or above sealevel}
#' \item{at, values at \code{value} are assigned NA, above +1 and below -1}
#' \item{below, values at or below \code{value} are assigned NA, all others assigned 1 - this masks area at or below sealevel}
#' }
#' @return RasterLayer or SpatRaster
mask_topo <- function(x = read_etopo(),
                       value = 0,
                       where = c("above", "at", "below")[1]){

  m <- switch(tolower(where[1]),
              "above" = {
                ix <- x[drop = TRUE] >= value
                x[ix] <- NA
                x[!ix] <- 1
                x
              },
              "at" = {
                ix <- abs(x[drop = TRUE] - value) <= .Machine$double.eps
                x[ix] <- 1
                x[!ix] <- NA
                x
              },
              "below" = {
                ix <- x[drop = TRUE] <= value
                x[!ix] <- 1
                x[ix] <- NA
                x
              })
  m
}
