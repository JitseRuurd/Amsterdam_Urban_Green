easypackages::packages("sf", "sp", "osmdata", "FNN")
library(dplyr)

#read_sf("data/Noord_holland_polygon.shp") %>%
 # st_transform(crs=4326) %>%
  #st_write("Noord_Holland.gpkg", )

province_boundaries <- st_read ("data/Noord_Holland.gpkg")
funda_data <- st_read ("data/test_sample(100p).gpkg")

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
bus_points <-  st_transform (bus_points, 28992)
subway_points <-  st_transform (subway_points, 28992)
train_points <-  st_transform (train_points, 28992)

#This function take an origin point (from), and a destination point (to), and then use nn function of FNN package to estimate the distance to the nearest (k =1) neighborhood location
nn_function <- function(measureFrom,measureTo,k) {
  measureFrom_Matrix <- as.matrix(measureFrom)
  measureTo_Matrix <- as.matrix(measureTo)
  nn <-   
    get.knnx(measureTo, measureFrom, k)$nn.dist [,k]
  return(nn)
}

#distance to bus stop
funda_data <- funda_data %>%
  mutate(bus_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(bus_points$geom), 1))

#distance to subway entrance
funda_data <- funda_data %>%
  mutate(subway_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(subway_points$geom), 1))

#distance to train station
funda_data <- funda_data %>%
  mutate(train_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(train_points$geom), 1))

st_write(funda_data, "data/test_sample_distances(100p).gpkg")
