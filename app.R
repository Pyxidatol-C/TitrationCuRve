#
# (Acid-base) Titration curve plotter
#

library(shiny)
library(stringr)
library(titrationCurves)


# Chemistry ----
strong.acids <- data.frame(
  # "3 important strong acids" given by Mr. Thompson
  name = c(
    "Hydrochloric acid",
    "Sulfuric acid",  # TODO diprotic impacts pH?
    "Nitric acid"
  ),

  formula = c(
    "HCl",
    "H2SO4",
    "HNO3"
  )
)

weak.acids <- data.frame(
  # IB chemistry data booklet (version 2, 2014) table 21
  name = c(
    # Carboxylic acids
    "Methanoic acid",
    "Ethanoic acid",
    "Propanoic acid",
    "Butanoic acid",
    "2-Methylpropanoic acid",
    "Pentanoic acid",
    "2,2-Dimethylpropanoic acid",
    "Benzoic acid",
    "Phenylethanoic acid",

    # Halogenated carboxylic acids
    "Chloroethanoic acid",
    "Dichloroethanoic acid",
    "Trichloroethanoic acid",
    "Fluoroethanoic acid",
    "Bromoethanoic acid",
    "Iodoethanoic acid",

    # Phenols
    "Phenol",
    "2-Nitrophenol",
    "3-Nitrophenol",
    "4-Nitrophenol",
    "2,4-Dinitrophenol",
    "2,4,6-Trinitrophenol",

    # Alcohols
    "Methanol",
    "Ethanol"
  ),

  formula = c(
    # Carboxylic acids
    "HCOOH",
    "CH3COOH",
    "CH3CH2COOH",
    "CH3(CH2)2COOH",
    "(CH3)2CHCOOH",
    "CH3(CH2)3COOH",
    "(CH3)3CCOOH",
    "C6H5COOH",
    "C6H5CH2COOH",

    # Halogenated carboxylic acids
    "CH2ClCOOH",
    "CHCl2COOH",
    "CCl3COOH",
    "CH2FCOOH",
    "CH2BrCOOH",
    "CH2ICOOH",

    # Phenols
    "C6H5OH",
    "O2NC6H4OH",
    "O2NC6H4OH",
    "O2NC6H4OH",
    "(O2N)2C6H3OH",
    "(O2N)3C6H2OH",

    # Alcohols
    "CH3OH",
    "C2H5OH"
  ),

  pKa = c(
    # Carboxylic acids
    3.75,
    4.76,
    4.87,
    4.83,
    4.84,
    4.83,
    5.03,
    4.20,
    4.31,

    # Halogenated carboxylic acids
    2.87,
    1.35,
    0.66,
    2.59,
    2.90,
    3.18,

    # Phenols
    9.99,
    7.23,
    8.36,
    7.15,
    4.07,
    0.42,

    # Alcohols
    15.5,
    15.5
  )
)

strong.bases <- data.frame(
  # "Three strong bases for IB" given by Mr. Thompson
  name = c(
    "Sodium hydroxide",
    "Potassium hydroxide",
    "Barium hydroxide"  # TODO diprotic impacts HP?
  ),

  formula = c(
    "NaOH",
    "KOH",
    "Ba(OH)2"
  )
)

weak.bases <- data.frame(
  # IB chemistry data booklet (version 2, 2014) table 21
  # TODO which ones are diprotic?
  name = c(
    # Amines
    "Ammonia",
    "Methylamine",
    "Ethylamine",
    "Dimethylamine",
    "Trimethylamine",
    "Diethylamine",
    "Triethylamine",
    "Phenylamine"
  ),

  formula = c(
    # Amines
    "NH3",
    "CH3NH2",
    "CH3CH2NH2",
    "(CH3)2NH",
    "(CH3)3N",
    "(C2H5)2NH",
    "(C2H5)3N",
    "C6H5NH2"
  ),

  kPb = c(
    4.75,
    3.34,
    3.35,
    3.27,
    4.20,
    3.16,
    3.25,
    9.13
  )
)


# Frontend ----
ui <- fluidPage(
  # Title ---
  titlePanel("TitrationCuRve"),

  # Layout ----
  sidebarLayout(
    # Sidebar panel for inputs ---
    sidebarPanel(
      # Input: ---

      div(
        # Analyte ---
        # * pKa or pKb (not required for strong acid or strong base)
        # * concentration
        # * volume
        h2("Analyte"),

        selectInput(
          inputId = "analyteName",
          label = "Name",
          choices = c(
            as.character(strong.acids$name),
            as.character(weak.acids$name),
            as.character(strong.bases$name),
            as.character(weak.bases$name)
          ),
          selected = "Hydrochloric acid"
        ),

        htmlOutput("analyteFormula"),
        textOutput("analytePk"),

        numericInput(
          inputId = "analyteConcentration",
          label = "Concentration (M)",
          value = 0.1,
          min = 0.1,
          step = 0.1
        ),

        numericInput(
          inputId = "analyteVolume",
          label = "Volume (mL)",
          value = 20,
          min = 1,
          step = 1
        )
      ),

      div(
        # Titrant ---
        # * pKb or pKb (not required for strong acid or strong base)
        # * concentration
        h2("Titrant"),

        selectInput(
          inputId = "titrantName",
          label = "Name",
          choices = c(
            as.character(strong.acids$name),
            as.character(weak.acids$name),
            as.character(strong.bases$name),
            as.character(weak.bases$name)
          ),
          selected = "Sodium hydroxide"
        ),

        htmlOutput("titrantFormula"),
        textOutput("titrantPk"),

        numericInput(
          inputId = "titrantConcentration",
          label = "Concentration",
          value = 0.1,
          min = 0.1,
          step = 0.1
        )
      ),

      div(
        # Other ---
        # * pKw
        h2("Other settings"),
        numericInput(
          inputId = "kw",
          label = "Kw / 1E-14",
          value = 1.00,
          min =  0.1,
          step = 0.1
        )
      ),

      # Submit button ---
      actionButton(
        inputId = "submit",
        label = "Submit"
      )
    ),


    # Main panel for displaying outputs ---
    mainPanel(
      # Output: ---
      #   Titration curve, pH against volume of titrant added
      plotOutput(
        outputId = "pHCurvePlot"
      )
    )
  )
)


# Backend ----
displayPk <- function(name) {
  # Display the pKa or the pKb of the acid or base.
  # 
  # Input
  #   name: (character) The name of the acid or base.
  # 
  # Output
  #   (character) Information about the dissociation constant to display on the website.
  #   for example: "pKa: 4.73"
  if (name %in% weak.acids$name) {
    paste("pKa:", weak.acids$pKa[weak.acids$name == name])
  } else if (name %in% weak.bases$name) {
    paste("pKb:", weak.bases$kPb[weak.bases$name == name])
  }
  # Else, display nothing for strong acids and strong bases
}


getFormula <- function(name) {
  # Get the formula of the acid or base.
  # 
  # Input
  #   name: (character) The name of the acid or base.
  #   for example: "Sulfuric acid"
  #
  # Output
  #   (character) The chemical formula of the acid or base.
  #   for example: H2SO4
  for (category in list(strong.acids, weak.acids, strong.bases, weak.bases)) {
    if (name %in% category$name) {
      return(as.character(category$formula[category$name == name]))
    }
  }
}


displayFormula <- function(formula) {
  # Display the chemical formula.
  # 
  # Input
  #   formula: (character) The chemical formula.
  #   for example: "H2O"
  # 
  # Output
  #   (character) The HTML for chemical formula formatted with subscripts. 
  #   for example: "H<sub>2</sub>O"
  gsub("(\\d+)", "<sub>\\1</sub>", formula)
}


server <- function(input, output, session) {
  output$analytePk <- renderText(displayPk(input$analyteName))
  output$titrantPk <- renderText(displayPk(input$titrantName))
  output$analyteFormula <- renderUI(HTML(displayFormula(getFormula(input$analyteName))))
  output$titrantFormula <- renderUI(HTML(displayFormula(getFormula(input$titrantName))))
  observeEvent(input$submit, {
    pKw <- -log10(input$kw * 1e-14)
    if (input$analyteName %in% strong.acids$name && input$titrantName %in% strong.bases$name) {
      output$pHCurvePlot <- renderPlot({
        sa_sb(
          conc.acid = input$analyteConcentration,
          vol.acid = input$analyteVolume,
          conc.base = input$titrantConcentration,
          pkw = pKw,
          eqpt = TRUE
        )
      })
    } else if (input$analyteName %in% strong.bases$name && input$titrantName %in% strong.acids$name) {
      output$pHCurvePlot <- renderPlot({
        sb_sa(
          conc.base = input$analyteConcentration,
          vol.base = input$analyteVolume,
          conc.acid = input$titrantConcentration,
          pkw = pKw,
          eqpt = TRUE
        )
      })
    } else if (input$analyteName %in% weak.acids$name && input$titrantName %in% strong.bases$name) {
      output$pHCurvePlot <- renderPlot({
        wa_sb(
          conc.acid = input$analyteConcentration,
          vol.acid = input$analyteVolume,
          pka = weak.acids$pKa[weak.acids$name == input$analyteName],
          conc.base = input$titrantConcentration,
          pkw = pKw,
          eqpt = TRUE
        )
      })
    } else if (input$analyteName %in% weak.bases$name && input$titrantName %in% strong.acids) {
      output$pHCurvePlot <- renderPlot({
        wb_sa(
          conc.base = input$analyteConcentration,
          vol.base = input$analyteVolume,
          pka = pKw - weak.bases$kPb[weak.bases$name == input$analyteName],
          conc.acid = input$titrantConcentration,
          pkw = pKw,
          eqpt = TRUE
        )
      })
    } else {
      # TODO display error
      print("Nope")
    }
  })
}


# Run app ----
shinyApp(ui = ui, server = server)
