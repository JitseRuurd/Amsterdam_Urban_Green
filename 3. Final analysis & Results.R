easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "spdep")


#Visualize results GWR model
gwr_result<- st_read("data/models/gwr_results_amsterdam_ndvi300_m2.gpkg")
funda_data <- st_read("data/Houseprices/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")

funda_data %>% 
  mapview( zcol = "ndvi300", col.regions=brewer.pal(9, "YlOrRd"))

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
  filter(ndvi300_TV < -1.91| ndvi300_TV > 1.91) %>% 
  mapview( zcol = "ndvi300", col.regions=brewer.pal(9, "YlOrRd"))


gwr_result %>% 
  filter(school_dist_TV < -1.91| school_dist_TV > 1.91) %>% 
  mapview( zcol = "school_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(shops_dist_TV < -1.91| shops_dist_TV > 1.91) %>% 
  mapview( zcol = "shops_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(centre_dist_TV < -1.91| centre_dist_TV > 1.91) %>% 
  mapview( zcol = "centre_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(zuid_dist_TV < -1.91| zuid_dist_TV > 1.91) %>% 
  mapview( zcol = "zuid_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  mapview( zcol = "residual", col.regions=brewer.pal(9, "YlOrRd"))


funda_KNN <- knearneigh(funda_data, k=50) #Identify k nearest neighbours for spatial weights 
funda_nbq_KNN <- knn2nb(funda_KNN, sym=T) #Neighbours list from knn object
funda_KNN_w <- nb2listw(funda_nbq_KNN, style="W", zero.policy = TRUE)

mc_gwr <- moran.mc(gwr_result$residual, funda_KNN_w, 2999, zero.policy= TRUE, alternative="greater")
mc_gwr
plot(mc_gwr)
funda_data %>% 
  ggplot(aes(y = price_m2, x = metro_dist)) + geom_point()

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
