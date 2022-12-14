# install.packages("devtools")
# devtools::install_github("stefanwilhelm/ShinyRatingInput")

library(shiny)
library(recommenderlab)
library(stringr)
library(tidyverse)
library(shinydashboard)
library(data.table)
library(ShinyRatingInput)
library(shinyjs)

source('assets/helpers.R')

# load preprocessed movies data
data_url = "https://github.com/wjonasreger/shiny_movie_recommender/blob/main/data/"
url_dl = "?raw=true"
# data_url = "../data/"
# url_dl = ""
movies = readLines(paste0(data_url, 'movies.dat', url_dl))
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 7, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)

colnames(movies) = movies[1, ]
movies = movies[-1, ]

num_col = c("movie_id", "num_ratings", "rank", "unweighted_mean_rating")
movies[, num_col] = sapply(movies[, num_col], as.numeric)

movie_genres = delCat(movies$genres, sep='\\|')
cats = c("All", sort(colnames(movie_genres)))
movies = cbind(movies, movie_genres)

movies = movies %>%
  arrange(desc(rank))

# load recommender models
UBCF_REC_MOD = readRDS("models/ubcf.rds")
IBCF_REC_MOD = readRDS("models/ibcf.rds")

# system II testing
# movie_id rating
# 1:     3624      3
# 2:     1213      1
# 3:      745      5
# 4:       50      5
# 5:     1784      5

# user_ratings = data.frame(
#   movie_id = as.numeric(c(3624, 1213, 745, 50, 1784)),
#   rating = as.numeric(c(3, 1, 5, 5, 5))
# )
# user_ratings
# 
# rating_matrix = preprocessRatings(user_ratings, UBCF_REC_MOD)
# pred_recommend = predict(UBCF_REC_MOD, rating_matrix, type="ratings")
# pred_recommend = as.numeric(as(pred_recommend, "matrix"))
# pred_ids = order(pred_recommend, decreasing = TRUE, na.last = TRUE)
# movies[pred_ids[1:(2 * 6)], "title"]



























