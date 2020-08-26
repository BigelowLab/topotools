#' etopotools - R tools for use with right whale observations compiled by Hansen Johnson and others.
#'
#' Coding tools for working with local copies of \href{https://ngdc.noaa.gov/mgg/global/}{ETOPO data}.
#'
#' @name etopotools
#' @aliases etopo etopo1
#' @docType package
NULL

#' Retrieve the etopo path
#'
#' @export
#' @param ... file path segments to append to the root
#' @param root character, the root directory
#' @return file path sepcification (whihc may not exists)
etopo_path <- function(..., root = "/mnt/ecocast/coredata/bathy/ETOPO1"){
  file.path(root[1], ...)
}


#' Read a raster file - possibly subsetting
#'
#' @export
#' @param filename character, the name of the file to read
#' @param bb numeric (or NULL), 4 element subsetting bounding box [west, east, south, north]
#' @param path character, the path to the etopo datasets
#' @return NULL or RasterLayer
read_etopo <- function(filename = c("ETOPO1_Ice_c_geotiff.tif",
                                    "ETOPO1_Ice_c_mask.tif")[1],
                       bb = NULL,
                       path = etopo_path()){
  f <- file.path(path, filename[1])
  if (!file.exists(f)) stop("file not found:", f)
  R <- raster::raster(f)
  cur_proj <- raster::projection(R)
  if (is.na(cur_proj) || nchar(cur_proj) == 0) raster::projection(R) <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
  if (!is.null(bb[[1]])){
    R <- raster::crop(R, bb)
  }
  R
}

#' Mask a raster of ETOPO data
#'
#' @export
#' @param x raster, as per \code{read_etopo}
#' @param value numeric, the value around which to threshold
#' @param where character, indiates what gets masked relative to 0
#' \itemize{
#' \item{above, values at or above \code{value} are assigned NA, all others assigned 1 - this masks area at or above sealevel}
#' \item{at, values at \code{value} are assigned NA, above +1 and below -1}
#' \ietm{below, values at or below \code{value} are assigned NA, all others assigned 1 - this masks area at or below sealevel}
#' }
mask_etopo <- function(x = read_etopo(),
                       value = 0,
                       where = c("above", "at", "below")[1]){

  m <- switch(tolower(where[1]),
              "above" = {
                ix <- x[] >= value
                x[ix] <- NA
                x[!ix] <- 1
                x
              },
              "at" = {
                ix <- abs(x[] - value) <= .Machine$double.eps
                x[ix] <- 1
                x[!ix] <- NA
                x
              },
              "below" = {
                 ix <- x[] <= value
                x[ix] <- 1
                x[!ix] <- NA
                x
              })

}
