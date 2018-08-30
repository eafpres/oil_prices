#
  oil_prices <- function() {
    require(httr)
    require(pack)
    require(jsonlite)
#
# this function gets EIA oil price data 
#    
    EIA_key <- "your key from https://www.eia.gov/opendata/register.php"
    options(warn = -1)
    retry_threshold <- 2
    retry_timeout <- 5
#
# get EIA data for crude oil historical prices
#
# specific categories
#
    EIA_category_names <- c("Petroleum",
                            "Electricity",
                            "STEO")  
    EIA_sub_category_names <- c("Europe_Brent_crude_monthly_spot_price",
                                "US_Cushing_OK_WTI_daily_spot_price",
                                "US_commercial_electricity_sales")
    EIA_names <- c(EIA_category_names, EIA_sub_category_names)
    EIA_categories <- vector("list", length(EIA_names))
    names(EIA_categories) <- EIA_names
#
    EIA_categories$Petroleum <- "category_id=714755"
    EIA_categories$Electricity <- "category_id=0"
    EIA_categories$STEO <- "category_id=829714"
    EIA_categories$Europe_Brent_crude_monthly_spot_price <- "series_id=STEO.BREPUUS.M"
    EIA_categories$US_commercial_electricity_sales <- "category_id=1003"
    EIA_categories$US_Cushing_OK_WTI_daily_spot_price <- "series_id=PET.RWTC.D"
#
# build url for Cushing WTI
#
    EIA_url <- paste("http://api.eia.gov/series/?",
                     "api_key=",
                     EIA_key,
                     "&",
                     EIA_categories$US_Cushing_OK_WTI_daily_spot_price,
                     sep = "")
#  
# call the API
#
    raw_crude_pricing <- GET(EIA_url)
# 
    retry <- 0
    retry_time <- Sys.time()
#
# if the API returns an error, retry up to retry_threshold times 
# or up to retry_timeout seconds
#
    while (raw_crude_pricing[["status_code"]] != 200 & 
           retry < retry_threshold & 
           difftime(Sys.time(), retry_time) < retry_timeout) {
      retry <- retry + 1
    }    
#  
    raw_crude_pricing <- GET(EIA_url)
#
# if we still fail, then read historical data
#
    if (raw_crude_pricing[["status_code"]] != 200) {
#  
      crude_history <- read.csv("Cushing_OK_WTI_Spot_Price_FOB_Daily.csv", 
                                header = TRUE, 
                                stringsAsFactors = FALSE)
      crude_source_flag <- "API error, using stored data"
      crude_history[, "date"] <- as.Date(crude_history[, "date"],
                                         origin = "1899-12-30")
      crude_dates <- crude_history[, "date"]
      crude_pricing <- crude_history[, "price"]
      rm(crude_history)
    } else {
#  
      parsed_crude_pricing <- fromJSON(content(raw_crude_pricing, 
                                               as = "text",
                                               encoding = "latin1"), 
                                       simplifyVector = TRUE)
#  
      crude_pricing <- parsed_crude_pricing$series$data[[1]][, 2]
#
# note that the dates are in reverse order (newest first)
#
      crude_dates <- as.Date(parsed_crude_pricing$series$data[[1]][, 1],
                             format = "%Y%m%d")
      crude_pricing <- crude_pricing[order(crude_dates, decreasing = FALSE)]
      crude_dates <- crude_dates[order(crude_dates, decreasing = FALSE)]
      crude_source_flag <- "using live API data"
    }
#
    crude_dates <- as.numeric(crude_dates)
    crude_pricing <- as.numeric(crude_pricing)
    oil_series <- data.frame(date = crude_dates, price = crude_pricing)  
    oil_list <- list(oil_series = oil_series, crude_source_flag = crude_source_flag)
#
    options(warn = 0)
    return(oil_list)
  }