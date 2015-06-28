####ui.r
library(shiny)
library(dygraphs)
library(Quandl)
library(PerformanceAnalytics)
library(stringr)
library(xts)

# Define UI for miles per gallon application
shinyUI(navbarPage(theme="bootstrap.css",
  
  # Application title
  title="The Breakdown",
  
  tabPanel("Summary", icon = icon("info-circle"),
    sidebarLayout(
      sidebarPanel(includeMarkdown("summary.md")),      
      mainPanel(width=6,
        includeHTML("stockSummary.html")
        )
      
      )
           
    ),
  tabPanel("Chart", icon = icon("line-chart"),
    dygraphOutput('dygraphPrice'),
    "Performance of the chart may decrease for large time windows."
  ),
  tabPanel("Performance", icon = icon("flag-checkered"),
           h3("Still working") 
  ),
  tabPanel("Wordcloud", icon = icon("cloud"),
    h3("Still working")     
    )
  

))