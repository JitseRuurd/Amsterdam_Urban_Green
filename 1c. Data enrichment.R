easypackages::packages("sf", "sp", "osmdata", "FNN", "tidyverse", "stars", "mapview")

############################################################ AMSTERDAM ###########################################################
############################################################ DATA ###########################################################
funda_data <- st_transform(st_read("data/Houseprices/funda_buy_amsterdam_31-03-2023_full.gpkg"), crs = 28992)
amsterdam_boundaries <- st_read("data/Amsterdam/PC4.json")
public_transport <- st_transform(st_read("data/Amsterdam/public_transport.json"), crs= 28992)
tram <- public_transport %>% 
  filter(Modaliteit == "Tram")
metro <- public_transport %>% 
  filter(Modaliteit == "Metro")
train <- st_transform(st_read("data/Amsterdam/Stations_(NS).geojson"), crs= 28992)
############################################################ OSM ###########################################################
school <-  opq(st_bbox(amsterdam_boundaries)) %>%
  add_osm_feature(key = "amenity", c("school")) %>%
  osmdata_sf ()
school_points <- st_as_sf (school$osm_points) %>% dplyr:: select(osm_id, amenity)

daily_shops <-  opq(st_bbox(amsterdam_boundaries)) %>%
  add_osm_feature(key = "shop", c("convenience", "department_store", "supermarket")) %>%
  osmdata_sf ()
daily_shops_points <- st_as_sf (daily_shops$osm_points) %>% dplyr:: select(osm_id, amenity)
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

#Re-project the point layer from WGS to local projection to have unit in meter
school_points <-  st_transform (school_points, 28992)
daily_shops_points <-  st_transform (daily_shops_points, 28992)

funda_data <- funda_data %>%
  mutate(school_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(school_points$geometry), 1))

funda_data <- funda_data %>%
  mutate(shops_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(daily_shops_points$geometry), 1))

#Distance to city centre and Amsterdam Zuid (Centre of Business)
dam_centre_coords <- st_point(x = c(121391.4, 487329.7), dim="XY")
zuid_coords <- st_point(x = c(119988, 483393), dim="XY")

funda_data <- funda_data %>%
  mutate(centre_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(dam_centre_coords), 1))

funda_data <- funda_data %>%
  mutate(zuid_dist = nn_function(st_coordinates(funda_data$geom), st_coordinates(zuid_coords), 1))
############################################################ NDVI ######################################################
raster100 <- read_stars("data/Greenness/NDVI_Amsterdam_100m.tif")
raster300 <- read_stars("data/Greenness/NDVI_Amsterdam_300m.tif")
raster500 <- read_stars("data/Greenness/NDVI_Amsterdam_500m.tif")

ndvi100 <- st_extract(raster100, funda_data)
ndvi300 <- st_extract(raster300, funda_data)
ndvi500 <- st_extract(raster500, funda_data)

funda_data$ndvi100 <- ndvi100$NDVI_Amsterdam_100m.tif
funda_data$ndvi300 <- ndvi300$NDVI_Amsterdam_300m.tif
funda_data$ndvi500 <- ndvi500$NDVI_Amsterdam_500m.tif

#write results to updated gpkg

st_write(funda_data, "data/Houseprices/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")
