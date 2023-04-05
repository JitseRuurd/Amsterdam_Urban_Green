easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "car", "spdep", "spatialreg", "leafsync", "systemfonts")

#load data
funda_data <- st_read("data/Houseprices/funda_buy_amsterdam_31-03-2023_full_distances.gpkg")
PC4 <- st_transform(st_read("data/Amsterdam/PC4.json"), crs = 28992)

#plot dependent variable
# Extend bbox for plots
bbox_new <- st_bbox(PC4) # current bounding box 
xrange <- bbox_new$xmax - bbox_new$xmin # range of x values 
yrange <- bbox_new$ymax - bbox_new$ymin # range of y values 
# bbox_new[1] <- bbox_new[1] - (0.25 * xrange) # xmin - left 
bbox_new[3] <- bbox_new[3] + (0.25 * xrange) # xmax - right 
# bbox_new[2] <- bbox_new[2] - (0.25 * yrange) # ymin - bottom 
bbox_new[4] <- bbox_new[4] + (0.25 * yrange) # ymax - top 
bbox_new <- bbox_new %>%
  st_as_sfc() 

library(stars)
ndvi <- read_stars("data/Greenness/NDVI_Amsterdam_100m.tif")


tm_shape(ndvi, bbox = bbox_new)+
  tm_raster() +
  tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white", alpha = 0)+
  tm_shape(funda_data)+
  tm_dots(c("price_m2"), title = "Price (m2)", breaks = c(0,1000,2500,5000,7500,10000,12500,15000,20000,30000), size = 0.1) + 
  tm_layout(title = "Amsterdam house prices",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)




tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white")+
tm_shape(funda_data)+
  tm_dots(c("price_m2"), title = "Price (m2)", breaks = c(0,2500,5000,7500,10000,12500,15000,20000,30000), size = 0.1) + 
  tm_layout(title = "Amsterdam house prices",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)

tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white")+
  tm_shape(funda_data)+
  tm_dots(c("ndvi300"), title = "NDVI (300m range)", size = 0.1) + 
  tm_layout(title = "Amsterdam NDVI values",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)

#test global spatial autocorrelation with Moran's I
funda_KNN <- knearneigh(funda_data, k=5) #Identify k nearest neighbours for spatial weights 
funda_nbq_KNN <- knn2nb(funda_KNN, sym=T) #Neighbours list from knn object
funda_KNN_w <- nb2listw(funda_nbq_KNN, style="W", zero.policy = TRUE)
mc_global_knn <- moran.mc(funda_data$price_m2, funda_KNN_w, 2999, alternative="greater")
plot(mc_global_knn, xlab = "Dependent variable (price per squared meter)")
mc_global_knn
#there is significant spatial autocorrelation

equation <- price_m2 ~ bedroom + bathroom + living_area + house_age + tram_dist + metro_dist + train_dist + ndvi300 + centre_dist + zuid_dist + shops_dist + school_dist

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
par(mfrow=c(1,1))
plot(mc_global_OLS, xlab = "Residuals of OLS model")
mc_global_OLS

#SAC model
sac_model = sacsarlm(equation, data = funda_data, listw= funda_KNN_w, zero.policy = TRUE)
summary(sac_model, Nagelkerke=T)
#check residual autocorrelation
mc2_global_sac <-moran.mc(sac_model$residuals, funda_KNN_w, 2999, alternative="greater")
plot(mc2_global_sac, xlab = "Residuals of SAC model")
mc2_global_sac
#No more spatial autocorrelation

#Plot residuals 
#add the residual to polygon and plot
funda_data$res_lm <- model$residuals
funda_data$res_sac <- residuals(sac_model)

tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white")+
  tm_shape(funda_data)+
  tm_dots(c("res_lm"), title = "Residual", size = 0.1) + 
  tm_layout(title = "Residuals OLS model",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)

tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white")+
  tm_shape(funda_data)+
  tm_dots(c("res_sac"), title = "Residual", size = 0.1) + 
  tm_layout(title = "Residuals SAC model",
            title.fontfamily = "cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)
