
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


##################################
# DOWNLOAD FILE WHEN IT IS READY #
##################################
#' @title RP_APIDownloadFileWhenReady
#' @description Downloads a request file when it is ready.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param token A string that identifies the request.
#' @param outputFile Output filename
#' @param timeout: time (in seconds) to wait for download
#' @author Maria Gomez
#' @export
RP_APIDownloadFileWhenReady = function ( APIHandler, token, outputFile, timeout ) {

  # Wait until job is completed
  status = RP_APIWaitForJobCompletion(APIHandler = APIHandler, token = token, timeout = timeout)

  if(status$STATUS == 'completed') {

    RP_APIDownloadFile(APIHandler = APIHandler, statusInfo = status$STATUSINFO, outputFile = outputFile)
    print( 'File successfully downloaded!' )
  }

  else {
    print( paste0('Error downloading the file. Error message: ', status$STATUS) )
  }
}


##################################
###   WAIT JOB COMPLETION      ###
##################################
#' @title RP_APIWaitForJobCompletion
#' @description Waits until the request file is available to download
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param token A string that identifies the request.
#' @param timeout Time (in seconds) to wait.
#' @return The final status of the job. A list containg two values:
#'          STATUS (String defining the final status: 'completed', 'error' or 'timeout'), and
#'          STATUSINFO status object coming from RP_APICheckFileAvailability().
#' @author Maria Gomez
#' @export
RP_APIWaitForJobCompletion = function ( APIHandler, token, timeout = 60) {

  waitTime = 10 # Waiting time (in seconds) between checks
  status = RP_APICheckFileAvailability(APIHandler = APIHandler, token = requestToken$TOKEN)
  currentStatus = status$STATUS

  # Check if polling is needed (status 'enqueued' or 'processing')
  if ( currentStatus %in% c('enqueued','processing') ) {
    # We get the number of iterations
    pollIterations = ceiling(timeout/waitTime)
    iteration = 1

    while ( (currentStatus %in% c('enqueued','processing')) & iteration<=pollIterations) {
      # Wait
      Sys.sleep(waitTime)
      print(paste("Check",iteration,"out of",pollIterations,"..."))

      status = RP_APICheckFileAvailability(APIHandler = APIHandler, token = requestToken$TOKEN)
      currentStatus = status$STATUS
      iteration = iteration + 1
    }
  }

    # Check Status
    if (currentStatus == 'completed') {
      result = 'completed'
    } else if (currentStatus == 'error') {
      result = 'error'
    } else if (currentStatus == 'cancelled') {
      result = 'cancelled'
    } else {
      result =  paste0(currentStatus,'_TIMEOUT')
    }

  print(result)

  return ( list(STATUS = result, STATUSINFO = status))
}

