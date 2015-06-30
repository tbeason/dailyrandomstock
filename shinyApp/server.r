####server.r
library(shiny)
library(dygraphs)
library(Quandl)
library(PerformanceAnalytics)
library(stringr)
library(xts)
library(DT)

symbolList <- reactiveFileReader(86400000,NULL,'https://s3.amazonaws.com/quandl-static-content/Ticker+CSV%27s/WIKI_tickers.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)
stockDataFile <- reactiveFileReader(1000,NULL,'stockDataFile.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)
stockNameFile <- reactiveFileReader(1000,NULL,'stockNameFile.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)

# Define server logic
shinyServer(function(input, output) {
  
  # grabs new random stock data on Date change
  observeEvent(as.numeric(Sys.Date()),{
    set.seed(floor(as.numeric(Sys.Date())))
    rand <- sample(1:nrow(symbolList()),1)
    newStock <- symbolList()[rand,]
    write.csv(newStock,file='stockNameFile.csv',row.names=FALSE)
    write.csv(Quandl(newStock[[1]],authcode="NFwNwciNUYryUG3r2FRr",start_date='2009-01-01'),file='stockDataFile.csv',row.names=FALSE)
  })
  
  observe({
    fileConn <- file("stockSummary.html")
    title <- '<h2>Random Stock of the Day</h2>'
    text1 <- paste('<p>Today\'s random stock is <b>',fullName(),'</b></p>')
    text2 <- paste('<p>They trade under the symbol <b>',symbol(),'</b></p>')
    text3 <- paste('<p>Last open: <b>',lastOpen(),'</b></p>')
    text4 <- paste('<p>Last close: <b>',lastClose(),'</b></p>')
    text5 <- paste('<p>52-week High: <b>',yrHi(),'</b></p>')
    text6 <- paste('<p>52-week Low: <b>',yrLo(),'</b></p>')
    text7 <- paste('<p>1-month Average Daily Volume: <b>',avgVol(),'</b></p>')
    writeLines(c(title,text1,text2,text3,text4,text5,text6,text7),fileConn)
    close(fileConn)
  })
  
  checkFun1 <- function()
  {
    Sys.Date()
  }
  valueFun1 <- function()
  {
    as.xts(stockDataFile(),order.by=as.Date(stockDataFile()[,1]))
  }
  stockData <- reactivePoll(1000,NULL, checkFun1, valueFun1)
  
  checkFun2 <- function()
  {
    stockNameFile()
  }
  valueFun2 <- function()
  {
    unlist(stockNameFile())
  }
  todayStock <- reactivePoll(1000,NULL, checkFun1, valueFun2)
  
  quandl_code <- reactive({
    todayStock()[[1]]
  })

  symbol <- reactive({
    str_sub(quandl_code(),6,-1)
  })
  
  output$ticker <- renderText({
    symbol()
  })
  
  fullName <- reactive({
    todayStock()[[2]]
  })
  

  closePrices <- reactive({
    Price<-as.xts(as.numeric(stockData()$'Adj..Close'),order.by=index(stockData()))
    return(Price)
  })
  
  lastClose <- reactive({
    as.numeric(stockData()$'Adj..Close'[end(stockData())])
  })
  
  lastOpen <- reactive({
    as.numeric(stockData()$'Adj..Open'[end(stockData())])
  })
  
  volume <- reactive({
    Volume <-as.xts(as.numeric(stockData()$'Adj..Volume'),order.by=index(stockData()))
    return(Volume)
  })
  
  avgVol <-reactive({
    vol <- as.numeric(volume())
    avg<-mean(vol[length(vol)-30:length(vol)])
    round(avg)
  })
  
  yrHi <- reactive({
    pri <- as.numeric(closePrices()[(length(closePrices())-252):length(closePrices())])
    m<-max(pri,na.rm=TRUE)
    round(m,2)
  })
  
  yrLo <- reactive({
    pri <- as.numeric(closePrices()[(length(closePrices())-252):length(closePrices())])
    m<-min(pri,na.rm=TRUE)
    round(m,2)
  })
  
  
  
  output$dygraphPrice <- renderDygraph({
    series <- merge(closePrices(),volume())
    series[,2] <- as.numeric(series[,2])/1000000
    names(series) <-c('Price','Volume')
    dygraph(series, main = paste(symbol(),"Price & Volume History")) %>%
      dySeries('Volume',axis='y2') %>%
      dyAxis('y',label="Stock Price (USD)") %>%
      dyAxis('y2',label="Volume (in Millions of shares)") %>%
      dyOptions(colors = RColorBrewer::brewer.pal(4, "Dark2")) %>%
      dyHighlight(highlightCircleSize = 5, 
                  highlightSeriesBackgroundAlpha = 0.2,
                  hideOnMouseOut = FALSE) %>%
      dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
      dyLegend(width = 400) %>%
      dyRangeSelector(dateWindow = c(start(series), end(series)))
  })
  
  output$dygraphPerf <- renderDygraph({
    SP <- Quandl("SPDJ/SPX", authcode="NFwNwciNUYryUG3r2FRr", trim_start="2009-01-01")
    SP.xts <- as.xts(SP,order.by=as.Date(SP[,1]))
    
    series <- na.omit(merge(closePrices(),SP.xts[,2],SP.xts[,3]))
    names(series) <- c(symbol(),'SP500TR','SP500')
    returns <- na.omit(apply(series,2,Return.calculate))
    growth <- 10000*apply(returns+1,2,cumprod)
    growth.xts <- as.xts(growth,order.by=index(series[2:nrow(series),])) 
    dygraph(growth.xts, main = "Growth of $10,000") %>%
      dyAxis('y',label="Value of Investment (USD)") %>%
      dyOptions(colors = RColorBrewer::brewer.pal(3, "Dark2")) %>%
      dyHighlight(highlightCircleSize = 5, 
                  highlightSeriesBackgroundAlpha = 0.2,
                  hideOnMouseOut = FALSE) %>%
      dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
      dyLegend(width = 400) %>%
      dyRangeSelector(dateWindow = c(start(growth.xts), end(growth.xts)))
  })
  
  output$dataTable <- DT::renderDataTable(
    datatable(as.xts(apply(stockData()[,9:13],2,as.numeric),order.by=index(stockData()$Date)),
      rownames=as.character(index(stockData()[,1])),
      options=list(searching=FALSE)
    )
  )
  
  output$downloadData <- downloadHandler(
    filename = function() { 
      paste('dailyrandomstock-',symbol(),'.csv',sep="") 
    },
    content = function(file) {
      write.csv(stockData(), file,row.names=FALSE)
    }
  )
  
  output$wordCloud <- renderPlot({
    library("twitteR")
    library("wordcloud")
    library("tm")
    
    auths<-read.csv('auths.csv',stringsAsFactors=FALSE,header=FALSE)[,1]
    consumer_key <- auths[1]
    consumer_secret <- auths[2]
    access_token <- auths[3]
    access_secret <- auths[4]
    
    setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)
    
    searchString <- paste('#',symbol(),'+$',symbol(),sep='')
    tweets <- searchTwitter(searchString, n=1200)
    
    #save text
    tweet_text <- sapply(tweets, function(x) x$getText())
    
    removeHTTP <- function(x) gsub("(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", x)
    tweet_text <- sapply(tweet_text, removeHTTP)
    
    
    #create corpus
    tweet_text_corpus <- Corpus(VectorSource(tweet_text))
    
    #clean up
    tweet_text_corpus <- tm_map(tweet_text_corpus, content_transformer(tolower)) 
    tweet_text_corpus <- tm_map(tweet_text_corpus, removePunctuation)
    tweet_text_corpus <- tm_map(tweet_text_corpus, function(x)removeWords(x,stopwords()))
    
    wordcloud(tweet_text_corpus,min.freq=3,scale=c(5,1),colors=RColorBrewer::brewer.pal(6, "Dark2"))
  })


  
})