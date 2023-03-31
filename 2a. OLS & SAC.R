easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "car", "spdep", "spatialreg", "leafsync")

#load data
funda_data <- st_read("data/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")
PC4 <- st_transform(st_read("data/Amsterdam/PC4.json"), crs = 28992)
#funda_data <- funda_data %>% filter(price <1000000)

#plot dependent variable
mapview(funda_data, zcol = "price", col.regions=brewer.pal(9, "YlOrRd"))

tm_shape(PC4)+
  tm_polygons()+
tm_shape(funda_data)+
  tm_dots(c("price"), style = "log10_pretty") + 
  tm_layout(legend.position = c("right", "top"), 
            legend.text.size = 0.5, legend.title.size = 0.8)

#test global spatial autocorrelation with Moran's I
funda_KNN <- knearneigh(funda_data, k=5) #Identify k nearest neighbours for spatial weights 
funda_nbq_KNN <- knn2nb(funda_KNN, sym=T) #Neighbours list from knn object
funda_KNN_w <- nb2listw(funda_nbq_KNN, style="W", zero.policy = TRUE)
mc_global_knn <- moran.mc(funda_data$price, funda_KNN_w, 2999, alternative="greater")
plot(mc_global_knn)
mc_global_knn
#there is significant spatial autocorrelation

equation <- price ~ room + bedroom + bathroom + living_area + house_age + tram_dist + metro_dist
#OLS
model <- lm(equation, 
            data = funda_data)
summary(model)
#check multicollinearity (VIF < 5)
vif(model)
#homoscedasticity test using plots 
par(mfrow=c(2,2))
plot(model)
#test spatial autocorrelation in residuals
mc_global_OLS <- moran.mc(model$residuals, funda_KNN_w, 2999, zero.policy= TRUE, alternative="greater")
#plot the  Moran's I
plot(mc_global_OLS)
mc_global_OLS

funda_data$res_lm <- model$residuals
#Now plot the residuals
mapview(funda_data, zcol = "res_lm", col.regions=brewer.pal(9, "YlOrRd"))

#SAC model
sac_model = sacsarlm(equation, data = funda_data, listw= funda_KNN_w, zero.policy = TRUE)
summary(sac_model, Nagelkerke=T)


#Visualize results GWR model
gwr_result<- st_read("data/gwr_results_amsterdam.gpkg")

gwr_result %>% 
  filter(living_area_TV < -1.96| living_area_TV > 1.96) %>% 
  mapview( zcol = "living_area", col.regions=brewer.pal(9, "YlOrRd"))
  

map <- mapview(gwr_result, zcol = "metro", col.regions=brewer.pal(9, "YlOrRd"))

map

gwr_result %>% 
  ggplot(aes(x = residual)) + geom_density()










########################################################### KNOEIEN ########################################################### 
#test local spatial autocorrelation with Moran's I
funda_price_LISA <- localmoran(funda_data$price, funda_KNN_w) 
# to visualize this statistic the relevant information needs to be extracted
# extract local Moran's I values and attach them to sf object 
funda_data$price_LISA <- funda_price_LISA[,1] 
# extract p-values
funda_data$price_LISA_p <- funda_price_LISA[,5] 

#Here we can map the local Moran's I with t-map, and show which areas have significant clusters
map_LISA <- tm_shape(funda_data) + 
  tm_dots(col= "price_LISA", title= "Local Moran's I", midpoint=0,
          palette = "RdYlBu", breaks= c(-10, -5, 0, 5, 10, 20)) 
map_LISA_p <- tm_shape(funda_data) + 
  tm_dots(col= "price_LISA_p", title= "p-values",
          breaks= c(0, 0.01, 0.05, 1), palette = "Reds") 
tmap_arrange(map_LISA, map_LISA_p)


### PC4 test

PC4 <- st_transform(st_read("data/Postcodevlakken_PC_4/PC4.shp"), crs= 28992)
Noord_Holland <- st_transform(st_read("data/Noord_Holland.gpkg"), crs= 28992)


NH_PC4 <- st_intersection(PC4, Noord_Holland)

mapview(NH_PC4, zcol = "PC4", col.regions=brewer.pal(9, "YlOrRd"))

Mode <- function(x) {
  ux <- unique(x) 
  ux[which.max(tabulate(match(x, ux)))]} 

funda_agg <- funda_data %>% 
  mutate(zip = as.character(zip)) %>% 
  group_by(zip) %>% 
  summarize(price = median(price),
            percent_house = sum(house_type=="huis")/n() * 100,
            building_type = Mode(building_type),
            room = median(room),
            bedroom = median(bedroom),
            bathroom = median(bathroom),
            energy_label = Mode(energy_label),
            living_area = median(living_area),
            house_area = median(house_age),
            has_garden = Mode(has_garden),
            has_balcony = Mode(has_balcony),
            house_age = median(house_age),
            bus_dist = median(bus_dist),
            subway_dist = median(subway_dist),
            train_dist = median(train_dist),
            university_dist = median(university_dist),
            school_dist = median(school_dist),
            mall_dist = median(mall_dist),
            supermarket_dist = median(supermarket_dist)) %>% 
  st_drop_geometry() %>%
  left_join(NH_PC4, by = c("zip"="PC4"))

funda_agg_st <- st_as_sf(funda_agg)

mapview(funda_agg_st, zcol = "price", col.regions=brewer.pal(9, "YlOrRd"))

coordsW <- funda_agg_st%>%
  st_centroid()%>%
  st_geometry()

greendata_KNN <- knearneigh(coordsW, k=5) #Identify nearest neighbours for spatial weights 

greendata_nbq_KNN <- knn2nb(greendata_KNN, sym=T) #Neighbours list from knn object
summary (greendata_nbq_KNN)
greendata_KNN_w <- nb2listw(greendata_nbq_KNN, style="W", zero.policy = TRUE)
mc_global <- moran.mc(funda_agg_st$price, greendata_KNN_w, 2999, alternative="greater") #here 2999 is the simulation number, if taking too long you can also use 999

#plot the  Moran's I
plot(mc_global)
mc_global

model <- lm(price~ room + bedroom + bathroom + living_area + house_age + bus_dist +subway_dist + train_dist + university_dist + school_dist + mall_dist + supermarket_dist, data = funda_agg )
summary(model)

sum(funda_data$house_type=="huis")
