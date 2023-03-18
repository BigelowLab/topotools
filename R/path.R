#' Set the topotools data path
#'
#' @export
#' @param path the path that defines the location of topotools data
#' @param filename the name the file to store the path as a single line of text
#' @return NULL invisibly
set_root_path <- function(path = "/mnt/s1/projects/ecocast/coredata/bathy",
                          filename = "~/.topodata"){
  cat(path, sep = "\n", file = filename)
  invisible(NULL)
}

#' Get the topotools data path from a user specified file
#'
#' @export
#' @param filename the name the file to store the path as a single line of text
#' @return character data path
root_path <- function(filename = "~/.topodata"){
  readLines(filename)
}


#' Retrieve the topo path
#'
#' @export
#' @param ... file path segments to append to the root
#' @param root character, the root directory
#' @return file path specification (which may not exists)
topo_path <- function(..., root = root_path()){
  file.path(root[1], ...)
}