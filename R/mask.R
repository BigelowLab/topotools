#' Mask a raster of topo data
#'
#' @export
#' @param x SpatRaster or stars, as per \code{read_etopo} or \code{read_gebco}
#' @param value numeric, the value around which to threshold
#' @param where character, indicates what gets masked relative to 0
#' \itemize{
#' \item{above, values at or above \code{value} are assigned NA, all others assigned 1 - this masks area at or above sealevel}
#' \item{at, values at \code{value} are assigned NA, above +1 and below -1}
#' \item{below, values at or below \code{value} are assigned NA, all others assigned 1 - this masks area at or below sealevel}
#' }
#' @return SpatRaster or stars
mask_topo <- function(x = read_etopo(),
                      value = 0,
                      where = c("above", "at", "below")[1]){
  
  if (inherits(x, "SpatRaster")){
  
    x <- switch(tolower(where[1]),
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
  } else {
   
    x <- switch(tolower(where[1]),
                "above" = {
                  dplyr::mutate(x, z = dplyr::if_else(.data$z >= value, NA, .data$z))
                },
                "at" = {
                  dplyr::mutate(x, dplyr::na_if(.data$z, value))
                },
                "below" = {
                  dplyr::mutate(x, z = dplyr::if_else(.data$z <= value, NA, .data$z))
                })
     
  }

  x
}
