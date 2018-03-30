#
# (Acid-base) Titration curve plotter
#

library(shiny)
library(titrationCurves)

# Frontend ---
ui <- fluidPage(
  # Title ---
  titlePanel("TitrationCuRve"),
  
  # Layout ---
  sidebarLayout(
    # Sidebar panel for inputs ---
    sidebarPanel(
      # Input: ---
      #   analyte: 
      #     * pKa or pKb
      #     * concentration
      #     * volume
      #   titrant:
      #     * pKa or pKb
      #     * concentration
      #   Kw
      h2("Analyte (acid)"),
      h2("Titrant (base)"),
      h2("Other settings")
    ),
    
    # Main panel for displaying outputs ---
    mainPanel(
      # Output: ---
      #   Titration curve, pH against volume of titrant added
      plotOutput(
        outputId = "distPlot"
      )
    )
  )
)

# Backend ---
server <- function(input, output) {
  output$distPlot <- renderPlot({
    sa_sb()  # placeholder
  })
}

shinyApp(ui = ui, server = server)
