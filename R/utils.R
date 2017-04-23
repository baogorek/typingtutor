
count_words <- function(string) {
  nchar(string) / 5
}

get_gross_wpm <- function(string, time_in_sec) {
  60 * count_words(string) / time_in_sec
}

get_errors_per_min <- function(entered_string, true_string, time_in_sec) {
  60 * adist(entered_string, true_string)[1, 1] / time_in_sec
}


#get_net_wpm <- function(gross_wpm, errors_per_min) {
#  gross_wpm - errors_per_min
#}

get_net_wpm <- function(word_ct, errors_ct, time_in_sec) {
  60 * (word_ct - errors_ct) / time_in_sec
}

#' Get R file name and url from github
#'
#' @param repo Github repository address with format username/repo
#'
#' @return a list mapping R file names to github download urls
get_r_files_from_github <- function(repo = "hadley/dplyr") {
  r_dir_url <- paste0("https://api.github.com/repos/", repo, "/contents/R")
  response <- httr::GET(r_dir_url)
  r_files <- list() 
  for (item in httr::content(response)) {
    r_files[[item$name]] <- item$download_url
  } 
  r_files
}

display_files_for_selection <- function(r_files, max_char_per_line) {
  cat("--------------------------------------------\n")
  out_string <- ""
  n_chars <- 0
  for (i in 1:length(r_files)) {
    contrib_i <- paste0(i, ": ", names(r_files)[i], ", ")
    out_string <- paste(out_string, contrib_i)
    n_chars <- n_chars + nchar(contrib_i)
    if (n_chars > max_char_per_line) {
      out_string <- paste(out_string, "\n")
      n_chars <- 0
    }
  }
  cat(out_string, "\n")

  cat("--------------------------------------------\n")
  cat("Which R file would you like to practice on?\n")
  cat("Press <Enter> for random selection\n") 
  cat("Selection:")
}

get_user_choice <- function(r_files, max_char_per_line = 30) {

  display_files_for_selection(r_files, max_char_per_line)
  choice <- as.integer(readline())
  if (choice %in% 1:length(r_files)) {
    cat("\nUser selected", names(r_files)[choice], "\n\n")
  }
  else {
    choice <- sample(1:length(r_files), size = 1)
    cat("\nRandomly selected", names(r_files)[choice], "\n\n")
  }
  choice
}

extract_roxygen_comments <- function(string_contents) {
  contents[grepl("^#'.*", string_contents)]
}

# TODO: create chunks of expressions that don't take too long to type
type_contents <- function(r_files, choice) {
  
  expressions <- parse(r_files[[choice]])
  deparsed_exprs <- lapply(expressions, deparse)

  results_df <- data.frame()
  for (j in 1:length(expressions)) {
    expression_name <- deparse(expressions[[j]][[2]])
    cat("\n On expression", j, "of", length(expressions), ":",
        expression_name, "\n\n")
    contents <- deparsed_exprs[[j]]
    n_lines <- length(contents)
 
    expr_df <- data.frame(expression = rep(expression_name, n_lines),
                          time_in_sec = numeric(n_lines),
                          errors_ct = numeric(n_lines),
                          word_ct = numeric(n_lines),
                          net_wpm = numeric(n_lines))

    for(i in 1:n_lines) {
      line <- contents[i]

      t0 <- proc.time()
      cat(paste0(line,"\n"))
      input <- trimws(readline())
      delta <- proc.time() - t0

      expr_df[i, "time_in_sec"] <- delta["elapsed"]
      expr_df[i, "errors_ct"] <- adist(trimws(line), input)[1, 1]
      expr_df[i, "word_ct"] <- count_words(line)
      expr_df[i, "net_wpm"] <- with(expr_df[i, ],
                                    get_net_wpm(word_ct, errors_ct,
                                                time_in_sec))
    cat("\nNet WPM for last line:", round(expr_df[i, "net_wpm"]), "\n\n")
    }
    results_df <- rbind(results_df, expr_df)
  }
  results_df
}

evaluate_results <- function(results_df) {
  results_df <- results_df[results_df$word_ct > 0, ]
 
  overall_net_wpm <- with(results_df,
                          get_net_wpm(sum(word_ct), sum(errors_ct),
                                      sum(time_in_sec)))
  return(overall_net_wpm)
}

get_storage_location <- function() {
  storage_location <- ""
  if(".typing_storage" %in% names(.GlobalEnv)) {
    if(!file.exists(.typing_storage)) {
      warning(paste(".typing_storage contains invalid file path. Progress",
                    "will not be saved!"))
    } else {
      cat("Storing typing results in", .typing_storage, "\n")
      cat("based on .typing_storage variable\n")
      storage_location <- .typing_storage
    }
  } else {
    cat("\nWhere would you like to store your results?\n")
    cat("local file path (press <Enter> to bypass saving):")
    valid_path_entered <- FALSE
    while (!valid_path_entered) {
      storage_location <- gsub("\"|'", '', readline())
      if (storage_location == "") {
        cat("\nProgress will not be saved\n")
        valid_path_entered <- TRUE
      } else if (file.exists(storage_location)) {
        cat("Storing typing results in", storage_location, "\n")
        valid_path_entered <- TRUE
      }
      else {
        cat(storage_location, "is not a valid file path. Please try again: ")
      }
    }
    cat("\nTo avoid this message in the future, set .typing_storage to a valid")
    cat("file path in your .Rprofile\n")
    Sys.sleep(3)
  }
  return(storage_location)
}

get_history_from_storage <- function(storage_loc) {
  storage_file <- file.path(storage_loc, "typing_history.csv")
  if(file.exists(storage_file)) {
    history_df <- read.csv(storage_file)
    cat("getting history from storage\n")
  } else {
    history_df <- data.frame()
    cat("creating new history dataset\n")
  }
  history_df
}

get_history <- function(storage_loc) {
  if ("history_df" %in% names(.GlobalEnv)) {
    history <- history_df
    cat("\nUsing typing history from active session\n")
  } else {
    history <- get_history_from_storage(storage_loc)
  }
  history
}

perform_countdown <- function(start_pos = 3, pause = 1) {
  cat("Ready?\n")
  for (i in start_pos:1) {
    cat(i, "\n")
    Sys.sleep(pause)
  }
  cat("GO!\n")
}

#' Typing practice via R packages on Github
#' 
#' This function sends the user into an interactive loop that simulates
#' typing a part of an actual R package on github. The standard
#' words-per-minute calculations are presented to the user after each typed
#' line and following the typing round.
#'
#' @param repo Which repo do you want to practice typing on ("hadley/dplyr") is
#'             the default
#'
#' @examples
#' cat(crayon::yellow("I am not really an example.\n"))
#' cat(crayon::red("Does colored text show up in Travis CI?\n"))
#' cat(crayon::green("Hopefully it does\n"))
#'
#' @export
type_github <- function(repo = "hadley/dplyr") {
  storage_location <- get_storage_location()
  history_df <- get_history(storage_location)
  cat("\n...Getting R file information from Github\n")
  r_files <- get_r_files_from_github(repo)
  user_choice <- get_user_choice(r_files)
  perform_countdown(3, .7)
  results_df <- type_contents(r_files, user_choice)  
  net_wpm <- evaluate_results(results_df)
  cat("\n\nOverall Net WPM:", net_wpm, "\n")
  history_df <<- rbind(history_df,
                       data.frame(sys_time = as.numeric(Sys.time()),
                                  repo = repo,
                                  r_file = names(r_files)[user_choice],
                                  wpm = net_wpm))
}

