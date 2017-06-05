#' @importFrom utils adist read.csv

count_words <- function(string) {
  nchar(string) / 5
}

get_gross_wpm <- function(string, time_in_sec) {
  60 * count_words(string) / time_in_sec
}

get_errors_per_min <- function(entered_string, true_string, time_in_sec) {
  60 * adist(entered_string, true_string)[1, 1] / time_in_sec
}

get_net_wpm <- function(word_ct, errors_ct, time_in_sec) {
  60 * (word_ct - errors_ct) / time_in_sec
}

#' Get R file name and url from github
#'
#' @param repo Github repository address with format username/repo
#'
#' @return a list mapping R file names to github download urls
get_r_files_from_github <- function(repo = "tidyverse/dplyr") {
  r_dir_url <- paste0("https://api.github.com/repos/", repo, "/contents/R")
  response <- httr::GET(r_dir_url)
  r_files <- list() 
  for (item in httr::content(response)) {
    r_files[[item$name]] <- item$download_url
  } 
  r_files
}

get_version_from_github <- function(repo) {
  r_desc_url <- paste0("https://api.github.com/repos/", repo,
                       "/contents/DESCRIPTION")
  response <- httr::GET(r_desc_url)
  response2 <- httr::GET(httr::content(response)$download_url)
  desc_text <- httr::content(response2)
  version_info <- grep("Version:", strsplit(desc_text, "\n")[[1]],
                       ignore.case = TRUE, value = TRUE)
  return(version_info)
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
}

get_user_choice <- function(r_files, max_char_per_line = 30) {

  display_files_for_selection(r_files, max_char_per_line)
  choice <- as.integer(readline("Selection:"))
  if (choice %in% 1:length(r_files)) {
    cat("\nUser selected", names(r_files)[choice], "\n\n")
  }
  else {
    choice <- sample(1:length(r_files), size = 1)
    cat("\nRandomly selected", names(r_files)[choice], "\n\n")
  }
  choice
}

get_user_group_choice <- function(expr_groups) {
  cat("Which expression group would you like to type?\n")
  cat("----------------------------------------------\n")
  for (i in 1:length(expr_groups)) {
    cat(i, ":", names(expr_groups)[i], "\n")
  }
  choice <- as.integer(readline("Choice:"))
  if (choice %in% 1:length(expr_groups)) {
    cat("\nUser selected", names(expr_groups)[choice], "\n\n")
  }
  else {
    choice <- sample(1:length(expr_groups), size = 1)
    cat("\nRandomly selected", names(expr_groups)[choice], "\n\n")
  }
  choice
}

extract_roxygen_comments <- function(string_contents) {
  contents[grepl("^#'.*", string_contents)]
}

get_deparsed_object <- function(parsed_expression, max_chars = 750) {
  deparsed_exprs <- lapply(parsed_expression, deparse)

  object <- list()
  for (j in 1:length(deparsed_exprs)) {
    contents <- deparsed_exprs[[j]]
    n_char <- sum(nchar(contents))
    truncated <- FALSE
    if (n_char > max_chars) { 
      contents <- contents[cumsum(nchar(contents)) < max_chars]
      n_char <- sum(nchar(contents))
      truncated <- TRUE
    }
    object[[j]] <- list(name = deparse(parsed_expression[[j]][[2]]),
                        contents = contents,
                        n_lines = length(contents),
                        n_char = n_char,
                        truncated = truncated)
  }
  return(object)
} 

get_grouped_exprs <- function(expr_object, max_group_chars = 751) {
  expr_sizes <- sapply(expr_object, FUN = function(x) x$n_char)
  if (max(expr_sizes) > max_group_chars) {
    stop("The max allowed chars for group must exceed that of largest expr!")
  }
  object <- list()
  running_total <- 0
  running_name <- ""
  k <- 1
  i <- 1
  while_iter <- 0 # purely for debugging
  group <- list()
  while (i <= length(expr_object)) {
    while_iter <- while_iter + 1
    if (running_total + expr_object[[i]]$n_char <= max_group_chars) {
      running_total <- running_total + expr_object[[i]]$n_char
      running_name <- paste(running_name, expr_object[[i]]$name, sep = ";")
      group[[k]] <- expr_object[[i]]
      i <- i + 1 # increment input expression list index 
      k <- k + 1 # increment position in current group list
    } else {
      object[[length(object) + 1]] <- group
      names(object)[length(object)] <- substr(running_name, 2,
                                              nchar(running_name))
      k <- 1
      running_total <- 0
      running_name <- ""
      group <- list()
    }
    if (while_iter > 2000) {
      stop("This loop has been spinning for a while; something went wrong!")
    }
  }
  if (running_total > 0) {
     object[[length(object) + 1]] <- group
     names(object)[length(object)] <- substr(running_name, 2,
                                             nchar(running_name))
  }
  return(object)
}

#' Type contents of list of expressions
#'
#' @param expression_group list of expressions
type_contents <- function(expression_group) {
  
  results_df <- data.frame()
  for (j in 1:length(expression_group)) {
    current_expr <- expression_group[[j]]
    n_lines <- current_expr$n_lines
    cat("\n On expression", j, "of", length(expression_group), ":",
        current_expr$name, "\n\n")
 
    expr_df <- data.frame(expression  = rep(current_expr$name, n_lines),
                          time_in_sec = numeric(n_lines),
                          errors_ct   = numeric(n_lines),
                          word_ct     = numeric(n_lines),
                          net_wpm     = numeric(n_lines))

    for(i in 1:n_lines) {
      line <- trimws(current_expr$contents[i], "right") # rm trailing spaces
      n_leading_spaces <- nchar(line) - nchar(trimws(line, "left")) 
      space_buffer <- paste(rep(" ", n_leading_spaces), collapse = "")

      t0 <- proc.time()
      cat(crayon::green(line), "\n")
      input <- trimws(readline(space_buffer))
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

perform_countdown <- function(pause = 1) {
  cat("Ready?\n")
  cat(crayon::red("3"), "\n")
  Sys.sleep(pause)
  cat(crayon::yellow("2"), "\n")
  Sys.sleep(pause)
  cat(crayon::yellow("1"), "\n")
  Sys.sleep(pause)
  cat(crayon::green("GO!"), "\n")
  Sys.sleep(.5)
}

#' Typing practice via R packages on Github
#' 
#' This function sends the user into an interactive loop that simulates
#' typing a part of an actual R package on github. The standard
#' words-per-minute calculations are presented to the user after each typed
#' line and following the typing round.
#'
#' @param repo Which repo do you want to practice typing on ("tidyverse/dplyr") is
#'             the default
#'
#' @examples
#' \dontrun{
#' type_github()
#'}
#'
#' @export
type_github <- function(repo = "tidyverse/dplyr") {
  cat("\n...Getting R file information from Github\n")
  version <- get_version_from_github(repo)
  r_files <- get_r_files_from_github(repo)
  user_choice <- get_user_choice(r_files)
  expressions <- parse(r_files[[user_choice]])
  deparsed <- get_deparsed_object(expressions)
  grouped_exprs <- get_grouped_exprs(deparsed)
  expr_group_choice <- get_user_group_choice(grouped_exprs)
  # User choice for which expression group to type
  perform_countdown(.5)
  results_df <- type_contents(grouped_exprs[[expr_group_choice]])  
  net_wpm <- evaluate_results(results_df)
  cat("\nOverall Net WPM:", net_wpm, "\n")
  cat("Total time:", sum(results_df$time_in_sec), "seconds\n\n")

  if (!("firebase_env" %in% search())) {
    cat("Save progress via typingtutor web app?\n")
    save_choice <- readline("y for yes, Enter to bypass:")
    if (tolower(save_choice) %in% c("y", "yes")) init()
  }
  if ("firebase_env" %in% search()) {
    write_data_to_firebase(
      list(repo             = repo,
           version          = version,
           r_file           = names(r_files)[user_choice],
           expression_group = names(grouped_exprs)[expr_group_choice],
           wpm              = net_wpm))
  }
}
