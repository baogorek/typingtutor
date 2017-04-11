
count_words <- function(string) {
  nchar(string) / 5
}

get_gross_wpm <- function(string, time_in_sec) {
  60 * count_words(string) / time_in_sec
}

get_errors_per_min <- function(entered_string, true_string, time_in_sec) {
  60 * adist(entered_string, true_string)[1, 1] / time_in_sec
}

get_net_wpm <- function(gross_wpm, errors_per_min) {
  gross_wpm - errors_per_min
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
    cat("User selected", names(r_files)[choice], "\n")
  }
  else {
    choice <- sample(1:length(r_files), size = 1)
    cat("Randomly selected", names(r_files)[choice], "\n")
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
    cat("On expression", j, ":", expression_name, "\n")
    contents <- deparsed_exprs[[j]]
    n_lines <- length(contents)
 
    expr_df <- data.frame(expression = rep(expression_name, n_lines),
                          time_to_type = numeric(n_lines),
                          dist_to_truth = numeric(n_lines),
                          word_ct = numeric(n_lines),
                          char_ct = numeric(n_lines))

    for(i in 1:n_lines) {
      line <- contents[i]

      cat("N words:", length(strsplit(line, " ")[[1]]), "\n")
      cat("N chars:", nchar(line), "\n")

      t0 <- proc.time()
      cat(paste0(line,"\n"))
      input <- trimws(readline())
      delta <- proc.time() - t0

      cat("\nTime elapsed:", delta["elapsed"], "\n")
      cat("\nstring distance", adist(trimws(line), input), "\n") 

      expr_df[i, "time_to_type"] <- delta["elapsed"]
      expr_df[i, "dist_to_truth"] <- adist(trimws(line), input)
      expr_df[i, "word_ct"] <- length(strsplit(line, " ")[[1]])
      expr_df[i, "char_ct"] <- nchar(line)
    }
    results_df <- rbind(results_df, expr_df)
  }
  results_df
}

# TODO: See these typing equations
# https://www.speedtypingonline.com/typing-equations 

evaluate_results <- function(results_df, error_penalty = 3) {
  results_df <- results_df[results_df$word_ct > 0, ]
  raw_words_per_minute <- 60 * sum(results_df$word_ct) / sum(results_df$time_to_type)
  adj_words_per_minute <- 60 * sum(results_df$word_ct) / (
    sum(results_df$time_to_type) + error_penalty * sum(results_df$dist_to_truth))
  return(c(raw_words_per_minute, adj_words_per_minute))
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
    cat("Where would you like to store your results?\n")
    cat("local file path (press <Enter> to bypass saving):")
    valid_path_entered <- FALSE
    while (!valid_path_entered) {
      storage_location <- gsub("\"|'", '', readline())
      if (storage_location == "") {
        cat("Progress will not be saved\n")
        valid_path_entered <- TRUE
      } else if (file.exists(storage_location)) {
        cat("Storing typing results in", storage_location, "\n")
        valid_path_entered <- TRUE
      }
      else {
        cat(storage_location, "is not a valid file path. Please try again: ")
      }
    }
    cat("To avoid this message in the future, set .typing_storage to a valid")
    cat("file path in your .Rprofile\n")
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
    cat("reusing typing history from current session\n")
  } else {
    history <- get_history_from_storage(storage_loc)
  }
  history
}

#' @export
type_github <- function(repo = "hadley/dplyr") {
  storage_location <- get_storage_location()
  history_df <- get_history(storage_location)
  r_files <- get_r_files_from_github(repo)
  user_choice <- get_user_choice(r_files)
  results_df <- type_contents(r_files, user_choice)  
  evaluation <- evaluate_results(results_df)
  history_df <<- rbind(history_df,
                       data.frame(sys_time = as.numeric(Sys.time()),
                                  repo = repo,
                                  r_file = names(r_files)[user_choice],
                                  wpm = evaluation[1]))
  print("Better evaluation metrics coming")
  print(history_df)
}

