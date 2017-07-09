
#' Visit typingtutor's companion website
#'
#' Uses utils::browseURL to launch a browser with destination
#' \url{https://baogorek.github.io/typingtutor/site/signed-in.html}
#'
#' @export 
visit_site <- function() {
  browseURL("https://baogorek.github.io/typingtutor/site/signed-in.html")
}  

init <- function() {
  cat("In a browser, head to:\n\n",
      "https://baogorek.github.io/typingtutor/site/signed-in.html\n",
      "and report back with the copied 'authentication metadata' string!\n\n")
  refresh_token()
}

refresh_token <- function() {

  user_input <- readline("Paste 'authentication metadata' and press enter:")
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
  cat("\nSaving data to https://baogorek.github.io/typingtutor\n")

  write_url <- paste0("https://typingtutor-9f7e9.firebaseio.com/user_info/",
                      as.environment("firebase_env")$userid, ".json?auth=",
                      as.environment("firebase_env")$token)

  msec_since_1970 <- as.character(round(unclass(Sys.time()) * 1000))
  timestamp_posix <- paste0("p", msec_since_1970) 
  data_to_write <- list(this_timestamp = data_in_list)
  names(data_to_write) <- timestamp_posix

  write_response <- httr::PATCH(write_url, body = data_to_write,
                                encode = "json")

  if (write_response$status_code == 200) {
    cat("Progress successfully saved!\n\n")
  }
}

handle_get_content <- function(httr_response) {

  read_error_message <- ifelse("error" %in% names(httr_response),
                               httr_response$error, "")
  if (read_error_message == "Auth token is expired") {
    cat("Auth token is expired. Please enter token from refreshed page\n")
    init() 
  } else if (nchar(read_error_message) > 0) {
    stop(read_error_message)
  }

}
