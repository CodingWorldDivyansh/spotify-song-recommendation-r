# ============================================================
# Spotify Song Recommendation System in R
# Uses K-Means Clustering + ANN (RANN) + Shiny Dashboard
# Dataset: https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset
# ============================================================

# ----------------------------
# 1. Package Installation
# ----------------------------
packages <- c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "data.table",
  "RANN",
  "memoise"
)

install.packages(packages, dependencies = TRUE)

# ----------------------------
# 2. Load Libraries
# ----------------------------
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(data.table)
library(RANN)
library(memoise)

# ----------------------------
# 3. Load Dataset
# Download from: https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset
# Place "SpotifyFeatures.csv" in your working directory
# ----------------------------
spotify <- fread("SpotifyFeatures.csv")

# ----------------------------
# 4. Clean Data and Prepare Features
# ----------------------------
spotify_clean <- spotify[
  track_name != "" &
    artist_name != ""
]

spotify_clean[, track_id := .I]
spotify_clean[, track_artist := paste(track_name, "-", artist_name)]

# ----------------------------
# 5. Scale Feature Matrix
# ----------------------------
audio_features <- c(
  "danceability", "energy", "loudness", "speechiness",
  "acousticness", "instrumentalness", "liveness",
  "valence", "tempo"
)

feat_mat <- as.matrix(spotify_clean[, ..audio_features])

mins <- apply(feat_mat, 2, min)
maxs <- apply(feat_mat, 2, max)
feat_mat_scaled <- sweep(sweep(feat_mat, 2, mins, "-"), 2, maxs - mins, "/")

# ----------------------------
# 6. K-Means Clustering
# ----------------------------
set.seed(123)
k <- kmeans(feat_mat_scaled, centers = 10)
spotify_clean[, cluster := k$cluster]

# ----------------------------
# 7. PCA for Visualisation
# ----------------------------
set.seed(1)
sample_ids <- sample(nrow(spotify_clean), 3000)
pca <- prcomp(feat_mat_scaled[sample_ids, ])
pca_small <- data.table(
  PC1 = pca$x[, 1],
  PC2 = pca$x[, 2],
  row_index = sample_ids
)

# ----------------------------
# 8. ANN Index for Fast Recommendations
# ----------------------------
get_recs_nn <- memoise(function(selected_ids, n_recs = 10) {
  idx <- match(selected_ids, spotify_clean$track_id)
  sel_vec <- colMeans(feat_mat_scaled[idx, , drop = FALSE])
  kq <- n_recs + 20
  nn <- nn2(feat_mat_scaled, query = matrix(sel_vec, 1), k = kq)
  out <- nn$nn.idx[1, ]
  out <- out[!(spotify_clean$track_id[out] %in% selected_ids)]
  out <- head(out, n_recs)
  spotify_clean[out]
})

# ----------------------------
# 9. Shiny UI
# ----------------------------
ui <- dashboardPage(
  dashboardHeader(title = "Spotify Recommender"),

  dashboardSidebar(
    width = 300,
    h4("Select Your Top 3 Songs"),

    selectizeInput("song1", "Song 1", choices = NULL),
    selectizeInput("song2", "Song 2", choices = NULL),
    selectizeInput("song3", "Song 3", choices = NULL),

    sliderInput("num", "Number of Recommendations",
      min = 5, max = 50, value = 10
    ),

    actionButton("go", "Get Recommendations"),
    actionButton("clear", "Clear Selection")
  ),

  dashboardBody(
    fluidRow(
      box(title = "Selected Songs", DTOutput("selected"), width = 6),
      box(title = "Audio Profile", plotlyOutput("radar"), width = 6)
    ),
    fluidRow(
      box(title = "Recommendations", DTOutput("recs"), width = 12)
    ),
    fluidRow(
      box(title = "Cluster PCA Plot", plotlyOutput("pca"), width = 12)
    )
  )
)

# ----------------------------
# 10. Shiny Server
# ----------------------------
server <- function(input, output, session) {

  song_choices <- setNames(
    as.list(spotify_clean$track_id),
    spotify_clean$track_artist
  )

  updateSelectizeInput(session, "song1", choices = song_choices, server = TRUE)
  updateSelectizeInput(session, "song2", choices = song_choices, server = TRUE)
  updateSelectizeInput(session, "song3", choices = song_choices, server = TRUE)

  vals <- reactiveValues(selected = NULL, recs = NULL)

  observeEvent(input$clear, {
    updateSelectizeInput(session, "song1", selected = "")
    updateSelectizeInput(session, "song2", selected = "")
    updateSelectizeInput(session, "song3", selected = "")
    vals$selected <- NULL
    vals$recs <- NULL
  })

  observeEvent(input$go, {
    ids <- as.integer(c(input$song1, input$song2, input$song3))
    ids <- ids[!is.na(ids)]
    if (length(ids) < 3) return()

    vals$selected <- spotify_clean[track_id %in% ids]
    vals$recs <- get_recs_nn(ids, input$num)
  })

  output$selected <- renderDT({
    if (is.null(vals$selected)) return()
    datatable(vals$selected[, .(track_name, artist_name, cluster)])
  })

  output$recs <- renderDT({
    if (is.null(vals$recs)) return()
    datatable(vals$recs[, .(track_name, artist_name, cluster)])
  })

  output$radar <- renderPlotly({
    if (is.null(vals$selected)) return()

    ids <- vals$selected$track_id
    subset_matrix <- feat_mat_scaled[ids, , drop = FALSE]
    final_scaled <- colMeans(subset_matrix)

    plot_ly(
      type = "scatterpolar",
      r = as.numeric(final_scaled),
      theta = names(final_scaled),
      fill = "toself"
    ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 1)
          )
        ),
        showlegend = FALSE
      )
  })

  output$pca <- renderPlotly({
    pca_small2 <- merge(
      pca_small,
      spotify_clean[, .(row_index = track_id, cluster)],
      by = "row_index",
      all.x = TRUE
    )

    plot_ly(
      pca_small2,
      x = ~PC1,
      y = ~PC2,
      color = ~as.factor(cluster),
      type = "scattergl",
      mode = "markers"
    )
  })
}

# ----------------------------
# Run App
# ----------------------------
shinyApp(ui, server)
