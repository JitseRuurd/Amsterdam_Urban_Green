easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap")


#Visualize results GWR model
gwr_result<- st_read("data/models/mgwr_results_amsterdam_ndvi.gpkg")

gwr_result %>% 
  filter(tram_dist_TV < -1.96| tram_dist_TV > 1.96) %>% 
  mapview( zcol = "tram_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(train_dist_TV < -1.96| train_dist_TV > 1.96) %>% 
  mapview( zcol = "train_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(metro_dist_TV < -1.96| metro_dist_TV > 1.96) %>% 
  mapview( zcol = "metro_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(living_area_TV < -1.96| living_area_TV > 1.96) %>% 
  mapview( zcol = "living_area", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(ndvi100_TV < -1.96| ndvi100_TV > 1.96) %>% 
  mapview( zcol = "ndvi100", col.regions=brewer.pal(9, "YlOrRd"))




map <- mapview(gwr_result, zcol = "metro", col.regions=brewer.pal(9, "YlOrRd"))

map

gwr_result %>% 
  ggplot(aes(x = residual)) + geom_density()

funda_data <- st_read("data/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")
PC4 <- st_transform(st_read("data/Amsterdam/PC4.json"), crs = 28992)

tm_shape(PC4)+
  tm_polygons()+
  tm_shape(gwr_result)+
  tm_dots(c("train_dist")) + 
  tm_layout(legend.position = c("right", "top"), 
            legend.text.size = 0.5, legend.title.size = 0.8)
