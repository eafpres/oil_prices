This function uses the API available from the US Government website eia.gov to retrieve historical oil price data or other data.

The function is mainly self explanatory
To use the function, you need an API key which you can obtain from eia.gov.  The registration link is in the code.

There are several different data sets that can be obtained.  The function is configured to get US West Texas Intermediate crude oil pricing.  A feature is included that if the API call fails, data are loaded from a csv file.  At present, that is only configured for WTI crude.  However, the function includes definitions to get Europe Brent Crude pricing, as well as US Electricity Sales.
