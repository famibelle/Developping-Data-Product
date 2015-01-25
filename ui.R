shinyUI(pageWithSidebar(
    headerPanel("A Minimum Viable Twitter Analysis Tool"),
    sidebarPanel(
        textInput('TwitterQuery', "Text to be searched (#, @ included): ", "medhi"), #labeled TwitterQuery
        #numericInput("woeid", "Where On Earth Identifiers: ", 615702, min = 1),
        sliderInput("latitude", "Latitude",   -25,  min = -90,  max = 90,  step = .5),
        sliderInput("longitude", "Longitude", 135, min = -180, max = 180, step = .5),
        numericInput('n_Tweets', 'Number of tweets to retrieve: ', 7, min = 1, max = 1500, step = 1), #labeled n_Tweets
        radioButtons("lang","Select the language",c(
            "French"="fr",
            "English"="en",
            "Spanish"="es",
            "Deutsch"="de",
            "Russian"="ru"
            )
            ),
        
        
        dateRangeInput("daterange", "Select a Date range:",
                       start = Sys.Date()-10,
                       end   = Sys.Date())
        ),
    
    mainPanel(
        tabsetPanel(
            tabPanel("Words Cloud", plotOutput("plot")),
            tabPanel("Tweets", dataTableOutput("oTwitterQuery")),
            tabPanel("Trending Topics by countries", dataTableOutput("TrendingTopics")),
            #tabPanel("Trending Map", htmlOutput("mapPlot")) #soon 
            tabPanel("Sentiment", verbatimTextOutput("sentiment")) #soon            
        )
    
        
        #h3('Search Results'),

        #h4('Selected date Range'),
        #verbatimTextOutput("odate"),

        #h4('Tweets'),
        #dataTableOutput("oTwitterQuery")
        
        #h4('Number of tweets'),
        #verbatimTextOutput("on_Tweets"),
        
        #h4('Tweets Type'),
        #verbatimTextOutput("oid2"),
        
        )
))
