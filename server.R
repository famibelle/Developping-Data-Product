#inspiration came from http://davetang.org/muse/2013/04/06/using-the-r_twitter-package/
#install.packages("ROAuth")
#install.packages("twitteR")
#install.packages("wordcloud")
#install.packages("tm")
#install_github("timjurka/sentiment")
# install_url("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz")

# require(sentiment)

library(twitteR)
library(shiny)
library(ROAuth)
library(RColorBrewer)
library(tm)
library(wordcloud)
library(googleVis)
library(ggplot2)

load("twitter.authentication")
registerTwitterOAuth(twitCred)

shinyServer(
    function(input, output) {
        r_stats <- reactive({
            QueryResult <- searchTwitteR(input$TwitterQuery, 
                      n = input$n_Tweets, 
                      since = as.character(input$daterange[1]),
                      until = as.character(input$daterange[2]),
                      lang = input$lang,
                      cainfo = "cacert.pem")
            #Clean the data into a neat dataframe
            do.call("rbind", lapply(QueryResult, as.data.frame))
                
        })
        
        output$TwitterQuery <- renderDataTable({
            withProgress(message = 'Calculation in progress',
                        detail = 'This may take a while...', value = 0, {
                             r_stats()[,c("screenName", "text", "created") ]
                        })
            
            })
        output$on_Tweets    <- renderPrint({input$n_Tweets})
        output$oid2         <- renderPrint({input$id2})
        output$odate        <- renderPrint({input$daterange})

# uncomment for local usage
#         output$sentiment <- renderPlot({
#             withProgress(message = 'Calculation in progress',
#                          detail = 'This may take a while...', value = 0, {
#                              TweetSentiments <- r_stats()
#                          })
#                         
#             emotion  <- classify_emotion( TweetSentiments[,c("text") ],algorithm="bayes", prior=1.0)
#             polarity <- classify_polarity(TweetSentiments[,c("text") ],algorithm="bayes", prior=1.0)
#             emotion  <- as.data.frame(emotion)
#             polarity <- as.data.frame(polarity)
#             
#             TweetSentiments[,17] <- emotion[,7]
#             TweetSentiments[,18] <- polarity[,4]
#             
#             names(TweetSentiments) <- c(
#                 "text", "favorited", "favoriteCount", "replyToSN", "created", "truncated", 
#                 "replyToSID", "id", "replyToUID", "statusSource", "screenName", "retweetCount", 
#                 "isRetweet", "retweeted", "longitude", "latitude", 
#                 "emotion", "polarity"
#             )
#                             
#             EmotionPlot <- ggplot(TweetSentiments, aes(x=emotion))
#             EmotionPlot <- EmotionPlot + geom_bar(aes(y=..count.., fill=emotion))
#             PolarityPlot <- ggplot(TweetSentiments, aes(x=polarity))
#             PolarityPlot <- PolarityPlot + geom_bar(aes(y=..count.., fill=polarity))
# 
#             return(PolarityPlot)
#         })
        
        output$TrendingTopics <- renderDataTable({
            TrendLocation <- closestTrendLocations(input$latitude, input$longitude)
            TT <- getTrends(TrendLocation$woeid)
            TT[,"woeid"] <- TrendLocation$country
            names(TT) <- c("name",  "url",   "query", "country")
            TT[, c("name","country")]
            })
        
        output$plot <- renderPlot({
            withProgress(message = 'Collecting tweets in progress',
                         detail = 'This may take a while...', value = 0, {
                             VectorTweet <- as.vector(r_stats()[,"text"])
                         })
            
            Tweet_palette <-brewer.pal(9,"Set1")
            TweetCorpus <- Corpus(VectorSource(VectorTweet))
            TweetCorpus <- tm_map(TweetCorpus, tolower)
            TweetCorpus <- tm_map(TweetCorpus, function(x) removeWords(x,c("http\\w+", stopwords(input$lang))))
            TweetCorpus <- tm_map(TweetCorpus, removePunctuation)
            TweetCorpus <- tm_map(TweetCorpus, removeNumbers)
            TweetCorpus <- tm_map(TweetCorpus, PlainTextDocument)
            wordcloud(TweetCorpus,min.freq=10,max.words=100, random.order=T, colors=Tweet_palette)
            })
        
#         output$mapPlot <- renderGvis({
#             TrendLocation <- data.frame(matrix(NA, nrow = 245, ncol = 3))
#             names(TrendLocation) <- c("name", "country", "woeid")
#             
#             for (i in 1:26) {
#                 TrendLocation[i,] <- closestTrendLocations(countryList$latitude[i], countryList$longitude[i])
#                 TrendLocation[i,4] <- getTrends(TrendLocation$woeid[i])$name[1]
#                 print(i)
#             }
#             TrendLocation <- TrendLocation[,-1]
#             names(TrendLocation) <- c("country", "woeid", "trending")
#             GeoMap <- gvisGeoMap(TrendLocation[c(1:26),], locationvar="country", hovervar="Trending")
#             plot(GeoMap)
#                 #TT[i,"woeid"] <- TrendLocation$country[i]
#                 #names(TT) <- c("name",  "url",   "query", "country")
#                 #data <- cbind(TT$country, TT$name)
#                 #data <- as.data.frame(data)
#                 #data <- cbind(data, as.data.frame(10:1))
#                 #data <- as.data.frame(data)
#                 #data <- data[,c(1,3,2)]
#                 #names(data) <- c("Country", "Int", "Trending")
#                 
#             
#             #TrendLocation <- closestTrendLocations(input$latitude, input$longitude)
#             #TT <- getTrends(TrendLocation$woeid)
#             #TT[,"woeid"] <- TrendLocation$country
#             #names(TT) <- c("name",  "url",   "query", "country")
#             #data <- cbind(TT$country, TT$name)
#             #data <- as.data.frame(data)
#             #data <- cbind(data, as.data.frame(10:1))
#             #data <- as.data.frame(data)
#             #data <- data[,c(1,3,2)]
#             #names(data) <- c("Country", "Int", "Trending")
#             #GeoMap <- gvisGeoMap(data, locationvar="Country", hovervar="Trending")
#             #return(GeoMap)
#             
#         })
    }
)