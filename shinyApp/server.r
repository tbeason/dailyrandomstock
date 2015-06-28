####server.r
library(shiny)
library(dygraphs)
library(Quandl)
library(PerformanceAnalytics)
library(stringr)
library(xts)

symbolList <- reactiveFileReader(86400000,NULL,'https://s3.amazonaws.com/quandl-static-content/Ticker+CSV%27s/WIKI_tickers.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)
stockDataFile <- reactiveFileReader(10000,NULL,'stockDataFile.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)
stockNameFile <- reactiveFileReader(10000,NULL,'stockNameFile.csv',read.csv,stringsAsFactors=FALSE,header=TRUE)

# Define server logic
shinyServer(function(input, output) {
  
  # grabs new random stock data on Date change
  observeEvent(Sys.Date(),{
    set.seed(floor(as.numeric(Sys.Date())))
    rand <- sample(1:nrow(symbolList()),1)
    newStock <- symbolList()[rand,]
    write.csv(newStock,file='stockNameFile.csv',row.names=FALSE)
    write.csv(Quandl(newStock[[1]]),file='stockDataFile.csv',row.names=FALSE)
  })
  
  checkFun1 <- function()
  {
    Sys.Date()
  }
  valueFun1 <- function()
  {
    as.xts(stockDataFile(),order.by=as.Date(stockDataFile()[,1]))
  }
  stockData <- reactivePoll(10000,NULL, checkFun1, valueFun1)
  
  checkFun2 <- function()
  {
    stockNameFile()
  }
  valueFun2 <- function()
  {
    unlist(stockNameFile())
  }
  todayStock <- reactivePoll(10000,NULL, checkFun1, valueFun2)
  
  quandl_code <- reactive({
    todayStock()[[1]]
  })

  symbol <- reactive({
    str_sub(quandl_code(),6,-1)
  })
  
  output$ticker <- renderText({
    symbol()
  })
  
  output$fullName <- renderText({
    todayStock()[[2]]
  })
  

  closePrices <- reactive({
    stockData()$'Adj..Close'
  })
  
  output$lastClose <- renderText({
    as.numeric(stockData()$'Adj..Close'[end(stockData())])
  })
  
  output$lastOpen <- renderText({
    as.numeric(stockData()$'Adj..Open'[end(stockData())])
  })
  
  volume <- reactive({
    stockData()$'Adj..Volume'
  })
  
  output$dygraphPrice <- renderDygraph({
    dygraph(closePrices(), main = paste(symbol(),"Price History")) %>% 
      dyRangeSelector(dateWindow = c(start(closePrices()), end(closePrices())))
  })

  output$dygraphVol <- renderDygraph({
    dygraph(volume(), main = paste(symbol(),"Volume History")) %>% 
      dyRangeSelector(dateWindow = c(start(volume()), end(volume())))
  })
  
  output$sum1 <- renderText({
    paste("Today's stock is", symbol())
  })
  


  
})






#   stockData <- reactive({
#     Quandl(quandl_code(),type="xts")
#   })
