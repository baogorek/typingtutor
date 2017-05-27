
init <- function() {
  browseURL("https://baogorek.github.io/typingtutor/site/signed-in.html")
  refresh_token()
}

refresh_token <- function() {

  user_input <- readline("Paste token from browser and press enter:")
  firebase_metadata <- jsonlite::fromJSON(user_input)

  while ("firebase_env" %in% search()) {  
    detach(firebase_env)
  }

  firebase_env <- new.env()

  firebase_env$token <- firebase_metadata$token 
  firebase_env$userid <- firebase_metadata$userid

  attach(firebase_env)
}

write_data_to_firebase <- function(data_in_list) {

  ensure_user_exists_in_db(as.environment("firebase_env")$userid,
                           as.environment("firebase_env")$token)

  write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info/",
                      as.environment("firebase_env")$userid, ".json?auth=",
                      as.environment("firebase_env")$token)

  msec_since_1970 <- as.character(round(unclass(Sys.time()) * 1000))
  timestamp_posix <- paste0("p", msec_since_1970) 
  data_to_write <- list(this_timestamp = data_in_list)
  names(data_to_write) <- timestamp_posix

  write_response <- httr::PATCH(write_url, body = data_to_write,
                                encode = "json")

  handle_response(write_response) 

}

handle_response <- function(httr_response) {

  read_error_message <- ifelse("error" %in% names(httr_response),
                               query_data$error, "")
  if (read_error_message == "Auth token is expired") {
    cat("Auth token is expired. Please enter token from refreshed page\n")
    init() 
  } else if (nchar(read_error_message) > 0) {
    stop(read_error_message)
  }
}

ensure_user_exists_in_db <- function(userid, token) {
  data_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info/",
                     userid, ".json?auth=", token)

  read_request <- httr::GET(data_url, query = list(auth = token))
  query_data <- httr::content(read_request)
  handle_response(query_data)

  if (is.null(query_data)) {
  
    write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info",
                        ".json", "?auth=", token)
    data_to_write <- list(userid = "placeholder")
    names(data_to_write) <- userid

    write_response <- httr::PUT(write_url,
                                body = data_to_write,
                                encode = "json")
    print(write_response)
  }
}
