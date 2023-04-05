easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "spdep")




#Visualize results GWR model
gwr_result<- st_read("data/models/gwr_results_amsterdam_ndvi300_m2.gpkg")
funda_data <- st_read("data/Houseprices/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")

mean(funda_data$shops_dist)
sd(funda_data$shops_dist)


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
  filter(ndvi300_TV < -1.96| ndvi300_TV > 1.96) %>% 
  mapview( zcol = "ndvi300", col.regions=brewer.pal(9, "YlOrRd"))


gwr_result %>% 
  filter(school_dist_TV < -1.96| school_dist_TV > 1.96) %>% 
  mapview( zcol = "school_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(shops_dist_TV < -1.96| shops_dist_TV > 1.96) %>% 
  mapview( zcol = "shops_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(centre_dist_TV < -1.96| centre_dist_TV > 1.96) %>% 
  mapview( zcol = "centre_dist", col.regions=brewer.pal(9, "YlOrRd"))

gwr_result %>% 
  filter(zuid_dist_TV < -1.96| zuid_dist_TV > 1.96) %>% 
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


#################### create BW selection plot


bw_df <- read.csv("data/models/bw_selection.csv")

bw_df %>% 
  ggplot(aes(x = bw, y = AIC)) + geom_line() +
  theme_minimal()+
  labs(title = "GWR bandwith optimization with AIC scores",
       x = "Bandwidth",
       y = "AIC scores")

#################### create coef plot for ndvi


tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white", alpha = 0)+
  tm_shape(gwr_result %>%  filter(ndvi300_TV < -1.96| ndvi300_TV > 1.96))+
  tm_dots(c("ndvi300"), title = "Price (m2)", size = 0.1) + 
  tm_layout(title = "Amsterdam house prices",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)


