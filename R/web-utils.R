
get_token <- function() {
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

do_things <- function() {

  token <- as.environment("firebase_env")$token
  userid <- as.environment("firebase_env")$userid
 
  ensure_user_exists_in_db(userid, token)

  write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info/",
                      userid, ".json?auth=", token)
  msec_since_1970 <- as.character(round(unclass(Sys.time()) * 1000))
  timestamp_posix <- paste0("p", msec_since_1970) 
  data_to_write <- list(this_timestamp = list(four = "Jack", five = "Sparrow"))
  names(data_to_write) <- timestamp_posix

  write_request <- httr::PUT(write_url,
                 body = data_to_write,
                 encode = "json")

  httr::content(write_request)

}

ensure_user_exists_in_db <- function(userid, token) {
  data_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info/",
                     userid, ".json?auth=", token)

  read_request <- httr::GET(data_url, query = list(auth = token))
  query_data <- httr::content(read_request)
  if (is.null(query_data)) {
  
    write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info2",
                        ".json", "?auth=", token)
    data_to_write <- list(userid = "placeholder")
    names(data_to_write) <- userid

    write_response <- httr::PUT(write_url,
                                body = data_to_write,
                                encode = "json")
  }
}
