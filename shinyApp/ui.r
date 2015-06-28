####ui.r
library(shiny)
library(dygraphs)
library(Quandl)
library(PerformanceAnalytics)
library(stringr)
library(xts)

# Define UI for miles per gallon application
shinyUI(navbarPage(
  
  # Application title
  title="The Breakdown",
  
  tabPanel("Price Plot",
    dygraphOutput('dygraphPrice')
    ),
  tabPanel("Volume Plot",
    dygraphOutput('dygraphVol')
    ),
  tabPanel("Wordcloud",
    h3("Still working")     
    )
  

))