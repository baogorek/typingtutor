
grab_web_contents <- function() {
  browseURL("https://baogorek.github.io/typingtutor/site/signed-in.html")
  user_input <- readline("Paste token from browser and press enter:")
  firebase_metadata <- jsonlite::fromJSON(user_input)
  

  # Example of querying data:
  data_url <- "https://typingtutor-9f7e9.firebaseio.com/with_chris.json"
                    "?auth=", firebase_metadata$token)

  read_request <- httr::GET(data_url,
                            query = list(auth = firebase_metadata$token))
  query_data <- httr::content(read_request)

  # Example of writing data
  write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info.json",
                    "?auth=", firebase_metadata$token)

  write_request <- httr::PUT(write_url,
                 body = list(d = list(inner_obj = list(four = "Jack", five = "Sparrow"))),
                 encode = "json",
                 verbose())

  content(write_request)

}


