library(rjson)
library(jsonlite)

CountryWoeid <- fromJSON(txt = "WOEID.json", flatten =TRUE)
TownList <-    CountryWoeid[CountryWoeid$placeType.name == "Town"    ,  ]
CountryList <- CountryWoeid[CountryWoeid$placeType.name == "Country" ,  ]


shinyUI(pageWithSidebar(
    headerPanel("A Minimum Viable Twitter Analysis Tool"),
    sidebarPanel(
        textInput('TwitterQuery', "Text to be searched (#, @ included): ", "#JeSuisCharlie"), #labeled TwitterQuery
        #numericInput("woeid", "Where On Earth Identifiers: ", 615702, min = 1),
        numericInput('n_Tweets', 'Number of tweets to retrieve: ', 101, min = 1, max = 1500, step = 1), #labeled n_Tweets
        radioButtons("lang","Select the language",c(
            "English"="en",
            "French"="fr",
            "Spanish"="es",
            "Deutsch"="de",
            "Russian"="ru"
        )
        ),
        
#         checkboxInput("checkbox", label = "Take into account GPS coordinate ?", value = FALSE),
        
#         sliderInput("latitude", "Latitude",   -25,  min = -90,  max = 90,  step = .5),
#         sliderInput("longitude", "Longitude", 135, min = -180, max = 180, step = .5),
        
        selectInput("town", "Choose a Town (only for Trend Topics tab)", 
                    choices = TownList$name,
                    selectize =TRUE
        ),
        
        
        dateRangeInput("daterange", "Select a Date range:",
                       start = Sys.Date()-10,
                       end   = Sys.Date())
    ),
    
    mainPanel(
        tabsetPanel(
            tabPanel("Words Cloud", plotOutput("plot")),
            tabPanel("Sentiment Analysis", plotOutput("sentiment")), #Soon when sentiment install_github("timjurka/sentiment") problem is fixed
            tabPanel("Tweets", dataTableOutput("TwitterQuery")),
            tabPanel("Trending Topics by major cities", dataTableOutput("TrendingTopics"))
            #tabPanel("Trending Map", htmlOutput("mapPlot")) #soon             
        )
        
        
    )
))