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
# data_url = "https://github.com/wjonasreger/movie_recommender_shiny/raw/"
# url_dl = "?raw=true"
data_url = "../data/"
url_dl = ""
movies = readLines(paste0(data_url, 'movies.dat', url_dl))
movies = strsplit(movies, 
                          split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 24, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)

colnames(movies) = movies[1, ]
movies = movies[-1, ]

num_col = c("movie_id", "num_ratings", "rank", "unweighted_mean_rating", 
            "Animation", "Children's", "Comedy", "Adventure", "Fantasy", 
            "Romance", "Drama", "Action", "Crime", "Thriller", "Horror", 
            "Sci-Fi", "Documentary", "War", "Musical", "Mystery", "Film-Noir",
            "Western")
movies[, num_col] = sapply(movies[, num_col], as.numeric)
# movies[rowSums(is.na(movies)) > 0, ]

# genre categories for system I
cats = c("All", "Animation", "Children's", "Comedy", "Adventure", "Fantasy", 
         "Romance", "Drama", "Action", "Crime", "Thriller", "Horror", "Sci-Fi",
         "Documentary", "War", "Musical", "Mystery", "Film-Noir", "Western")

movies = movies %>%
  arrange(desc(rank))

# load recommender models
UBCF_REC_MOD = readRDS("../data/ubcf.rds")
IBCF_REC_MOD = readRDS("../data/ibcf.rds")

# system II testing
# movie_id rating
# 1:     2959      5
# 2:     2594      3
# 3:     3175      5
# 4:     3006      5
# 5:       17      4
# 6:      527      4
# 7:      318      5

# user_ratings = data.frame(
#   movie_id = as.numeric(c(2959, 2594, 3175, 3006, 17, 527, 318)),
#   rating = as.numeric(c(5, 3, 5, 5, 4, 4, 5))
# )
# user_ratings
# 
# rating_matrix = preprocessRatings(user_ratings, UBCF_REC_MOD)
# pred_recommend = predict(UBCF_REC_MOD, rating_matrix, type="ratings")
# pred_recommend = as.numeric(as(pred_recommend, "matrix"))
# pred_ids = order(pred_recommend, decreasing = TRUE, na.last = TRUE)
# movies[pred_ids[1:(2 * 6)], "title"]
