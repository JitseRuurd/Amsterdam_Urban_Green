Explaining Noord-Holland house prices
================
Yúri Grings, Thomas Nibbering, Jitse Ruurd Nauta
2023-03-21

A Spatial Statistics and Spatial Machine Learning approach.

Included data of the research was scraped from Funda. Below map gives an
overview of the scope of the data.

## We used the Funda-Scraper package to scrape our data

The query we used for the Funda-Scraper with below query on 28-03-2023.

``` python
scraper = FundaScraper(area="provincie-noord-holland", want_to="buy", find_past=False, n_pages = 1000)
df = scraper.run()
```

Note that this is not the original Funda-Scraper code underneath. The
Function is adjusted to contain additional adress information, compared
to the origional function. Code is included in the Scraper.ipynb file to
copy the updated package into the site-packages directory of python.

## A pre-processing pipeline is used to enrich data

OSM was used to enrich the scraped data. We geocode adressess into
geometries objects for in order to make use of the geospatial models.
Additional spatial data includes:

*Distance to public transport (Bus, Subway, and Train) *Distance to
public services (Schools, Universities, Shopping centres)

## This enriched data is used to fit an OLS model

### OLS on scraped data

``` r
model <- lm(price~ room + bedroom + bathroom + living_area + house_age, data = funda_data)
```

### OLS on enriched data

``` r
model <- lm(price~ room + bedroom + bathroom + living_area + house_age + bus_dist +subway_dist + train_dist + university_dist + school_dist + mall_dist + supermarket_dist, data = funda_data)
```

### GWR model to adjust for spatial component in the data

To look at local spatial dependence, a GWR model was fit on the data.

``` python
#Run basic GWR in parallel mode

gwr_selector = Sel_BW(b_coords, b_y, b_X)
gwr_bw = gwr_selector.search(pool = pool)
print(gwr_bw)
gwr_results = GWR(b_coords, b_y, b_X, gwr_bw).fit(pool = pool)
```

### MGWR model to adjust for spatial component in the data

As it would be more realistic to have different band-widths for every
feature, MGWR was used

``` python
#run MGWR in parallel mode. Note: max_iter_multi needs to be specified

mgwr_selector = Sel_BW(b_coords, b_y, b_X, multi=True)
mgwr_bw = mgwr_selector.search(pool=pool, max_iter_multi=200, criterion = "AICc") 
print(mgwr_bw)
mgwr_results = MGWR(b_coords, b_y, b_X, selector=mgwr_selector).fit(pool=pool)
```
