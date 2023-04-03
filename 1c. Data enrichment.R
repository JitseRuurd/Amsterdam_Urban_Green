easypackages::packages("sf", "sp", "osmdata", "FNN", "tidyverse")

#read_sf("data/Noord_holland_polygon.shp") %>%
# st_transform(crs=4326) %>%
#st_write("Noord_Holland.gpkg", )

# POIs: school, university, hospital/clinic, shopping center/mall, train, subway, bus, supermarket/market

############################################################ NOORD-HOLLAND #######################################################
############################################################ DATA ##########################################################
province_boundaries <- st_read ("data/Noord_Holland.gpkg")
funda_data <- st_read ("data/funda_buy_28-03-2023_full.gpkg")
train <- st_transform(st_read("data/Amsterdam/Stations_(NS).geojson"), crs= 28992)
############################################################ OSM ###########################################################
bus <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "amenity", c("bus_station")) %>%
  osmdata_sf ()
bus_points <- st_as_sf (bus$osm_points) %>% dplyr:: select(osm_id, amenity)


subway <-  opq(st_bbox(province_boundaries)) %>%
  add_osm_feature(key = "railway", c("subway_entrance")) %>%
  osmdata_sf ()
subway_points <- st_as_sf (subway$osm_points) %>% dplyr:: select(osm_id)

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
############################################################ DISTANCES #####################################################
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
  mutate(train_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(train$geometry), 1))

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

#write results to updated gpkg
st_write(funda_data, "data/funda_buy_28-03-2023_full_distances.gpkg")


############################################################ AMSTERDAM ###########################################################
############################################################ DATA ###########################################################
funda_data <- st_transform(st_read("data/funda_buy_amsterdam_31-03-2023_full.gpkg"), crs = 28992)
amsterdam_boundaries <- st_transform(st_read("data/Amsterdam/PC4.json"), crs= 28992)

public_transport <- st_transform(st_read("data/Amsterdam/public_transport.json"), crs= 28992)
tram <- public_transport %>% 
  filter(Modaliteit == "Tram")
metro <- public_transport %>% 
  filter(Modaliteit == "Metro")
train <- st_transform(st_read("data/Amsterdam/Stations_(NS).geojson"), crs= 28992)
############################################################ DISTANCES ######################################################
nn_function <- function(measureFrom,measureTo,k) {
  measureFrom_Matrix <- as.matrix(measureFrom)
  measureTo_Matrix <- as.matrix(measureTo)
  nn <-   
    get.knnx(measureTo, measureFrom, k)$nn.dist [,k]
  return(nn)
}

funda_data <- funda_data %>%
  mutate(tram_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(tram$geometry), 1))

funda_data <- funda_data %>%
  mutate(metro_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(metro$geometry), 1))

funda_data <- funda_data %>%
  mutate(metro_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(metro$geometry), 1))

funda_data <- funda_data %>%
  mutate(train_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(train$geometry), 1))

############################################################ NDVI ######################################################

raster <- 


terra::extract(raster, points)




#write results to updated gpkg
st_write(funda_data, "data/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")











############################################################ Network ######################################################

easypackages::packages("sfnetworks", "tidygraph")

amsterdam_network <- as_sfnetwork(st_transform(st_read("data/Amsterdam/streets.json"), crs= 28992))
plot(amsterdam_network)

facilities <- tram %>% st_geometry()
sites <- funda_data %>% st_geometry() 

net <- amsterdam_network %>%
  activate("edges") %>%
  mutate(weight = edge_length())

plot(net)

new_net = net %>%
  activate("nodes") %>%
  filter(group_components() == 1) %>%
  st_network_blend(c(sites, facilities))


plot(blended)

cost_matrix = st_network_cost(new_net, from = snapped_sites %>% st_geometry(), to = snapped_facilities %>% st_geometry(), weights = "weight")

facilities <- tram %>% st_geometry() 

closest = facilities[apply(cost_matrix, 1, function(x) which(x == min(x))[1])]


draw_lines = function(sources, targets) {
  lines = mapply(
    function(a, b) st_sfc(st_cast(c(a, b), "LINESTRING"), crs = st_crs(net)),
    sources,
    targets,
    SIMPLIFY = FALSE
  )
  do.call("c", lines)
}

connections = draw_lines(sites %>% st_geometry(), closest)

# Plot the results.
plot(new_net, col = "grey")
plot(connections, lwd = 2, add = TRUE)
plot(facilities, pch = 8, cex = 2, lwd = 2, add = TRUE)
plot(sites, pch = 20, cex = 2, add = TRUE)

