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
  
  tabPanel("Summary", icon = icon("info-circle"),
    h3(textOutput('sum1'))
    ),
  tabPanel("Price Plot", icon = icon("line-chart"),
    dygraphOutput('dygraphPrice')
  ),
  tabPanel("Volume Plot", icon = icon("bar-chart"),
    dygraphOutput('dygraphVol')
    ),
  tabPanel("Wordcloud", icon = icon("cloud"),
    h3("Still working")     
    )
  

))