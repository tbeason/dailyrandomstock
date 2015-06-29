####server.r
library(shiny)
library(dygraphs)
library(Quandl)
library(PerformanceAnalytics)
library(stringr)
library(xts)

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
    write.csv(Quandl(newStock[[1]],start_data='2005-01-01'),file='stockDataFile.csv',row.names=FALSE)
  })
  
  observeEvent(as.numeric(Sys.time()),{
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
    pri <- as.numeric(closePrices()[length(closePrices())-252:length(closePrices())])
    m<-max(pri,na.rm=TRUE)
    round(m,2)
  })
  
  yrLo <- reactive({
    pri <- as.numeric(closePrices()[length(closePrices())-252:length(closePrices())])
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
      dyOptions(colors = RColorBrewer::brewer.pal(4, "Set2")) %>%
      dyHighlight(highlightCircleSize = 5, 
                  highlightSeriesBackgroundAlpha = 0.2,
                  hideOnMouseOut = FALSE) %>%
      dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
      dyLegend(width = 400) %>%
      dyRangeSelector(dateWindow = c(start(series), end(series)))
  })
  
  
  


  
})






#   stockData <- reactive({
#     Quandl(quandl_code(),type="xts")
#   })
