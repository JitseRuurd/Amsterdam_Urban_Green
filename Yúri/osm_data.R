easypackages::packages("sf", "sp", "osmdata")

read_sf("C:/Users/ygrin/Documents/GitHub/Noord_Holland_house_prices/Yúri/data/Noord_holland_polygon.shp") %>%
  st_transform(crs=4326) %>%
  st_write("Noord_Holland.gpkg", )

province_boundaries <- st_read ("C:/Users/ygrin/Documents/GitHub/Noord_Holland_house_prices/Yúri/data/Noord_Holland.gpkg")

# Get OSM data
bus <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "amenity", c("bus_station")) %>%
  osmdata_sf ()
bus_points <- st_as_sf (bus$osm_points) %>% dplyr:: select(osm_id, amenity)


subway <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "railway", c("subway_entrance")) %>%
  osmdata_sf ()
subway_points <- st_as_sf (subway$osm_points) %>% dplyr:: select(osm_id)


train <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "building", c("train_station")) %>%
  osmdata_sf ()
train_points <- st_as_sf (train$osm_points) %>% dplyr:: select(osm_id, amenity)

############################################################ DISTANCES ###########################################################
#Re-project the point layer from WGS to local projection to have unit in meter
bikefac_points <-  st_transform (bikefac_points, 27700)

#Re-project the point layer from WGS to local projection to have unit in meter
shop_points <-  st_transform (Dailyshops_points, 27700)

#now we would write our own function to estimate distance using nearest neighbor algorithm
#This function take an origin point (from), and a destination point (to), and then use nn function of FNN package to estimate the distance to the nearest (k =1) neighborhood location
nn_function <- function(measureFrom,measureTo,k) {
  measureFrom_Matrix <- as.matrix(measureFrom)
  measureTo_Matrix <- as.matrix(measureTo)
  nn <-   
    get.knnx(measureTo, measureFrom, k)$nn.dist [,k]
  return(nn)
}

#now we will use the nn_function to measure the shortest distance from neighborhood centroid to  bike facilities (i.e., bikefac_points)
#distance to bike facilities (shops, repair, parking)
greendatacen <- greendatacen %>%
  mutate(bikefac_dist_new = nn_function(st_coordinates(greendatacen$geom), st_coordinates(bikefac_points$geom), 1))

#distance to shops
greendatacen <- greendatacen %>%
  mutate(Shop_dist_new = nn_function(st_coordinates(greendatacen$geom), st_coordinates(shop_points$geom), 1))

#you can see the data frame and there is new column at the end.
#view(greendatacen)

#this is how you can convert the raw OSM data into a spatial indicator