###Important to specify correct names for the original data and the desination data

#specify paths
origin_path <- "Scraper/data/"
desination_path <-  "data/"

#below names need to be specified

orgin_df_name <- "SPECIFY_THIS.csv"
desination_df_name <- "SPECIFY_THIS.csv"
desination_gpkg_name <- "SPECIFY_THIS.gkpg"

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


