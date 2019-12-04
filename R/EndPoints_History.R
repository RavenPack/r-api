##########################
# FULL HISTORY ENDPOINTS #
##########################

#' @title RP_APIFullHistory
#' @description Download a list of files containing the full RavenPack Analytics archive.
#' This option is normally used for bulk loading the archive into a database.
#' Files listed are yearly zip files containing monthly CSV files, up to the end of the prior month, relative to today.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @return The output of the call will be an array of objects listing the files available.
#' @import httr
#' @export
#' @author Maria Gomez
RP_APIFullHistory = function( APIHandler ) {

  # Parameter checking
  if ( missing( APIHandler) ) {
    stop("You have to provide a valid APIHandler.")
  }


  # Query API
  url_history = paste0( APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT, 'history/full' )

  res = httr::GET( url = url_history,
                   httr::add_headers( api_key = APIHandler$APIKEY,
                                      accept = "application/json",
                                      content_type = "application/json"),
                   encode = "json"
                   )

  return(res)
}



#' @title RP_APIFullHistoryCompanies
#' @description Download a list of files containing the RavenPack Analytics archive for company-only data.
#' This option is normally used for bulk loading the archive into a database.
#' Files listed are yearly zip files containing monthly CSV files, up to the end of the prior month, relative to today.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @return The output of the call will be an array of objects listing the files available.
#' @import httr
#' @export
#' @author Maria Gomez
RP_APIFullHistoryCompanies = function( APIHandler ) {

  # Parameter checking
  if ( missing( APIHandler) ) {
    stop("You have to provide a valid APIHandler.")
  }


  # Query API
  url_history = paste0( APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT, 'history/companies' )

  res = httr::GET( url = url_history,
                   httr::add_headers( api_key = APIHandler$APIKEY,
                                      accept = "application/json",
                                      content_type = "application/json"),
                   encode = "json"
  )

  return(res)
}



