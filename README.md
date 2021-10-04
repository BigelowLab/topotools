topotools
================

Coding tools for working with local copies of [ETOPO
data](https://ngdc.noaa.gov/mgg/global/) and [GEBCO
data](https://www.gebco.net).

### ETOPO Citation

    Amante, C. and B.W. Eakins, 2009. ETOPO1 1 Arc-Minute Global Relief Model:
    Procedures, Data Sources and Analysis. NOAA Technical Memorandum NESDIS NGDC-24.
    National Geophysical Data Center, NOAA. doi:10.7289/V5C8276M [2018-11-01].

### GEBCO Citation

    GEBCO Compilation Group (2020) GEBCO 2020 Grid (doi:10.5285/c6612cbe-50b3-0cff-e053-6c86abc09f8f).

## Requirements

-   [terra](https://CRAN.R-project.org/package=terra)

-   [ncdf4](https://CRAN.R-project.org/package=ncdf4)

## Installation

    devtools::install_github("BigelowLab/topotools")

## Usage

``` r
library(terra)
library(topotools)
library(viridisLite)
```

### Paths

The root path to the topography data defaults to that which works for
our setup. You can easily override this - see the `read_gebco` and
`read_etopo` functions.

``` r
library("topotools")
dir(topo_path(), full.names = TRUE)
```

    ## [1] "/mnt/ecocast/coredata/bathy/ETOPO1" "/mnt/ecocast/coredata/bathy/gebco"

### Read in a region

While it is possible to read in the entire dataset for each source,
generally the practice is to read in a portion defined by a bounding box
specified in `[west, east, south, north]` order.

``` r
bb <- c( -72,  -63,   39,   46)

etopo <- read_etopo(bb = bb)
gebco <- read_gebco(bb = bb)

etopo
```

    ## class       : SpatRaster 
    ## dimensions  : 422, 543, 1  (nrow, ncol, nlyr)
    ## resolution  : 0.01666667, 0.01666667  (x, y)
    ## extent      : -72.025, -62.975, 38.975, 46.00833  (xmin, xmax, ymin, ymax)
    ## coord. ref. : +proj=longlat +datum=WGS84 +no_defs 
    ## source      : memory 
    ## name        :     z 
    ## min value   : -5128 
    ## max value   :  1667

``` r
gebco
```

    ## class       : SpatRaster 
    ## dimensions  : 1682, 2162, 1  (nrow, ncol, nlyr)
    ## resolution  : 0.004166667, 0.004166667  (x, y)
    ## extent      : -72.00417, -62.99583, 38.99583, 46.00417  (xmin, xmax, ymin, ymax)
    ## coord. ref. : +proj=longlat +datum=WGS84 +no_defs 
    ## source      : memory 
    ## name        : elevation 
    ## min value   :     -5040 
    ## max value   :      1861

Note that the GEBCO data provides approximately 4x the resolution of the
ETOPO1 data.

For display purposes, it is helpful to clip each raster into a small
range of values.

``` r
par(mfrow = c(1,2))
plot(etopo, 
     col = viridisLite::viridis(50), 
     main = "ETOPO1", 
     range = c(-400, 800), 
     legend = FALSE)
plot(gebco, 
     col = viridisLite::viridis(50), 
     main = "GEBCO", 
     range = c(-400, 800), 
     legend = FALSE)
```

![](README_files/figure-gfm/plot-1.png)<!-- -->

``` r
par(mfrow = c(1,1))
```

### Masking

The `mask_topo` function will work with either data set (well, any
`terra::SpatRaster` or `raster::RasterLayer` object.) Use that function
in conjuction with `terra::mask` to produce a masked raster.

``` r
par(mfrow = c(1,3))
masked_land <- terra::mask(etopo, topotools::mask_topo(etopo, where = "above"))
masked_sea <- terra::mask(etopo, topotools::mask_topo(etopo, where = "below"))
plot(etopo, 
     col = viridisLite::viridis(50), 
     main = "ETOPO1", 
     range = c(-400, 800), 
     legend = FALSE,
     axes = FALSE,
     mar = NA)
plot(masked_land, 
     col = viridisLite::viridis(50), 
     main = "Masked Land ETOPO1", 
     range = c(-400, 800), 
     legend = FALSE,
     axes = FALSE,
     mar = NA)
plot(masked_sea, 
     col = viridisLite::viridis(50), 
     main = "Masked Ocean ETOPO1", 
     range = c(-400, 800), 
     legend = FALSE,
     axes = FALSE,
     mar = NA)
```

![](README_files/figure-gfm/mask-1.png)<!-- -->

``` r
par(mfrow = c(1,1))
```
