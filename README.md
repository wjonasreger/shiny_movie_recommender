# Movie Recommender Shiny App

In this project, a movie recommender app was developed as an R Shiny App. The [dataset](https://github.com/wjonasreger/shiny_movie_recommender/tree/main/raw) contains about 1 million anonymous ratings of approximately 3,900 movies made by 6,040 MovieLens users who joined MovieLens in 2000. Specifically, four methods of recommendations were implemented, and two were selected for the app (technically 3 are implemented: System I penalty method, and both UBCF and IBCF for System II).

Here are the methods that were explored:
* Recommender System I
    * Weighted Representations of Users
    * Weighted Mean Ratings with Movie Age Penalty
* Recommender System II
    * User-Based Collaborative Filtering
    * Item-based Collaborative Filtering

---

## Documentation

Here are some important links to view for learning more about this project:
* Analysis Documentation [[source code](https://github.com/wjonasreger/shiny_movie_recommender/tree/main/docs)], [[html](https://wjonasreger.github.io/projects/shiny_movie_recommender/)]
* Data [[raw](https://github.com/wjonasreger/shiny_movie_recommender/tree/main/raw), [processed](https://github.com/wjonasreger/shiny_movie_recommender/blob/main/data/movies.dat)]
* Shiny App [[source](https://github.com/wjonasreger/shiny_movie_recommender/tree/main/movie_recommender), [app link](https://h550e6-wjonasreger.shinyapps.io/movie_recommender/), [models](https://github.com/wjonasreger/shiny_movie_recommender/tree/main/movie_recommender/models)]

---

## Recommentder Systems

### Recommender System I: Weighted Mean User Ratings with Movie Age Penalty

Recommender System I in the app uses the following formula to measure the rank of a movie in order to select the top movies in a given genre.

$$\mathbf{rank}_k = S_{[0, 100]}\big(\frac{\sum_{i=1}^m w_i \times r_i}{\sum_{i=1}^m w_i} - S_{[0, 1]}(\log(\texttt{movie age})) \big)$$

Where $S(\cdot)$ is a mapping function that transforms the input to some space $[a, b]$.

### Recommender System II: UBCF and IBCF

Recommneder System II in the app both utilize UBCF and IBCF Recommender models from the `recommenderlab` package.

UBCF recommendations are essentially movies that are liked by other users that are similar to the test user, while IBCF recommendations are movies that are similar to movies the test user rated highly on. Follow the **Analysis Documentation** html link to read more about these implementations.

---

## How to use the Shiny App

The app is fairly simple to use, but here are some guidelines on how to use it and other details.

1. Recommendations by Genre

* The app will land on the System I page initially, which is called **Popular Movies by Genre**.
![sys1-land](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys1-default.png)

* The user selects a genre and the region to the right (with movie info) will update to show the top 15 movies in the genre based on movie ranks computed by the Recommender System I. Here is an example of selecting **Animation** and viewing the top movies in that genre. By default, this will show the top 15 movies across all genres when the app is opened (i.e., **All** genres).
![sys1-select](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys1-animation.png)

2. Recommendations by New User Ratings

* The user will click on the **Recommended Movies by Ratings** tab to switch into the Recommender System II interface. This will show a scrollable window of over 100 movies with 5-star rating inputs.
![sys2-init](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys2-default.png)

* The user will rate as many movies as they have seen. If less than 3 movies are rated, then the system will default to recommending the top 12 movies of all genres (i.e., this will be the same as System I default recommendations).
    * Sometimes computation errors occur with too few rating inputs. Also if a user is unable to rate more than 2 movies, then it is reasonable from an app perspective to implicitly use System I recommendations to help the user get exposed to more movies first. System II recommendations may perform poorly with very few ratings from the user.
![user-ratings](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys2-ratings.png)

* Once the user finishes with rating movies, they can select the **View your recommendations** button to recieve new movie recommendations. System II was originally only going to utilize UBCF recommendations, but it features both the UBCF and IBCF models to further enhance the recommendation experience for the user. Providing recommendations from both models will allow the user to explore movies they might like based on different criteria.
    * If the user wants to see more movies that are popular amongst their peers (i.e., people who are similar to them based on their movie ratings), then they are more likely to discover new movies outside their current interests.
    ![ubcf](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys2-ubcf-recs.png)
    * If the user wants to see more movies that are similar to the ones they rated highly on, then that allows more recommendations into a genre or some other latent trend of similar movies.
    ![ibcf](https://raw.githubusercontent.com/wjonasreger/shiny_movie_recommender/main/assets-README/sys2-ibcf-recs.png)