################################################################################
#Set up R to do GIS
################################################################################

#if not already installed
install.packages(c("sp","raster","rgdal","rgeos"))

#load the packages
library("sp")
library("raster")
library("rgdal")
library("rgeos")

################################################################################
#Get and read in data
################################################################################

#Get the Town Boundaries
towns_url <- "http://maps.vcgi.org/gisdata/vcgi/packaged_zips/BoundaryTown_TWNBNDS.zip"
download.file(towns_url,"vt_towns.zip")
unzip("vt_towns.zip")

#Get Landcover
lc_url <-"http://maps.vcgi.org/gisdata/vcgi/packaged_zips/LandLandcov_LCLU.zip"
download.file(lc_url,"vt_lulc.zip")
unzip("vt_lulc.zip")

#Read in the vector town boundary
vt_towns <- readOGR(".","Boundary_TWNBNDS_poly")

#Read in the raster landcover
vt_lulc <- raster("lclu/lclu/hdr.adf")

#Clean up some small diffs is p4
proj4string(vt_lulc)<-proj4string(vt_towns)

################################################################################
#Look at the new objects
################################################################################

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

################################################################################
#Create some maps
################################################################################

#Plot landcover first
plot(vt_lulc)
#Now add the towns
plot(vt_towns, add = TRUE)

#Get the package
install.packages("leaflet")
library("leaflet")

#Project for use with leaflet
proj4 <- CRS("+proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0")
vt_towns_geo <- spTransform(vt_towns,proj4)

#Create leaflet map
map <- leaflet()
map <- addTiles(map)
map <- addPolygons(map,data=vt_towns_geo)
#Raster Takes a while.  Does projection behind the scenes.
#Skip if you want to just see an example
map <- addRasterImage(map, data = vt_lulc)
map

################################################################################
#Do some analysis
################################################################################

#Use base R indexing to grab just Burlington boudnary
burlington_bnd <- vt_towns[vt_towns[["TOWNNAME"]] == "BURLINGTON",]
burlington_bnd
#And plot it, with all towns
plot(vt_towns)
plot(burlington_bnd, border="red", lwd = 3, add=T)

#First we crop the data: which uses the extent
burlington_lulc <- crop(vt_lulc,burlington_bnd)
#Next we mask which removes lulc outside of town boundary
burlington_lulc <- mask(burlington_lulc,burlington_bnd)
#And look at the result
plot(burlington_lulc)
plot(burlington_bnd, add = T, lwd = 3)

#Summarize lulc
values <- getValues(burlington_lulc)
values <- data.frame(table(values))
values$Perc <- round(100 * (values$Freq/sum(values$Freq)),1)

#Get lulc Codes from VCGI
download.file("http://maps.vcgi.org/gisdata/vcgi/products/products_vcgi/lucodes.zip","vt_lucodes.zip")
unzip("vt_lucodes.zip")
#It's a dbf so we can deal with that in foreign package
library(foreign)
codes <- read.dbf("lucodes/lucodes.dbf")
values <- merge(values,codes,by.x="values",by.y="CODE")
#Format output with markdown
kable(values[,3:4])

