easypackages::packages("tidyverse", "sf", "mapview", "RColorBrewer", "tmap", "spdep")

#Visualize results GWR model
gwr_result<- st_read("data/models/gwr_results_amsterdam_ndvi300_m2.gpkg")
PC4 <- st_transform(st_read("data/Amsterdam/PC4.json"), crs = 28992)

#plot variables of interest
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


#################### create coef plot for ndvi

tm_shape(PC4, bbox = bbox_new)+
  tm_polygons(col = "white", alpha = 0, border.col = "Black")+
  tm_shape(gwr_result %>%  filter(ndvi300_TV < -1.96| ndvi300_TV > 1.96))+
  tm_dots(c("ndvi300"), title = "Coefficient", size = 0.1) + 
  tm_layout(title = "Significant (95%) NDVI coefficients GWR model",
            title.fontfamily = "Cambria",
            title.fontface = "bold",
            legend.text.fontfamily = "cambria",
            legend.title.fontfamily = "cambria",
            legend.position = c("right", "top"),
            legend.text.size = 0.75,
            legend.title.size = 1)

################## create coef plot for ndvi for paper
paper_plot <- tm_shape(PC4) + 
  tm_polygons(col = 'lightgrey') + 
  tm_shape(gwr_result %>% filter(ndvi300_TV < -1.96 | ndvi300_TV > 1.96)) + 
  tm_dots(col = 'ndvi300', 
          size = 0.2,
          midpoint = 0, 
          title = "Residential Property Premiums (in euros)",
          palette = 'Spectral',
          shape = 21) + 
  tm_layout(title.position = c('center', 'top'),
            title.fontface = 'bold',
            title.fontfamily = 'Times',
            legend.title.fontface = 'bold',
            legend.title.fontfamily = 'Times',
            legend.text.fontfamily = 'Times',
            legend.position = c(0.03, -0.01),
            legend.text.size = 0.5,
            legend.title.size = 0.9,
            frame = F)

paper_plot

# Save
tmap_save(paper_plot, 'Economic_Value_Urban_Green.png', width = 5, height = 3.5)

