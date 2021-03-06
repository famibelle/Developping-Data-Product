#inspiration came from http://davetang.org/muse/2013/04/06/using-the-r_twitter-package/
#install.packages("ROAuth")
#install.packages("twitteR")
#install.packages("wordcloud")
#install.packages("tm")
#install.packages("devtools")
#library(devtools)
# install.packages("SnowballC")
#install_github("timjurka/sentiment")
#install_url("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz")

# require(sentiment)
require(graphics)

library(twitteR)
library(shiny)
library(ROAuth)
library(RColorBrewer)
library(tm)
library(wordcloud)
library(googleVis)
library(ggplot2)
library(gridExtra)
library(plyr)
library(igraph)
library(stringr)
library(SnowballC)

# load functions 
source("sentiment/R/classify_emotion.R")
source("sentiment/R/classify_polarity.R")
source("sentiment/R/create_matrix.R")
source("who-retweet.R") 
source("cleant.txt.R")
source("Stop.words.R")

# get the world main cities and and countries WOIED (Where On Earth IDentifier)
CountryWoeid <- fromJSON(txt = "WOEID.json", flatten =TRUE)
TownList <-    CountryWoeid[CountryWoeid$placeType.name == "Town"    ,  ]
CountryList <- CountryWoeid[CountryWoeid$placeType.name == "Country" ,  ]

# load all the needed twitter authentication 
load("twitter.authentication")
registerTwitterOAuth(twitCred)

# Shiny main program
shinyServer(
    function(input, output, session) {
        r_stats <- reactive({
            QueryResult <- searchTwitteR(input$TwitterQuery, 
                                            n = input$n_Tweets, 
                                            since = as.character(input$daterange[1]),
                                            until = as.character(input$daterange[2]),
                                            lang = input$lang,
                                            cainfo = "cacert.pem")                
            
            #Transform the list into a neat dataframe
            do.call("rbind", lapply(QueryResult, as.data.frame))            
        })
        
        output$TwitterQuery <- renderDataTable({
                    r_stats()[,c("screenName", "text", "created") ]
        })

        output$on_Tweets    <- renderPrint({input$n_Tweets})
        output$oid2         <- renderPrint({input$id2})
        output$odate        <- renderPrint({input$daterange})
        
        
        output$sentiment <- renderGvis({
            withProgress(message = 'Calculation in progress',
                         detail = 'This may take a while...', value = 0, {
                            TweetSentiments <- r_stats()
        
                            emotion  <- classify_emotion( TweetSentiments[,c("text") ],algorithm="bayes", prior=1.0)
                            polarity <- classify_polarity(TweetSentiments[,c("text") ],algorithm="bayes", prior=1.0)
                            emotion  <- as.data.frame(emotion)
                            polarity <- as.data.frame(polarity)
                         }
            )
            
            TweetSentiments[,17] <- emotion[,7]
            TweetSentiments[,18] <- polarity[,4]
            
            names(TweetSentiments) <- c(
                "text", "favorited", "favoriteCount", "replyToSN", "created", "truncated", 
                "replyToSID", "id", "replyToUID", "statusSource", "screenName", "retweetCount", 
                "isRetweet", "retweeted", "longitude", "latitude", 
                "emotion", "polarity"
            )
            Polarity <- count(TweetSentiments$polarity)
            Emotion  <- count(TweetSentiments$emotion)
            PiePolarity <- gvisPieChart(Polarity,
                                        options=list(
                                            title='Tweets Polarity'
                                            )
                                        )
            PieEmotion  <- gvisPieChart(Emotion,
                                        options=list(
                                            title='Tweets Emotion'
                                        )
            )
            PolarityPercentage <- Polarity
            PolarityPercentage$freq <- round(PolarityPercentage$freq/input$n_Tweets*100,2)
            GaugePolarityNegative <- gvisGauge(
                PolarityPercentage[1,], labelvar = "x",
                options=list(
                    #                     animation = "{startup: TRUE, duration : 400 }",
                    #                     NumberFormat = "{pattern: \"#'%'\"}",
                    min=0, 
                    max=100, 
                    redFrom=75, 
                    redTo=100
                )
            )
            
            Gauges <- gvisMerge(gvisMerge(PiePolarity, PieEmotion, horizontal=FALSE),
                                GaugePolarityNegative, horizontal=TRUE, tableOptions="cellspacing=5")
            return(Gauges)
        })

        output$TrendingTopics <- renderDataTable({
            TT <- getTrends(TownList[TownList$name == input$town, "woeid"], cainfo = "cacert.pem")
            TrendingTopics <- as.data.frame(TT$name)
            names(TrendingTopics) <- paste("Trending in ", input$town, sep="")
            return(TrendingTopics)            
        },
            options=list(
                     lengthChange = FALSE    # show/hide records per page dropdown
            )
        )
        
        output$WhoRT <- renderPlot({
            withProgress(message = 'Collecting tweets in progress',
                         detail = 'This may take a while...', value = 0, {
                             Who_RT_the_Tweet(Tweet = input$TwitterQuery, no_of_tweets = input$n_Tweets, lang = input$lang)
                         })
            })

        
        output$dendrogram <- renderPlot({
            withProgress(message = 'Collecting tweets in progress',
                         detail = 'This may take a while...', value = 0, {
                             VectorTweet <- as.vector(r_stats()[,"text"])
                         })
            
            withProgress(message = 'Processing Corpus and Dendrogram',
                         detail = 'This may take a while...', value = 0, {
                             VectorTweet <- clean.text(VectorTweet)
                             TweetCorpus <- Corpus(VectorSource(VectorTweet))
#                              TweetCorpus <- tm_map(TweetCorpus,
#                                                 content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte')),
#                                                 mc.cores=1)
                             TweetCorpus <- tm_map(TweetCorpus, tolower)
                            TweetCorpus <- tm_map(TweetCorpus, function(x) removeWords(x,c("http://t.co/*", "https://t.co/*", "RT", Stop.words(input$lang))))

                             TweetCorpus <- tm_map(TweetCorpus, removePunctuation)
                             TweetCorpus <- tm_map(TweetCorpus, removeNumbers)
                             TweetCorpus <- tm_map(TweetCorpus, PlainTextDocument)
                             # keep a copy of corpus to use later as a dictionary for stem completion
                             myCorpus <- TweetCorpus
                             myCorpusCopy <- myCorpus
                             # stem words
                             myCorpus <- tm_map(myCorpus, stemDocument)
                             # stem completion
#                              myCorpus <- tm_map(myCorpus, stemCompletion, dictionary = myCorpusCopy)
                             tdm <- TermDocumentMatrix(myCorpus, control = list(wordLengths = c(1, Inf)))
                             # remove sparse terms
                             tdm2 <- removeSparseTerms(tdm, sparse = 0.95)
                             m2 <- as.matrix(tdm2)
                             # cluster terms
                             distMatrix <- dist(scale(m2))
                             fit <- hclust(distMatrix, method = "ward.D")
                             plot(fit)
                             rect.hclust(fit, k = 6) # cut tree into 6 clusters
                         })
        })        
        
        output$plot <- renderPlot({
            withProgress(message = 'Collecting tweets in progress',
                         detail = 'This may take a while...', value = 0, {
                             VectorTweet <- as.vector(r_stats()[,"text"])
                         })

            withProgress(message = 'Processing word cloud',
                         detail = 'This may take a while...', value = 0, {
                Tweet_palette <-brewer.pal(9,"Set1")
                VectorTweet <- clean.text(VectorTweet)
                
                TweetCorpus <- Corpus(VectorSource(VectorTweet))
                TweetCorpus <- tm_map(TweetCorpus, tolower)
                TweetCorpus <- tm_map(TweetCorpus, function(x) removeWords(x,c("http://t.co/*", "https://t.co/*", "RT", Stop.words(input$lang))))
                TweetCorpus <- tm_map(TweetCorpus, removePunctuation)
                TweetCorpus <- tm_map(TweetCorpus, removeNumbers)
                TweetCorpus <- tm_map(TweetCorpus, PlainTextDocument)
                wordcloud(TweetCorpus,
                          min.freq=5,max.words=500, 
                          random.order=FALSE,
                          scale = c(4,1),
                          colors=Tweet_palette)
            })
        })
    }
)