# 🎵 Spotify Song Recommendation System in R

An interactive music recommendation engine built with R and Shiny. The system uses **K-Means Clustering** and **Approximate Nearest Neighbour (ANN)** search to recommend songs similar to ones you already love — based purely on audio features.

---

## 📌 How It Works

1. **Load** the Spotify audio features dataset
2. **Scale** 9 audio features (danceability, energy, loudness, speechiness, acousticness, instrumentalness, liveness, valence, tempo)
3. **Cluster** songs into 10 groups using K-Means
4. **Recommend** songs using ANN search (via `RANN`) based on the average feature vector of your selected songs
5. **Visualise** clusters with PCA and audio profiles with a radar chart — all in an interactive Shiny dashboard

---

## 📂 Dataset

This project uses the **Spotify Audio Features Dataset** from Kaggle:

🔗 [https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset](https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset)

- ~11,000 tracks
- 23 columns (13 features used in this project)

> Download `SpotifyFeatures.csv` from Kaggle and place it in the same directory as `app.R` before running.

---

## 🚀 Getting Started

### Prerequisites
- R (>= 4.0)
- RStudio (recommended)

### Installation & Run

```r
# 1. Clone the repository
# 2. Place SpotifyFeatures.csv in the project folder
# 3. Open app.R in RStudio
# 4. Run the app — it will install all required packages automatically
```

Or manually install dependencies:

```r
install.packages(c("shiny", "shinydashboard", "DT", "plotly", "data.table", "RANN", "memoise"), dependencies = TRUE)
```

Then run:

```r
shiny::runApp("app.R")
```

---

## 📦 Libraries Used

| Library | Purpose |
|---|---|
| `shiny` | Interactive web app framework |
| `shinydashboard` | Dashboard UI layout |
| `DT` | Interactive data tables |
| `plotly` | Radar chart & PCA scatter plot |
| `data.table` | Fast data loading and processing |
| `RANN` | Approximate Nearest Neighbour search |
| `memoise` | Caching repeated ANN computations |

---

## 🔮 Future Enhancements

- Integration with the **Spotify Web API** for real-time data, album art, and song previews
- **Hybrid recommendation model** combining content-based and collaborative filtering
- **Mood & genre-based recommendations**
- Improved UI with album covers and richer visualizations

---

## 📚 References

- [Kaggle Dataset](https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset)
- [CRAN R Manuals](https://cran.r-project.org/manuals.html)
- [Shiny Documentation](https://shiny.posit.co)
- [Plotly for R](https://plotly.com/r)
- [RANN Package](https://cran.r-project.org/package=RANN)
- [memoise Package](https://cran.r-project.org/package=memoise)
