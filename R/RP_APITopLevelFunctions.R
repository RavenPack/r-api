
###################################
##### HIGHER LEVEL FUNCTIONS  #####
###################################
#################
# DOWNLOAD FILE #
#################
#' @title RP_APIDownloadFile
#' @description  Downloads a request file
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param statusInfo Request status coming from RP_APICheckFileAvailability().
#' @param outputFile Output filename.
#' @return TRUE if the download was successful. FALSE otherwise.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIDownloadFile = function(APIHandler, statusInfo, outputFile) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }
  if (missing(outputFile)) {
    stop("You need to provide an outputfile.")
  }

  if (missing(statusInfo)) {
    stop("You need to provide a valid StatusInfo")
  }
  if (statusInfo$STATUS !='completed') {
    stop("The Request status is not complete. Please check its availability using RP_APICheckFileAvailability()")
  }

  tryCatch({

    Res = httr::GET(url = statusInfo$URL,
                    httr::add_headers(api_key = APIHandler$APIKEY,
                                      accept = "application/json",
                                      content_type = "application/json"),
                    httr::write_disk(outputFile, overwrite=TRUE), httr::progress())

  }, error = function(cond) {

    stop(paste("An error ocurred while downloading the file.", cond))

  })

  return(Res$status_code==200)
}
