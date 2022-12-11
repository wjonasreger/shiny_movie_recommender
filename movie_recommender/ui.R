# ui.R

# app header
header = dashboardHeader(
  title = "Movie Recommender"
)

# tabpanel for system I recommender
system1 = tabPanel(
  title = "Popular Movies by Genre",
  fluidRow(
    column(
      width = 2,
      box(
        title = "Top movies based on genre", width = NULL, status = "warning",
        selectInput(
          inputId = "selectGenre", 
          label = "Show me movies in...",
          choices = c("hi" = 1),
          selected = "hi"
        ),
        p(
          class = "text-muted",
          paste("Currently showing the top movies of your selected genre.")
        )
      )
    ),
    column(
      width = 10,
      box(
        title = "View the top 15 ranked movies of your selected genre", width = NULL, status = "info",
        div(class = "generalitems",
          uiOutput("top_in_genre"),
          p(
            class = "text-muted",
            paste("Developed by Jonas Reger and Hope Hunter. The source code is available at https://github.com/wjonasreger/shiny_movie_recommender.")
          )
        )
      )
    )
  )
)

# tabpanel for system II recommender
system2 = tabPanel(
  title = "Recommended Movies by Ratings",
  fluidRow(
    box(
      width = 12, title = "Rate as many movies as possible that you have seen", status = "info", collapsible = TRUE,
      div(
        class = "rateitems",
        uiOutput("to_be_rated")
      )
    )
  ),
  fluidRow(
    useShinyjs(),
    box(
      width = 12, status = "info", title = "Personalized recommendations based on your ratings",
      radioButtons(
        inputId = "selectModel", label = "Choose what kind of recommendations you want to see",
        choices = c(
          "Show me movies liked by people like me" = "UBCF",
          "Show me movies similar to what I liked" = "IBCF"
        )
      ),
      br(),
      withBusyIndicatorUI(
        actionButton("btn", "View your recommendations", class = "btn-warning")
      ),
      br(),
      tableOutput("user_recommendations"),
      p(
        class = "text-muted",
        paste("Developed by Jonas Reger and Hope Hunter. The source code is available at https://github.com/wjonasreger/shiny_movie_recommender.")
      )
    )
  )
)

# app body
body = dashboardBody(
  includeCSS("assets/styles.css"),
  fluidRow(
    tabBox(
      title = NULL, width = 12,
      id = "tabBox",
      system1,
      system2
    )
  )
)

# app dashboard page
dashboardPage(
  skin = "purple",
  header,
  dashboardSidebar(disable = TRUE),
  body
)

