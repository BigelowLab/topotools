#' Retrieves the extent of an object's bonding box
#' 
#' @export
#' @param x numeric, SpatVector, SpatRaster, sf or stars object
#' @return numeric vector of bounding box in [xmin, xmax, ymin, ymax] order
as_bb <- function(x){
  
  if (any(inherits(x, c("sf", "stars")))){
    x <- (sf::st_bbox(x) |> as.vector())[c(1,3,2,4)]
  } else if (any(inherits(x, c("SpatVector", "SpatRaster")))){
    x <- terra::ext(x) |> unname()
  }
  x
}
