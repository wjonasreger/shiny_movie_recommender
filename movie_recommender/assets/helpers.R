# helper functions for the movie recommender shiny app.
# load functions into app by source("assets/helpers") in `global.R` file

# `withBusyIndicator` functions for `server.R` and `ui.R` are referenced from
# /pspachtholz at https://github.com/pspachtholz/BookRecommender

# `getUserRatings` and `preprocessRatings` are custom functions to handle data 
# preprocessing of new user ratings as input to the recommender models loaded 
# in `global.R`: `UBCF_REC_MOD` and `IBCF_REC_MOD`

################################################################################
################################################################################

# UI button for system II

# set up a button to have an animated loading indicator and a checkmark
# for better user experience
# need to use with the corresponding `withBusyIndicator` server function
withBusyIndicatorUI = function(button) {
  id <- button[['attribs']][['id']]
  div(
    `data-for-btn` = id,
    button,
    span(
      class = "btn-loading-container",
      hidden(
        img(src = "ajax-loader-bar.gif", class = "btn-loading-indicator"),
        icon("check", class = "btn-done-indicator")
      )
    ),
    hidden(
      div(class = "btn-err",
          div(icon("exclamation-circle"),
              tags$b("Error: "),
              span(class = "btn-err-msg")
          )
      )
    )
  )
}

# call this function from the server with the button id that is clicked and the
# expression to run when the button is clicked
withBusyIndicatorServer = function(buttonId, expr) {
  # UX stuff: show the "busy" message, hide the other messages, disable the button
  loadingEl = sprintf("[data-for-btn=%s] .btn-loading-indicator", buttonId)
  doneEl = sprintf("[data-for-btn=%s] .btn-done-indicator", buttonId)
  errEl = sprintf("[data-for-btn=%s] .btn-err", buttonId)
  shinyjs::disable(buttonId)
  shinyjs::show(selector = loadingEl)
  shinyjs::hide(selector = doneEl)
  shinyjs::hide(selector = errEl)
  on.exit({
    shinyjs::enable(buttonId)
    shinyjs::hide(selector = loadingEl)
  })
  
  # try to run the code when the button is clicked and show an error message if
  # an error occurs or a success message if it completes
  tryCatch({
    value = expr
    shinyjs::show(selector = doneEl)
    shinyjs::delay(2000, shinyjs::hide(selector = doneEl, anim = TRUE, animType = "fade",
                                       time = 0.5))
    value
  }, error = function(err) { errorFunc(err, buttonId) })
}

# when an error happens after a button click, show the error
errorFunc = function(err, buttonId) {
  errEl = sprintf("[data-for-btn=%s] .btn-err", buttonId)
  errElMsg = sprintf("[data-for-btn=%s] .btn-err-msg", buttonId)
  errMessage = gsub("^ddpcr: (.*)", "\\1", err$message)
  shinyjs::html(html = errMessage, selector = errElMsg)
  shinyjs::show(selector = errEl, anim = TRUE, animType = "fade")
}

################################################################################
################################################################################

# user ratings data preprocessing for system II

# helper function to extract user ratings input from shiny input list
getUserRatings = function(value_list) {
  dat = data.table(movie_id = sapply(strsplit(names(value_list), "_"), 
                                     function(x) ifelse(length(x) > 1, x[[2]], NA)),
                   rating = unlist(as.character(value_list)))
  dat = dat[!is.null(rating) & !is.na(movie_id)]
  dat[rating == " ", rating := 0]
  dat[, ':=' (movie_id = as.numeric(movie_id), rating = as.numeric(rating))]
  dat = dat[rating > 0]
}

# preprocess long-form data for new user ratings into rRM obj
preprocessRatings = function(user_input, rec_mod) {
  user_input$movie_id = paste0('m', user_input$movie_id)
  
  # dataframe > sparseMatrix > realRatingMatrix
  # note: it is necessary to get factor levels across all items already 
  # existing in recommender model before filtering out rows with NA ratings.
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

################################################################################
################################################################################

# sample css code for app (not utilized)

appCSS <- "
.btn-loading-container {
  margin-left: 10px;
  font-size: 1.2em;
}
.btn-done-indicator {
  color: green;
}
.btn-err {
  margin-top: 10px;
  color: red;
}
"