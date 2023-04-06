###Important to specify correct names for the original data and the destination data

easypackages::packages("raster", "sf", "tidyverse", "tidygeocoder", "mapview")

#paths
origin_path <- "Scraper/data/"
destination_path <-  "data/Houseprices/"

#below names need to be specified
orgin_df_name <- "funda_buy_amsterdam_31-03-2023_full.csv"
destination_df_name <- "funda_buy_amsterdam_31-03-2023_fulllatlon.csv"
destination_gpkg_name <- "funda_buy_amsterdam_31-03-2023_full.gpkg"

#load raw scraped Funda data from the folder
df <- read.csv(paste0(origin_path, orgin_df_name))

#show and adjust structure
str(df)
df <-  df %>% 
  mutate(house_type = factor(house_type),
         building_type = factor(building_type),
         energy_label = factor(energy_label),
         has_balcony = factor(has_balcony),
         has_garden = factor(has_garden))
str(df)

#create correct address-line based on the funda data
#geocode the addres line with OSM to lat long columns
df_geo <- df %>% 
  separate(address_line, c("zip", "letters", "city", "optional1","optional2", "optional3", "optional4", "optional5"), " ") %>% 
  mutate(addressline_city = paste(city, optional1, optional2, optional3, optional4, optional5),
         addressline_zip = paste(zip, letters),
         addresszip = paste0(address, ", ",addressline_zip, ", ", addressline_city)) %>% 
  select(-optional1, -optional2, -optional3, -optional4, -optional5) %>% 
  geocode(addresszip, method = 'osm', lat = latitude , long = longitude)

#write to csv
write.csv(df_geo, paste0(destination_path, destination_df_name))

#NAs will be dropped and the data will be clipped to Amsterdam to delete any falsely geocoded locations.
df_geo_clean <- df_geo %>% drop_na() 

df_spatial = st_as_sf(df_geo_clean, coords = c( "longitude", "latitude"), crs = 4326)
#transform to RDNEW
df_spatial <- st_transform(df_spatial, crs = 28992)

#clip data basesd on Amsterdam PC4 boundaries
df_spatial_clipped <- st_intersection(df_spatial, st_transform(st_read("data/Amsterdam/PC4.json"), crs = 28992))

#view data
mapview(df_spatial_clipped)

#adjust for faulty house age values
df_spatial_clipped <- df_spatial_clipped %>% 
  mutate(house_age = ifelse(house_age == 2023, NA, house_age),
         house_age = ifelse(is.na(house_age), mean(house_age, na.rm = T), house_age))

#write to geopackage
st_write(df_spatial_clipped,paste0(destination_path, destination_gpkg_name))




