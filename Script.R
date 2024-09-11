projectName <- "ohdsiPlDme"
baseFolder <- file.path("E:", "studyResults", projectName)
dir.create(path = baseFolder,
           showWarnings = FALSE,
           recursive = TRUE)

activeProjectFolder <- rstudioapi::getActiveDocumentContext()$path |> dirname()

ohdsiPlDmeCohortIds <- c(
  207,
  210,
  211,
  # 213,deprecated
  216,
  218,
  219,
  222,
  229,
  275,
  276,
  720,
  723,
  724,
  725,
  726,
  727,
  728,
  729,
  730,
  731,
  732,
  733,
  735,
  736,
  737,
  739,
  741,
  747,
  1316
) |> sort() |> unique()



ROhdsiWebApi::authorizeWebApi(
  baseUrl = "https://atlas-phenotype.ohdsi.org/WebAPI",
  authMethod = "db",
  webApiUsername = Sys.getenv('ohdsiAtlasPhenotypeUser'),
  webApiPassword = Sys.getenv('ohdsiAtlasPhenotypePassword')
)


#get cohort definition set----
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(baseUrl = "https://atlas-phenotype.ohdsi.org/WebAPI",
                                                               cohortIds = ohdsiPlDmeCohortIds,
                                                               generateStats = TRUE) |>
  dplyr::select(colnames(CohortGenerator::createEmptyCohortDefinitionSet()))

saveRDS(
  object = cohortDefinitionSet,
  file = file.path(activeProjectFolder, "CohortDefinitionSet.RDS")
)
readr::write_excel_csv(x = cohortDefinitionSet,
                       file = file.path(activeProjectFolder, "CohortDefinitionSet.csv"))

cohortDefinitionSet <- readRDS(file.path(activeProjectFolder, "CohortDefinitionSet.RDS"))

# invoke cohort generation
cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = projectName)


OhdsiHelpers::executeCohortGenerationInParallel(
  cdmSources = cdmSources,
  cohortDefinitionSet = cohortDefinitionSet,
  outputFolder = file.path(baseFolder, "CohortGenerator"),
  cohortTableNames = cohortTableNames
)


OhdsiHelpers::executeCohortDiagnosticsInParallel(
  cdmSources = cdmSources,
  cohortDefinitionSet = cohortDefinitionSet,
  outputFolder = file.path(baseFolder, "CohortDiagnostics"),
  cohortTableNames = cohortTableNames
)

CohortDiagnostics::createMergedResultsFile(
  dataFolder = file.path(baseFolder, "CohortDiagnostics"),
  sqliteDbPath = file.path(baseFolder, "CohortDiagnostics", "MergedCohortDiagnosticsData.sqlite"), 
  overwrite = TRUE
)


CohortDiagnostics::createDiagnosticsExplorerZip(
  outputZipfile = file.path(baseFolder, "CohortDiagnostics", "DiagnosticsExplorer.zip"),
  sqliteDbPath = file.path(
    baseFolder,
    "CohortDiagnostics",
    "MergedCohortDiagnosticsData.sqlite"
  ),
  overwrite = TRUE
)