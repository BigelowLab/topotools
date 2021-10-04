#' Retrieve the etopo path
#'
#' @export
#' @param ... file path segments to append to the root
#' @param root character, the root directory
#' @return file path specification (which may not exists)
etopo_path <- function(..., root = topo_path("ETOPO1")){
  file.path(root[1], ...)
}

#' Retrieve the stated resolution of the grid
#'
#' @export
#' @param x ncdfd4 object
#' @param lookup logical, if TRUE then retrieve res from the ncdf4 object, otherwise
#'   return a predetermined resolution
#' @return two element numeric vector or [lon, lat] resolution
etopo_nc_res <- function(x, lookup = FALSE){
  if (lookup){
    res <- c( diff(x$dim$x$vals)[1], diff(x$dim$y$vals)[1])
  } else {
    res <- c(0.0166666666666799, 0.0166666666666657)
  }
  res
}

#' Retrieve GEBCO ncdf navigation values (start, count, lons, lats)
#'
#' @export
#' @param x ncdfd4 object
#' @param bb numeric, 4 element requested bounding box [west, east, south, north]
#' @param res numeric, 2 element resolution [res_x,res_y]
#' @param varname character the name of the variable
#' @return list with
#' \itemize{
#'   \item{bb the requested bounding box}
#'   \item{res the resolution}
#'   \item{start vector of start values}
#'   \item{count vector of count values}
#'   \item{ext vector of extent }
#'   \item{crs character}
#'   \item{varname character}
#' }
etopo_nc_nav <- function(x,
                         bb = c( -72,  -63,   39,   46),
                         res = etopo_nc_res(),
                         varname = "z"){
  stopifnot(inherits(x, 'ncdf4'))
  if (!(varname[1] %in% names(x$var))) stop("varname not known:", varname[1])
  if (length(res) == 1) res <- c(res[1],res[1])
  r2 <- res/2
  # pad bb by res/2 so that we cast a large enough net
  bb2 <- bb + c(-r2[1], r2[1], -r2[2], r2[2])
  ix <- sapply(bb2[1:2],
               function(xbb) which.min(abs(x$dim$x$vals-xbb)))
  we <- x$dim$x$vals[ix]
  iy <- sapply(bb2[3:4],
               function(ybb) which.min(abs(x$dim$y$vals-ybb)))
  sn <- x$dim$y$vals[iy]

  list(bb = bb,
       res = res,
       start = c(ix[1], iy[1]),
       count = c(ix[2] - ix[1] + 1, iy[2] - iy[1] + 1),
       ext = c(we + (res[1]/2 * c(-1,1)), sn + (res[2]/2 * c(-1,1)) ),
       crs = "+proj=longlat +datum=WGS84",
       varname = varname)
}


#' Read a raster file - possibly subsetting
#'
#' @export
#' @param filename character, the name of the file to read
#' @param bb numeric (or NULL), 4 element subsetting bounding box [west, east, south, north]
#' @param path character, the path to the etopo datasets
#' @return SpatRaster
read_etopo <- function(filename = "ETOPO1_Ice_g_gmt4.grd",
                       bb = c( -72,  -63,   39,   46),
                       path = etopo_path()){


  filename <- file.path(path, filename[1])
  if (!file.exists(filename)) stop("file not found:", filename)

  on.exit(ncdf4::nc_close(X))

  X <- try(ncdf4::nc_open(filename))
  if (inherits(X, "try-error")){
    print(X)
    return(NULL)
  }

  nav <- etopo_nc_nav(X, bb = bb)

  M <- ncdf4::ncvar_get(X,
                        varid = nav$varname,
                        start = nav$start,
                        count = nav$count)

  R <- terra::rast(names = nav$varname,
                   crs = nav$crs,
                   ext = terra::ext(nav$ext),
                   nrows = nav$count[2],
                   ncols = nav$count[1])
  terra::values(R) <-  t(M)
  R <- terra::flip(R, "vertical")

  return(R)
}