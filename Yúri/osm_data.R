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

