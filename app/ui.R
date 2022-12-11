# ui.R

# app header
header = dashboardHeader(
  title = "Movie Recommender"
)

# tabpanel for system I recommender
system1 = tabPanel(
  title = "Genres",
  fluidRow(
    column(
      width = 2,
      box(
        title = "User Input", width = NULL, status = "warning",
        selectInput(
          inputId = "selectGenre", 
          label = "Select Genre",
          choices = c("hi" = 1),
          selected = "hi"
        ),
        p(
          class = "text-muted",
          paste("Currently showing the top 15 movies of the selected genres.")
        )
      )
    ),
    column(
      width = 10,
      box(
        title = "Top 15 Movies", width = NULL, status = "info",
        div(class = "generalitems",
          uiOutput("top_in_genre")
        )
      )
    )
  )
)

# tabpanel for system II recommender
system2 = tabPanel(
  title = "Ratings",
  fluidRow(
    box(
      width = 12, title = "Rate as many movies as possible", status = "info", collapsible = TRUE,
      div(
        class = "rateitems",
        uiOutput("to_be_rated")
      )
    )
  ),
  fluidRow(
    useShinyjs(),
    box(
      width = 12, status = "info", title = "Recommended movies based on ratings",
      br(),
      withBusyIndicatorUI(
        actionButton("btn", "View recommendations", class = "btn-warning")
      ),
      br(),
      tableOutput("user_recommendations")
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

