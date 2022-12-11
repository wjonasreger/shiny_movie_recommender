# server.R

# helper function to preprocess long-form data for new user ratings into rRM obj
preprocessRatings = function(user_input, rec_mod) {
  user_input$movie_id = paste0('m', user_input$movie_id)
  
  # dataframe > sparseMatrix > realRatingMatrix
  # note: it is necessary to get factor levels across all items
  # already existing in recommender model before filtering out
  # rows with NA ratings.
  method = rec_mod@method
  if (method == "UBCF") {
    RRM_items = rec_mod@model$data@data@Dimnames[[2]]
  } else if (method == "IBCF") {
    RRM_items = rec_mod@model$sim@Dimnames[[2]]
  } else {
    break
  }
  
  tmp_data = data.frame( movie_id = RRM_items ) %>%
    left_join(user_input, "movie_id")
  tmp_data$user_id = rep("u0", nrow(tmp_data))
  
  tmp_data = data.frame(
    user_id = tmp_data$user_id,
    movie_id = tmp_data$movie_id,
    rating = as.integer(tmp_data$rating),
    stringsAsFactors = TRUE
  ) %>%
    drop_na()
  
  # tmp_data = head(tmp_data, 10)
  
  rating_matrix = sparseMatrix(
    dims = c(1, length(RRM_items)),
    as.integer(tmp_data$user_id),
    as.integer(tmp_data$movie_id),
    x = tmp_data$rating
  )
  
  rownames(rating_matrix) = levels(tmp_data$user_id)
  colnames(rating_matrix) = levels(tmp_data$movie_id)
  rating_matrix = new("realRatingMatrix", data = rating_matrix)
  
  return(rating_matrix)
}

# helper function to extract user ratings input from shiny input list
get_user_ratings = function(value_list) {
  dat = data.table(movie_id = sapply(strsplit(names(value_list), "_"), 
                                    function(x) ifelse(length(x) > 1, x[[2]], NA)),
                   rating = unlist(as.character(value_list)))
  dat = dat[!is.null(rating) & !is.na(movie_id)]
  dat[rating == " ", rating := 0]
  dat[, ':=' (movie_id = as.numeric(movie_id), rating = as.numeric(rating))]
  dat = dat[rating > 0]
}

# dimensions of data table
num_rows = 3
num_movies = 5


################################################################################


server = function(input, output, session) {
  # updates genre dropdown with choices dynamically upon loading
  updateSelectInput(
    session = session, 
    inputId = "selectGenre",
    choices = cats
  )
  
  # select ids of movies to be shown in system I (based on genre input)
  sample_movies = reactive({
    if (input$selectGenre == "All") {
      ids = (1:nrow(movies))[
        movies$num_ratings > quantile(movies$num_ratings, na.rm = TRUE, probs = c(0.25))
        ][1:(num_rows * num_movies)]
      movies[ids, ]
    } else {
      ids = (1:nrow(movies))[(movies[[input$selectGenre]] == 1) 
                             & movies$num_ratings > quantile(movies$num_ratings, na.rm = TRUE, probs = c(0.25))
                             ][1:(num_rows * num_movies)]
      movies[ids, ]
    }
  })
  
  # rendering table of movies for system I
  output$top_in_genre = renderUI({
    num_rows = num_rows
    num_movies = num_movies
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(
        lapply(1:num_movies, function(j) {
          list(box(
            width = 2, status = "success", title = paste0("Rank ", (i - 1) * num_movies + j),
            div(style = "text-align:center; margin-top: -13px", 
                a(href = paste0("https://www.google.com/search?q=", 
                                paste0(
                                  sample_movies()$title[(i - 1) * num_movies + j])
                                ), target = "blank",
                  img(src = sample_movies()$image_url[(i - 1) * num_movies + j], 
                      style="max-height:150; border-radius: 5%;")
                  )),
            div(style = "text-align:center; font-weight: bold; font-size: 90%; color: #666666; margin-top: 5px",
                paste0(
                  sample_movies()$title[(i - 1) * num_movies + j], " — ",
                  round(sample_movies()$unweighted_mean_rating[(i - 1) * num_movies + j], 2), "/5.00"))
          ))
        })
      ))
    })
  })
  
  # rendering table of movies to be rated for system II
  output$to_be_rated = renderUI({
    num_rows = 20
    num_movies = 6
    ids = sample(1:(2 * num_rows * num_movies), num_rows * num_movies)
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(
        lapply(1:num_movies, function(j) {
          list(
            box(width = 2, status = "info",
              div(style = "text-align: center", 
                  img(src = movies$image_url[ids[(i-1) * num_movies+j]], style="max-height: 150px; border-radius: 5%;")),
              div(style = "text-align:center; font-weight: bold; font-size: 90%; color: #666666",
                  paste0(
                    movies$title[ids[(i-1) * num_movies+j]])),
              div(style="text-align: center; color: #f0ad4e;", 
                  ratingInput(paste0("select_", 
                                     movies$movie_id[ids[(i-1) * num_movies+j]]), label = "", dataStop = 5))
            )
          )
        })
      ))
    })
  })
  
  # calculate recommendations when button is pushed for system II
  recommended_movies = eventReactive(input$btn, {
    withBusyIndicatorServer("btn", {
      # hide the ratings box
      useShinyjs()
      runjs("document.querySelector('[data-widget=collapse]').click()")
      
      # get user ratings 
      value_list = reactiveValuesToList(input)
      user_ratings = get_user_ratings(value_list)
      
      rating_matrix = preprocessRatings(user_ratings, UBCF_REC_MOD)
      pred_recommend = predict(UBCF_REC_MOD, rating_matrix, type="ratings")
      # pred_recommend = predict(IBCF_REC_MOD, rating_matrix, type="ratings")
      pred_recommend = as.numeric(as(pred_recommend, "matrix"))
      pred_ids = order(pred_recommend, decreasing = TRUE, na.last = TRUE)
      
      movies[pred_ids[1:(num_rows * num_movies)], ]
    })
  })
  
  # render recommendations for system II
  output$user_recommendations = renderUI({
    num_rows = 2
    num_movies = 6
    
    recommendations = recommended_movies()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(
        lapply(1:num_movies, function(j) {
          box(width = 2, status = "success", title = paste0("Rank ", (i - 1) * num_movies + j),
              
              div(style = "text-align:center; margin-top: -13px", 
                  a(href = paste0("https://www.google.com/search?q=", 
                                  paste0(
                                    recommendations$title[(i - 1) * num_movies + j])
                  ), target = "blank",
                  img(src = recommendations$image_url[(i - 1) * num_movies + j], 
                      style="max-height:150; border-radius: 5%;")
                  )),
              div(style = "text-align:center; font-weight: bold; font-size: 90%; color: #666666; margin-top: 5px",
                  paste0(
                    recommendations$title[(i - 1) * num_movies + j], " — ",
                    round(recommendations$unweighted_mean_rating[(i - 1) * num_movies + j], 2), "/5.00"))
            
          )
        })
      ))
    })
  })
  
}

