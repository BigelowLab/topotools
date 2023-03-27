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
#' @param varname char, by default 'z', but you might have a different name?
#' @param reassign logical, if \code{TRUE} unmasked values are assigned the value 1, but
#'   if \code{FALSE} then they are left unchanged.
#' @return SpatRaster or stars
mask_topo <- function(x = read_etopo(),
                      value = 0,
                      where = c("above", "at", "below")[1],
                      varname = "z",
                      reassign = FALSE){
  
  if (inherits(x, "SpatRaster")){
  
    x <- switch(tolower(where[1]),
                "above" = {
                  ix <- x[drop = TRUE] >= value[1]
                  x[ix] <- NA
                  if (reassign) x[!ix] <- 1
                  x
                },
                "at" = {
                  ix <- abs(x[drop = TRUE] - value) <= .Machine$double.eps
                  x[ix] <- 1
                  if (reassign) x[!ix] <- NA
                  x
                },
                "below" = {
                  ix <- x[drop = TRUE] <= value
                  x[!ix] <- 1
                  if (reassign) x[ix] <- NA
                  x
                })
  } else {
   
    vn <- varname[1]
    x <- switch(tolower(where[1]),
                "above" = {
                  ix <- x[[vn]] >= value[1]
                  x[[vn]][ix] <- NA
                  if (reassign) x[[vn]][!ix] <- 1
                  x
                  # dplyr::mutate(x, z = dplyr::if_else(.data$z >= value, NA, .data$z))
                },
                "at" = {
                  ix <- abs(x[[vn]] - value[1]) <= .Machine$double.eps
                  x[[vn]][ix] <- NA
                  if (reassign) x[[vn]][!ix] <- 1
                  x
                  #dplyr::mutate(x, dplyr::na_if(.data$z, value))
                },
                "below" = {
                  ix <- x[[vn]] <= value[1]
                  x[[vn]][ix] <- NA
                  if (reassign) x[[vn]][!ix] <- 1
                  x
                  #dplyr::mutate(x, z = dplyr::if_else(.data$z <= value, NA, .data$z))
                })
     
  }

  x
}
