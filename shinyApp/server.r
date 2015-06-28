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
    write.csv(Quandl(newStock[[1]]),file='stockDataFile.csv',row.names=FALSE)
  })
  
  observeEvent(as.numeric(Sys.time()),{
    library(ReporteRs)
    mydoc <- bsdoc(title ='Random Stock of the Day')
    mydoc <- addTitle(mydoc,'Random Stock of the Day',level=2)
    prop1 <- textProperties(font.size=12)
    prop2 <- textProperties(font.size=12,font.weight='bold',color='#1163A5')
    text1 <- pot('Today\'s random stock is ',prop1) + pot(fullName(),prop2)
    text2 <- pot('They trade under the symbol ',prop1) + pot(symbol(),prop2)
    text3 <- pot('Last open: ',prop1) + pot(lastOpen(),prop2)
    text4 <- pot('Last close: ',prop1) + pot(lastClose(),prop2)
    text5 <- pot('52-week High: ',prop1) + pot(lastClose(),prop2)
    text6 <- pot('52-week Low: ',prop1) + pot(lastClose(),prop2)
    text7 <- pot('1-month Average Daily Volume: ',prop1) + pot(lastClose(),prop2)
    my.pars = set_of_paragraphs( text1,text2,text3,text4,text5,text6,text7 )
    mydoc <- addParagraph(mydoc, my.pars)
    writeDoc(mydoc, file="stockSummary.html")
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
    stockData()$'Adj..Close'
  })
  
  lastClose <- reactive({
    as.numeric(stockData()$'Adj..Close'[end(stockData())])
  })
  
  lastOpen <- reactive({
    as.numeric(stockData()$'Adj..Open'[end(stockData())])
  })
  
  volume <- reactive({
    stockData()$'Adj..Volume'
  })
  
  output$dygraphPrice <- renderDygraph({
    series <- merge(closePrices(),volume())
    series[,2] <- as.numeric(series[,2])/1000000
    dygraph(series, main = paste(symbol(),"Price & Volume History")) %>%
      dySeries('Adj..Volume',axis='y2') %>%
      dyAxis('y',label="Stock Price (USD)") %>%
      dyAxis('y2',label="Volume (in Millions of shares)") %>%
      dyOptions(colors = RColorBrewer::brewer.pal(4, "Set2"),labelsKMB=TRUE) %>%
      dyHighlight(highlightCircleSize = 5, 
                  highlightSeriesBackgroundAlpha = 0.2,
                  hideOnMouseOut = FALSE) %>%
      dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
      dyLegend(width = 400) %>%
      dyRangeSelector(dateWindow = c(start(series), end(series)))
  })
  
  output$sum1 <- renderText({
    paste("Today's stock is", todayStock()[[2]],".")
  })
  
  output$sum2 <- renderText({
    paste("They are listed under the symbol", symbol(),".")
  })
  
  
  


  
})






#   stockData <- reactive({
#     Quandl(quandl_code(),type="xts")
#   })
