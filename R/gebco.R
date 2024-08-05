#' Retrieve the gebco path
#'
#' @export
#' @param ... file path segments to append to the root
#' @param root character, the root directory
#' @return file path sepcification (whihc may not exists)
gebco_path <- function(..., root = topo_path("gebco")){
  file.path(root[1], ...)
}

#' Retrieve the stated resolution of the grid
#'
#' @export
#' @param x ncdfd4 object
#' @param lookup logical, if TRUE then retrieve res from the ncdf4 object, otherwise
#'   return a predetermined resolution
#' @return two element numeric vector or [lon, lat] resolution
gebco_nc_res <- function(x, lookup = FALSE){
  if (lookup){
    A <- ncdf4::ncatt_get(x, varid = 0)
    res <- c(A$geospatial_lon_resolution, A$geospatial_lat_resolution)
  } else {
    res <- c(0.00416666666666667, 0.00416666666666667)
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
gebco_nc_nav <- function(x,
                        bb = c( -72,  -63,   39,   46),
                        res = gebco_nc_res(),
                        varname = "elevation"){
  stopifnot(inherits(x, 'ncdf4'))
  if (!(varname[1] %in% names(x$var))) stop("varname not known:", varname[1])
  if (length(res) == 1) res <- c(res[1],res[1])
  r2 <- res/2
  # pad bb by res/2 so that we cast a large enough net
  bb2 <- bb + c(-r2[1], r2[1], -r2[2], r2[2])
  ix <- sapply(bb2[1:2],
               function(xbb) which.min(abs(x$dim$lon$vals-xbb)))
  we <- x$dim$lon$vals[ix]
  iy <- sapply(bb2[3:4],
               function(ybb) which.min(abs(x$dim$lat$vals-ybb)))
  sn <- x$dim$lat$vals[iy]

  list(bb = bb,
       res = res,
       start = c(ix[1], iy[1]),
       count = c(ix[2] - ix[1] + 1, iy[2] - iy[1] + 1),
       ext = c(we + (res[1]/2 * c(-1,1)), sn + (res[2]/2 * c(-1,1)) ),
       crs = "+proj=longlat +datum=WGS84",
       varname = varname)
}



#' List available files for GEBCO
#' 
#' @export
#' @param path char, the path to the data
#' @param pattern char, regular expression of pattern for search
#' @param most_recent logical, if TRUE return just the most recent file
#' @param ... other arguments for \code{\link[base]{list.files}}
#' @return char possibly fully qualified file paths
list_gebco <- function(path = gebco_path(), 
                       pattern = "^GEBCO_.*\\.nc$",
                       most_recent = TRUE,
                       ...){
  ff = list.files(path, pattern = pattern, ...)
  if (most_recent){
    ff = ff[length(ff)]
  }
  ff
}

#' Read a raster file - possibly subsetting
#'
#' @export
#' @param filename character, the name of the file to read
#' @param bb numeric (or NULL), 4 element subsetting bounding box [west, east, south, north]
#'   or any spatial object inheriting from SpatVector, SpatRaster, sf or stars
#'   from which a bounding box can be extracted
#' @param path character, the path to the etopo datasets
#' @param form char, one of 'SpatRaster' or 'stars' (default)
#' @return SpatRaster or stars object
read_gebco <- function(filename = list_gebco()[1],
                       bb = c( -72,  -63,   39,   46),
                       path = gebco_path(),
                       form = c("SpatRaster", "stars")[2]){

  filename <- file.path(path, filename[1])
  if (!file.exists(filename)) stop("file not found:", filename)

  on.exit(ncdf4::nc_close(X))

  X <- try(ncdf4::nc_open(filename))
  if (inherits(X, "try-error")){
    print(X)
    return(NULL)
  }

  nav <- gebco_nc_nav(X, bb = as_bb(bb))

  M <- ncdf4::ncvar_get(X,
                        varid = nav$varname,
                        start = nav$start,
                        count = nav$count)

  if (tolower(form[1]) == 'spatraster'){
  
    R <- terra::rast(names = nav$varname,
                     crs = nav$crs,
                     ext = terra::ext(nav$ext),
                     res = nav$res)
    terra::values(R) <- t(M)
    R <- terra::flip(R, "vertical")
  
  } else {
    
    R <- stars::st_as_stars(
        sf::st_bbox(c(xmin = nav$ext[1],
                      xmax = nav$ext[2],
                      ymin = nav$ext[3],
                      ymax = nav$ext[4]),
                    crs = sf::st_crs(nav$crs)),
        nx = nav$count[1],
        ny = nav$count[2],
        #dx = nav$res[1],
        #dy = nav$res[2],
        xlim = nav$ext[1:2],
        ylim = nav$ext[3:4],
        values = as.vector(M)) |>
      stars::st_flip("y")
    
  }
  names(R) <- "z"
  return(R)
}


