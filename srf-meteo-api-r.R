library(httr)
library(jsonlite)
library(tidyverse)

# Define your client credentials
consumer_key <- "your_consumer_key"
consumer_secret <- "your_consumer_secret"

# Separate the credential using an ':' and Base64 encode them
credentials <- paste(consumer_key, consumer_secret, sep = ":")
encoded_credentials <- base64_enc(credentials)

# To access any further API calls we must first get an accesstoken:
# Define the URL from where we can POST our (secret) credentials:
url <- "https://api.srgssr.ch/oauth/v1/accesstoken?grant_type=client_credentials"

# Since we're sending data to the server, we need to construct a POST request (see ?POST for more information)
response <- POST(
  url,
  add_headers(
    Authorization = paste("Basic", encoded_credentials),
    `Cache-Control` = "no-cache",
    `Content-Length` = "0"
  )
)

# Get the authorization token from the API and save it in 'token_data'
if(http_status(response)$category == "Success"){
  token_data <- fromJSON(content(response, "text"))$access_token
} else {
  print("Erroneous data received.")
}

# -> From here you can do any of the documented API calls
#   ----

# -> Downloading geolocation names
#   Often we require the correct geolocation name(s) for the
#   locations of interest. They are constructed using the
#   lat and long rounded by 4 digits        

# Firstly, we construct an API call to get the correct 'geolocation_id'
# Define the API endpoint with the forecast point
url <- "https://api.srgssr.ch/srf-meteo/v2/geolocationNames"

# Define the query parameters (check the documentation for which information is
# required to be sent)
query_params <- list(zip = "8820")

# Define the headers for the GET function
headers <- add_headers(
  accept = "application/json",
  authorization = paste("Bearer", token_data) 
  # make sure that there's a blank space between Bearer and your token
)

# We're want to receive data from the server, thus we construct a GET request 
# from the query and the headers
response <- GET(url, query = query_params, headers)

# Check if the request was successful
if (http_status(response)$category == "Success") {
  # Parse the JSON response
  forecast_data <- fromJSON(content(response, "text"))
  geolocation_id <- forecast_data$geolocation$id
} else {
  # Print the error message and the response content for debugging
  print(paste("Error:", http_status(response)$message))
  print(content(response, "text"))
}

# print the geolocation id [lat,long]
print(geolocation_id)


# -> Downloading actual forecast data:
#   Since we now know the correct 'geolocation id', we can make another
#   API call to download the actual forecast data:

# Define the API endpoint with the forecast point
url <- "https://api.srgssr.ch/srf-meteo/v2/forecastpoint/"

# The geolocation id that we've found before
query_params <- list(id = geolocation_id)

# Make the GET request; headers stay the same as last time
response <- GET(url, query = query_params, headers)

# Check if the request was successful
if (http_status(response)$category == "Success") {
  # Parse the JSON response
  forecast_data <- fromJSON(content(response, "text"))
  print(forecast_data) # View the parsed response, it's a long output!
} else {
  # Print the error message and the response content for debugging
  print(paste("Error:", http_status(response)$message))
  print(content(response, "text"))
}
