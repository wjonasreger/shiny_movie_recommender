# server.R

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
  
  # calculate ubcf recommendations when button is pushed for system II
  recommended_movies = eventReactive(input$btn, {
    withBusyIndicatorServer("btn", {
      # hide the ratings box
      useShinyjs()
      runjs("document.querySelector('[data-widget=collapse]').click()")
      
      # get user ratings 
      value_list = reactiveValuesToList(input)
      user_ratings = getUserRatings(value_list)
      # print(user_ratings)
      if (nrow(user_ratings) < 3) {
        results1 = movies[1:(num_rows * num_movies), ]
        results2 = movies[1:(num_rows * num_movies), ]
        results = list(results1 = results1, results2 = results2)
      } else {
        # ubcf
        ubcf_rating_matrix = preprocessRatings(user_ratings, UBCF_REC_MOD)
        ubcf_pred = predict(UBCF_REC_MOD, ubcf_rating_matrix, type="ratings")
        ubcf_pred = as.numeric(as(ubcf_pred, "matrix"))
        ubcf_pred_ids = order(ubcf_pred, decreasing = TRUE, na.last = TRUE)
        results1 = movies[ubcf_pred_ids[1:(num_rows * num_movies)], ]
        # ibcf
        ibcf_rating_matrix = preprocessRatings(user_ratings, IBCF_REC_MOD)
        ibcf_pred = predict(IBCF_REC_MOD, ibcf_rating_matrix, type="ratings")
        ibcf_pred = as.numeric(as(ibcf_pred, "matrix"))
        ibcf_pred_ids = order(ibcf_pred, decreasing = TRUE, na.last = TRUE)
        results2 = movies[ibcf_pred_ids[1:(num_rows * num_movies)], ]
        results = list(results1 = results1, results2 = results2)
      }
    })
  })  
  
  # render ubcf recommendations for system II
  output$user_recommendations_ubcf = renderUI({
    num_rows = 2
    num_movies = 6
    
    recommendations = recommended_movies()$results1
    gc(verbose = FALSE)
    
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
  
  # render ibcf recommendations for system II
  output$user_recommendations_ibcf = renderUI({
    num_rows = 2
    num_movies = 6
    
    recommendations = recommended_movies()$results2
    gc(verbose = FALSE)
    
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

