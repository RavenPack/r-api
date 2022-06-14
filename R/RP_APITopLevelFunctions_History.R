
#########################
# DOWNLOAD FULL HISTORY #
#########################
#' @title RP_APIDownloadFullHistory
#' @description This function downloads the full archive of RavenPack Analytics.
#' This function is normally used for bulk loading the archive into a database.
#' Files downloaded are yearly zip files containing monthly CSV files, up to the end of the prior month, relative to today.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param outFolderPath The local folder to store the downloaded archive files.
#' @param onlyCompany TRUE as default. Whether to download only analytics for companies or for all type of entities. This parameter will only be used on 'rpa' product.
#' @param flatfile_package Unique identifier for the flat-file package. Only required for 'edge' product.
#' @return TRUE if the operation succeeds. An ERROR otherwise.
#' As output a set of zip files will be downloaded in the output folder indicated as parameter.
#' @author Maria Gomez
#' @export
#' @import httr
#' @import jsonlite
RP_APIDownloadFullHistory = function( APIHandler, outFolderPath = "~/Downloads", onlyCompany = TRUE, flatfile_package = NULL ) {

  # Parameter checking
  if ( missing( APIHandler) ) {
    stop("You have to provide a valid APIHandler.")
  }

  if( APIHandler$PRODUCT == 'edge' & (is.null(flatfile_package) | missing(flatfile_package)) ){
    stop("A flatfile_package identifier is required with 'edge' product.")
  }

  outFolderPath = paste0( outFolderPath, "/history" )
  if( !dir.exists(outFolderPath) ) {
      dir.create( outFolderPath, recursive = T)
  }


  # Query endpoint
  if( APIHandler$PRODUCT == 'edge' ) {
    if( !missing(onlyCompany) ){
      warning("Parameter 'onlyCompany' is ignored. The parameter is only used on 'rpa' product.")
    }
    res = RP_APIFullHistory( APIHandler, flatfile_package )

    } else if(APIHandler$PRODUCT == 'rpa'){
      if( onlyCompany ) {
        res = RP_APIFullHistoryCompanies( APIHandler )
      } else{
        res = RP_APIFullHistory( APIHandler )
      }
  }


  # Check query status
  checkAPIResponse( res$status_code )

  # Read query results
  resStr = httr::content(res, as = 'text', encoding = 'UTF-8')
  filesList = jsonlite::fromJSON(resStr)

  # Download single .zip files
  url_history = res$url
  for( i in 1:nrow(filesList) ) {

    tryCatch( {
      analyticsFileName = filesList[i,]$id
      message( paste0("Downloading ", analyticsFileName, "...") )
      downloadAnalyticsFile( url_history, analyticsFileName, outFolderPath )
    },
    error = function(e) {
      stop( paste0("Error downloading file ", analyticsFileName, " from ", url_history, "\n",e) )
    })
  }

  return(TRUE)
}



##############################
# INTERNAL FUNCTIONS         #
##############################

#' @title downloadAnalyticsFile
#' @description Internal function to download files from a RavenPack end-point.
#' @param url Url of a RavenPack endpoint.
#' @param analyticsFileName Name of the file to download from the endpoint.
#' @param outFolder The local folder to store the downloaded files.
#' @return TRUE if the operation succeeds. An ERROR otherwise.
#' @export
#' @author Maria Gomez
downloadAnalyticsFile = function( url, analyticsFileName, outFolder ) {

  res = httr::GET( url = paste0( url, "/",analyticsFileName ),
                   httr::add_headers(api_key = APIHandler$APIKEY,
                                    accept = "application/json",
                                    content_type = "application/json"),
                  encode = "json" ,
                  httr::write_disk( paste0( outFolder, "/", analyticsFileName ), overwrite = T), httr::progress() )

  checkAPIResponse(res$status_code)

  return(TRUE)
}



#' @title checkAPIResponse
#' @description Internal function to check the status of responses from endpoints.
#' @param statusCode The status code contained in the endpoint response.
#' @return It throws an ERROR if the status code corresonds to an error code.
#' It prints a message if the status code corresponds to a successfull code.
#' @export
#' @author Maria Gomez
checkAPIResponse = function( statusCode ) {
  switch( toString(statusCode),
          '200' = { print("API query successfull") },
          '403' = { stop("Unauthorized to query API") },
          stop( paste0("Unknown error querying API. Status code: ", statusCode) )
  )
}




