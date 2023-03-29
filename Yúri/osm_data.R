easypackages::packages("sf", "sp", "osmdata", "FNN")
library(dplyr)

#read_sf("data/Noord_holland_polygon.shp") %>%
 # st_transform(crs=4326) %>%
  #st_write("Noord_Holland.gpkg", )

# POIs: school, university, hospital/clinic, shopping center/mall, train, subway, bus, supermarket/market

province_boundaries <- st_read ("data/Noord_Holland.gpkg")
funda_data <- st_read ("data/funda_buy_28-03-2023_full.gpkg")

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

university <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "amenity", c("university")) %>%
  osmdata_sf ()
university_points <- st_as_sf (university$osm_points) %>% dplyr:: select(osm_id, amenity)

school <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "amenity", c("school")) %>%
  osmdata_sf ()
school_points <- st_as_sf (school$osm_points) %>% dplyr:: select(osm_id, amenity)

hospital <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "amenity", c("hospital")) %>%
  osmdata_sf ()
hospital_points <- st_as_sf (hospital$osm_points) %>% dplyr:: select(osm_id, amenity)

mall <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "shop", c("mall")) %>%
  osmdata_sf ()
mall_points <- st_as_sf (mall$osm_points) %>% dplyr:: select(osm_id, amenity)

supermarket <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "shop", c("supermarket")) %>%
  osmdata_sf ()
supermarket_points <- st_as_sf (supermarket$osm_points) %>% dplyr:: select(osm_id, amenity)


############################################################ DISTANCES ###########################################################
#Re-project the point layer from WGS to local projection to have unit in meter
bus_points <-  st_transform (bus_points, 28992)
subway_points <-  st_transform (subway_points, 28992)
train_points <-  st_transform (train_points, 28992)
university_points <-  st_transform (university_points, 28992)
school_points <-  st_transform (school_points, 28992)
hospital_points <-  st_transform (hospital_points, 28992)
mall_points <-  st_transform (mall_points, 28992)
supermarket_points <-  st_transform (supermarket_points, 28992)

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

#distance to university
funda_data <- funda_data %>%
  mutate(university_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(university_points$geom), 1))

#distance to primary/middle/secondary school
funda_data <- funda_data %>%
  mutate(school_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(school_points$geom), 1))

#distance to hospital
funda_data <- funda_data %>%
  mutate(hospital_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(hospital_points$geom), 1))

#distance to mall
funda_data <- funda_data %>%
  mutate(mall_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(mall_points$geom), 1))

#distance to supermarket
funda_data <- funda_data %>%
  mutate(supermarket_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(supermarket_points$geom), 1))

st_write(funda_data, "data/funda_buy_28-03-2023_full_distances.gpkg")
