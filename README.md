Explaining Amsterdam House Prices with Greenness
================
Yúri Grings, Thomas Nibbering, Jitse Ruurd Nauta

This study served as our term project performed at the end of the course
Spatial Statistics and Machine Learning.

Below a short overview of the structure of the GitHub page, methodology,
data sources, and code is provided.

Full paper can be found in the directory
[here](https://github.com/JitseRuurd/Amsterdam_Urban_Green/blob/main/Paper/Term-Project---Grings%2C-Nauta%2C-Nibbering.pdf)!

Kind regards,

Yúri Grings [Linkedin](https://www.linkedin.com/in/yurigrings/), Thomas
Nibbering [Linkedin](https://www.linkedin.com/in/thomas-nibbering/),
Jitse Ruurd Nauta
[Linkedin](https://www.linkedin.com/in/jitseruurdnauta/)

# Stucture of the directory

The way the data analysis was performed is described in the figure
below. Below headers provide some insight into the steps that were taken
during each phase.

![Overview of study area](Paper/figures/Methods.jpg)

## Data Extraction

The used data regarding the Public Amenities can be found in the
[/data/Amsterdam/
folder](https://github.com/JitseRuurd/Amsterdam_Urban_Green/tree/main/data/Amsterdam)
and partly in [the 1.c Data Enrichment
script](https://github.com/JitseRuurd/Amsterdam_Urban_Green/blob/main/1c.%20Data%20enrichment.R).

The House price data was extracted with the help of the Funda-Scraper
package. This code was however modified to be able to extract a more
precise adress line, which could be used for geocoding the adress to
spatial data.

The [Funda scraper
notebook](https://github.com/JitseRuurd/Amsterdam_Urban_Green/blob/main/Scraper/Scraper.ipynb)
provides code to copy the code of the enhanced funda scraper in the
site-packages or dist-packages directory of python:

``` python
#import function to copy the scraper folder into the dist-packages or site-packages libraries
from copy_scraper import copy_scraper
copy_scraper()
```

To extract the data for this project, below query was used:

``` python
####
# 2. Data
####
# Obtain Data
scraper = FundaScraper(area="amsterdam", want_to="buy", find_past=False, n_pages = 1000)
df = scraper.run()
```

Lastly, the Remote Sensing data was extracted with below code in the
[1.Pre-Processing
script](https://github.com/JitseRuurd/Amsterdam_Urban_Green/blob/main/1b.%20Pre-Processing.ipynb):

``` python
####
# 1. Obtain Data
####
# Define Catalog
catalog = pystac_client.Client.open("https://planetarycomputer.microsoft.com/api/stac/v1",modifier=planetary_computer.sign_inplace)

# Obtain Area of Interest
bbox_of_interest = [4.541943,52.193249,5.212109,52.532048] 
time_of_interest = "2022-06-01/2022-09-30" 

# Search Data
search = catalog.search(collections=["sentinel-2-l2a"],
                        bbox=bbox_of_interest,
                        datetime=time_of_interest,
                        query={"eo:cloud_cover": {"lt": 20}})

# Obtain Data
items = search.item_collection()

# Select Item from List
selected_item = items[4]

# Obtain Bands of Interest
data = odc.stac.stac_load([selected_item], bands = ['red', 'green', 'blue', 'nir'], bbox = bbox_of_interest).isel(time=0)
```

## Data Enhancement

To then use the data for the analysis, the [pre-processing R
script](https://github.com/JitseRuurd/Amsterdam_Urban_Green/blob/main/1a.%20Pre-processing.R)
provides the code to geocode the adresses from the Funda.nl data to
latlon column.

``` r
df_geo <- df %>%
    separate(address_line, c("zip", "letters", "city", "optional1",
        "optional2", "optional3", "optional4", "optional5"),
        " ") %>%
    mutate(addressline_city = paste(city, optional1, optional2,
        optional3, optional4, optional5), addressline_zip = paste(zip,
        letters), addresszip = paste0(address, ", ", addressline_zip,
        ", ", addressline_city)) %>%
    select(-optional1, -optional2, -optional3, -optional4, -optional5) %>%
    geocode(addresszip, method = "osm", lat = latitude, long = longitude)
```
