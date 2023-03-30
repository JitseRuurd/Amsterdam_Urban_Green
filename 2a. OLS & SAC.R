easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "spdep")

#load data
funda_data <- st_read("data/funda_buy_28-03-2023_full_distances.gpkg")


funda_data <- funda_data %>% filter(price <1000000)


#plot dependent variable
mapview(funda_data, zcol = "price", col.regions=brewer.pal(20, "YlOrRd"))


tm_shape(funda_data) +
  tm_dots(c("price", "living_area")) + 
  tm_layout(legend.position = c("right", "top"), 
            legend.text.size = 0.5, legend.title.size = 0.8)













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
