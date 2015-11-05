## ----echo=FALSE, message=FALSE-------------------------------------------
library(knitr)
purl("index.Rmd")

## ----eval = FALSE--------------------------------------------------------
## #if not already installed
## install.packages(c("sp","raster","rgdal","rgeos"))

## ------------------------------------------------------------------------
library("sp")
library("raster")
library("rgdal")
library("rgeos")

## ------------------------------------------------------------------------
#Get the Town Boundaries
towns_url <- "http://maps.vcgi.org/gisdata/vcgi/packaged_zips/BoundaryTown_TWNBNDS.zip"
download.file(towns_url,"vt_towns.zip")
unzip("vt_towns.zip")

#Get Landcover
lc_url <-"http://maps.vcgi.org/gisdata/vcgi/packaged_zips/LandLandcov_LCLU.zip"
download.file(lc_url,"vt_lulc.zip")
unzip("vt_lulc.zip")

## ------------------------------------------------------------------------
#Read in the vector town boundary
vt_towns <- readOGR(".","Boundary_TWNBNDS_poly")

## ------------------------------------------------------------------------
#Read in the raster landcover
vt_lulc <- raster("lclu/lclu/")

## ---- echo = FALSE-------------------------------------------------------
proj4string(vt_lulc)<-proj4string(vt_towns)

## ------------------------------------------------------------------------
#List the objects in memory
ls()

#Let's look at the towns
#Default view (from the raster package, actually)
vt_towns
#Summary
summary(vt_towns)
#Look at the attributes on the towns
head(vt_towns)
#Or the whole thing
vt_towns@data

#Now for the raster
vt_lulc
#Value attribute table
print(vt_lulc)


## ---- echo = FALSE, messages = FALSE-------------------------------------
png("map1.png")
#Plot landcover first
plot(vt_lulc)
#Now add the towns
plot(vt_towns, add = TRUE)
dev.off()

## ---- eval = FALSE-------------------------------------------------------
## #Plot landcover first
## plot(vt_lulc)
## #Now add the towns
## plot(vt_towns, add = TRUE)

## ---- eval=FALSE---------------------------------------------------------
## #Get the package
## install.packages("quickmapr")
## library("quickmapr")

## ---- echo=FALSE,message=FALSE-------------------------------------------
#Get the package
if(!require(quickmapr)){
  install.packages("quickmapr", repo = "https://cran.rstudio.com")
}
library("quickmapr")

## ---- echo = FALSE, messages = FALSE-------------------------------------
png("map2.png")
map <- qmap(vt_lulc,vt_towns)
dev.off()

## ---- eval = FALSE-------------------------------------------------------
## map <- qmap(vt_lulc,vt_towns)

## ---- eval=FALSE---------------------------------------------------------
## #Get the package
## install.packages("leaflet")
## library("leaflet")

## ---- echo=FALSE,message=FALSE-------------------------------------------
#Get the package
if(!require(leaflet)){
  install.packages("leaflet", repo = "https://cran.rstudio.com")
}
library("leaflet")

## ------------------------------------------------------------------------
proj4 <- CRS("+proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0")
vt_towns_geo <- spTransform(vt_towns,proj4)

## ------------------------------------------------------------------------
map <- leaflet()
map <- addTiles(map)
map <- addPolygons(map,data=vt_towns_geo)
#Not Run: Takes a while.  Does projection behind the scenes.
#map <- addRasterImage(map, data = vt_lulc)
map

## ------------------------------------------------------------------------
#Use base R indexing to grab this
burlington_bnd <- vt_towns[vt_towns[["TOWNNAME"]] == "BURLINGTON",]
burlington_bnd
#And plot it, with a basemap in quickmapr
burl <- qmap(vt_towns, burlington_bnd, basemap = "1m_aerial", 
             resolution = 600)

## ------------------------------------------------------------------------
#First we crop the data: which uses the extent
burlington_lulc <- crop(vt_lulc,burlington_bnd)
#Next we mask which removes lulc outside of town boundary
burlington_lulc <- mask(burlington_lulc,burlington_bnd)
#And look at the result 
burl <- qmap(burlington_lulc,burlington_bnd,
             colors = "black")

## ------------------------------------------------------------------------
values <- getValues(burlington_lulc)
values <- data.frame(table(values))
values$Perc <- round(100 * (values$Freq/sum(values$Freq)),1)

## ------------------------------------------------------------------------
#Get Codes from VCGI
download.file("http://maps.vcgi.org/gisdata/vcgi/products/products_vcgi/lucodes.zip","vt_lucodes.zip")
unzip("vt_lucodes.zip")
#It's a dbf so we can deal with that in foreign package
library(foreign)
codes <- read.dbf("lucodes/lucodes.dbf")
values <- merge(values,codes,by.x="values",by.y="CODE")
kable(values[,3:4])

