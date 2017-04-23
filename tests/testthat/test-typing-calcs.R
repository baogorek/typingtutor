context("Typing calculations")

# Tests use examples from https://www.speedtypingonline.com/typing-equations

string_1 <- "I love keyboarding, don't you?"
string_2 <- "I love keyboarding,     don't you?"

two_hundred_chars <- paste(rep("a", 200), collapse = "")
mistakes <- paste0(substr(two_hundred_chars, 1, 198), "bb")

test_that("Typing calculations work as expected", {
  expect_equal(count_words(string_1), 6)
  expect_equal(count_words(string_2), 6.8)

  expect_equal(get_gross_wpm(two_hundred_chars, 30), 80)
  expect_equal(get_errors_per_min(two_hundred_chars, mistakes, 30), 4) 

  expect_equal(get_net_wpm(80, 4, 60), 76)
})
