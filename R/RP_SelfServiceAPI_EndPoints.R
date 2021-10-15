
######################
# CREATE API HANDLER #
######################
#' @title RP_CreateAPIHandler
#' @description This functions creates an API Handler, needed to call all API functions.
#' @param APIKey A valid API Key.
#' @param product 'rpa' as default. The RavenPack product: 'rpa' or 'edge'.
#' @return An API Handler.
#' @author Jose A. Guerrero-Colon, Maria Gomez
#' @export
#' @import httr
#' @import jsonlite
#' @import data.table
RP_CreateAPIHandler = function(APIKey, product = 'rpa') {

  # Check params
  if (missing(APIKey)) {
    stop("Missing APIKey")
  }

  if(!product %in% c('rpa', 'edge')) {
    stop("Unknown product. Only 'rpa' and 'edge' are available.")
  }


  # Create API handler
  env = Sys.getenv('RPServerAPI')
  env = ifelse(env == '', 'PROD', env)

  if(product == 'edge') {
    baseUrl = 'https://api-edge.ravenpack.com/1.0/'
    feedUrl = 'https://feed-edge.ravenpack.com/1.0/'

  } else if (product == 'rpa') {
    baseUrl = switch (env,
                      'STAGING' = 'https://api-staging.ravenpack.com/1.0/',
                      'PREPROD' = 'https://api-pre.ravenpack.com/1.0/',
                      'PROD'    = 'https://api.ravenpack.com/1.0/')

    feedUrl = ifelse(env == 'PROD',
                     'https://feed.ravenpack.com/1.0/',
                     'https://staging-feed.ravenpack.com/1.0/')
  }

  APIHandler = list(APIKEY = APIKey,
                    ENDPOINTS = data.table::data.table(TYPE = c('ASYNC', 'RT'),
                                                       BASE_ENDPOINT = c(baseUrl,
                                                                         feedUrl)),
                    ENV = env)

  return(APIHandler)
}

RP_APIParamsParsing = function (key, value) {

  query = ""
  if (length(value)!=0) {
    query = paste0(key,"=",unlist(value), collapse = '&')
  }
  return(query)

}

######################################################################################
###########################  PRIMITIVE FUNCTIONS  BEGIN   ############################
######################################################################################

####################################
#####   STATUS ENDPOINT BEGINS #####
####################################
##################
# GET API STATUS #
##################
#' @title RP_APIStatus
#' @description Request the status of the server. This endpoint allows you to check that your connection with the server is running correctly and that the server is functioning correctly.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @return The status of the API ("OK" expected)
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIStatus = function(APIHandler) {

  if (missing(APIHandler)) {

    stop("You need to provide a valid APIHandler.")

  }
  url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'status')

  Res = httr::GET(url = url_dataset,
            httr::add_headers(api_key = APIHandler$APIKEY,
                        accept = "application/json",
                        content_type = "application/json"),
            encode = "json")

  # Parsing Results
  ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
  if (jsonlite::validate(ResStr)) {

    status = jsonlite::fromJSON(ResStr)$status

  } else {

    stop(paste("There was an error receiving the httr::content.",ResStr))

  }

  return(status)

}
###################################
#####   STATUS ENDPOINT ENDS  #####
###################################

#####################################
#####   DATASET ENDPOINT BEGINS #####
#####################################
################
# LIST DATASET #
################
#' @title RP_APIListDataSet
#' @description List all available datasets. Get a list of the datasets that you have permission to access. You may filter the list by tags and search for only the list of datasets that have the tags specified, or you may filter by scope, and return only the datasets that are Public to everyone, Shared with you by someone else using RavenPack or Private datasets that were created by you.
#' The list of datasets returns the dataset_uuid and name for each dataset. It is possible to request the full set of information that defines a dataset using the API.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param params A list with the request query parameters.
#' \itemize{ \item{tags: }{Optional. A list of tags that should be used to filter the list of datasets returned.}
#' \item{scope: }{Optional. A list with the desired scope: [public, shared, private (default)]}
#' \item{frequency: }{Optional. A list with the desired  type of dataset: [daily, granular]}}
#' @return A data.table with the datasets.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
#' @import data.table
RP_APIListDataSet = function(APIHandler, params = list()) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }
  paramNames = c('scope','tags','frequency')
  ScopeFields = c('public','shared', 'private')
  # Checking paramenters
  if (length(params)!=0) {
    #
    inputParams = names(params)
    extraParams = setdiff(inputParams, paramNames)
    # We check for not supported parameters
    if (length(extraParams)>0) {

      stop(paste0("Available parameters are: ", paste0(paramNames, collapse = ', '),
                  ". \nNot supported: ",
                  paste0(extraParams, collapse = ', ')))

    } else {
      # Validating
      if (paramNames[1]%in% inputParams) {
        notSupportedValues = setdiff(params$scope, ScopeFields)
        if (length(notSupportedValues)>0) {

          stop(paste0("Scope possible values are: ", paste0(ScopeFields, collapse = ', '),
                      ". \nNot supported: ",
                      paste0(notSupportedValues, collapse = ', ')))

        }
      }

    }
  }
  url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datasets/')
  # Preparing the query of the GET
  query = paste0(
    unlist(lapply(seq_along(params), FUN = function(values,keys,i) {RP_APIParamsParsing(key = keys[[i]], value =values[[i]])}, values = params, keys = names(params))),
    collapse = '&')

  Res = httr::GET(url = url_dataset,
                  httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                  query = URLencode(query),
                  encode = "json")
  # Parsing Results
  ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
  if (jsonlite::validate(ResStr)) {

    serverResponse = jsonlite::fromJSON(httr::content(Res, as = 'text', encoding = 'UTF-8'), flatten = TRUE)
    # We check the server response
    if ("datasets"%in%names(serverResponse)) {

      datasets = serverResponse$datasets
      if (length(datasets)!=0) {
        # We have to remove Nulls
        datasets$tags = lapply(datasets$tags, function(x) ifelse(is.null(x), NA, x))

        results = data.table::data.table(UUID = datasets$uuid,
                                         NAME = datasets$name,
                                         TAGS = datasets$tags,
                                         CREATION_TIME = datasets$creation_time)
      } else {
        print("No datasets found.")
        results = data.table::data.table()
      }
    } else {
      results = serverResponse
    }
  } else {

    stop(paste("There was an error receiving the httr::content.", ResStr))
  }
  return(results)

}

##################
# CREATE DATASET #
##################
#' @title RP_APICreateDataSet
#' @description Creates a dataset. This endpoint allows you to create a new dataset definition on ravenpack.com.
#' A dataset allows you to query a subset of RavenPack data by specifying filters and fields available in RavenPack Analytics.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param payload A string in JSON format with the request body parameters. See the RavenPack Analytics User Guide for more details on the fields in RavenPack Analytics data.
#' @return A dataset_uuid identifying the created dataset.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APICreateDataSet = function(APIHandler, payload) {

  datasetUUID = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }

  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datasets/')

    Res = httr::POST(url = url_dataset,
               httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
               body =  payload,
               encode = "json")
    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      results = jsonlite::fromJSON(ResStr)
      if ("dataset_uuid"%in% names(results)) {

        datasetUUID = results$dataset_uuid

      } else {

        datasetUUID = results

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(datasetUUID)
}

###############
# GET DATASET #
###############
#' @title RP_APIGetDataSet
#' @description Retrieves a dataset information. Provides the full specification for a single dataset
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param datasetUUID A string with the dataset identifier.
#' @return The dataset information in JSON format.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetDataSet = function(APIHandler, datasetUUID) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }

  url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datasets/',datasetUUID)

  Res = httr::GET(url = url_dataset,
             httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
             encode = "json")
  # Parsing Results
  ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
  if (jsonlite::validate(ResStr)) {

    dataset = jsonlite::toJSON(ResStr)

  } else {

    stop(paste("There was an error receiving the httr::content.", ResStr))

  }

  return(dataset)
}

##################
# DELETE DATASET #
##################
#' @title RP_APIDeleteDataSet
#' @description Deletes a dataset.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param datasetUUID A string with the dataset identifier to delete.
#' @return A list with the delete results if the dataset was successfully deleted. An Error otherwise.
#' The delete results contains a 'message' field.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIDeleteDataSet = function(APIHandler, datasetUUID) {

  # Parameter checking
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }

  # Request
  url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datasets/',datasetUUID)

  Res = httr::DELETE(url = url_dataset,
               httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
               encode = "json")

  # Parsing Results
  ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
  deleteResults = jsonlite::fromJSON(ResStr)

  if( Res$status_code == 200 ) {
    print( deleteResults$message )
  } else {
    stop( deleteResults$errors )
  }

  return( deleteResults )
}


##################
# MODIFY DATASET #
##################
#' @title RP_APIModifyDataSet
#' @description Modify an existing dataset on ravenpack.com. When modifying a dataset, it is possible to provide just the parameters that you wish to modify.
#' Any parameters that are not included in the request will retain their value and will not be modified.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier to modify.
#' @return TRUE if the dataset was successfully deleted. An error message otherwise.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIModifyDataSet = function(APIHandler, payload, datasetUUID) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_dataset = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datasets/',datasetUUID)

    Res = httr::PUT(url = url_dataset,
              httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
              body = payload,
              encode = "json")
    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("dataset_uuid"%in% names(serverResponse)) {

        print(paste("Dataset", datasetUUID, "successfully modified."))
        datasetUUID = serverResponse$dataset_uuid

      } else {

        datasetUUID = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

 return(datasetUUID)

}
#####################################
#####   DATASET ENDPOINT ENDS   #####
#####################################


########################################
#####  ANALYTICS ENDPOINT BEGINS  ######
########################################

##################
# SUSCRIBE TO RT #
##################
#' @title RP_APISubscribeRT
#' @description Subscribes to real-time analytics.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param datasetUUID A string with the dataset identifier to subscribe.
#' @param funPath The path to an R function to process the stream. Bear in mind the data will be passed from a
#' curl call using a pipe. Something like: curl -s -H \"api-key:XXX\" \"https://feed.ravenpack.com/1.0/json/<datasetUUID>\" | R -f funPath
#' As a function example:
#' "f <- file("stdin")
#' open(f)
#' while(length(line <- readLines(f,n=1)) > 0) \{
#' write(line, stderr())
#' print(line)
#' # do any other process
#' \}"
#' @return A stream of JSON objects separated by '\\n'
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APISubscribeRT = function(APIHandler, datasetUUID, funPath) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  if (missing(funPath)) {
    stop("You need to provide a proper R function.")
  }
   #THIS ENDPOINT IS DIFFERENT ON STAGING
   # url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'RT']$BASE_ENDPOINT,'json/',datasetUUID)

  host = paste0(APIHandler$ENDPOINTS[TYPE == 'RT']$BASE_ENDPOINT,'json/',datasetUUID)
  # Using an external function
  curlCall = paste0("curl -s -H \"api-key:",APIHandler$APIKEY,"\" \"",host,"\" | R -f \"",funPath,"\"")

  A = system(curlCall, intern = TRUE)
  return(A)

}

##################
# COUNT DATASET #
##################
#' @title RP_APIGetDataFileCount
#' @description Gets the count of the dataset for a time range described on payload. The datafile count endpoint allows you to find out how many rows a particular datafile will contain before actually generating it.
#' In general it is a good idea to use this in order to determine if a particular datafile will be too large and will need to be broken up into smaller subsets.
#' Please note: When requesting a count for a dataset defined with granular frequency, the count will be an exact count of the records that match in the time-range specified. When requesting a count for a dataset defined with daily frequency, the count is an estimate and has a margin of error typically less then 1%, varying with the size of the dataset.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier.
#' @return The count.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetDataFileCount = function(APIHandler, payload, datasetUUID) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    #THIS ENDPOINT IS NOT PROPERLY NAMED ON SERVER, IS MISSING / AT THE END.
    url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datafile/',datasetUUID,'/count')

    Res = httr::POST(url = url_datafile,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("count"%in% names(serverResponse)) {

        dataCount = serverResponse$count

      } else {

        dataCount = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(dataCount)

}

#####################
# REQUEST DATAFILE  #
#####################
#' @title RP_APIRequestDataFile
#' @description The datafile endpoint allows a file to be generated for a particular dataset for any period from the year 2000 to present.
#' Data may be retrieved in CSV or Excel format and may be compressed for transmission via HTTP.
#' Note: There is a limitation of 50 million records for generating granular data and 10 million records for aggregated data.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier.
#' @return A list with the request token and the expected time.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIRequestDataFile = function(APIHandler, payload, datasetUUID) {

  dataDump = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'datafile/',datasetUUID)

    Res = httr::POST(url = url_datafile,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("token"%in% names(serverResponse)) {

        dataDump = list(TOKEN = serverResponse$token, ETA = serverResponse$estimated_completion)
        token = serverResponse$token


      } else {

        dataDump = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(dataDump)

}

###########################
# CHECK FILE AVAILABILITY #
###########################
#' @title RP_APICheckFileAvailability
#' @description  Checks the availability of the datafile. After submitting a request to generate a datafile using the datafile endpoint, a token is returned which may be supplied to this endpoint in order to find the status of the datafile generation job.
#' When the job is complete, the status will be updated to completed and the size and URL will be set.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param token A string that identifies the request.
#' @return Information about the status of the request.
#' \itemize{
#' Response parameters:
#' \item{status: } {One of the following: [enqueued, processing, completed, error]}
#' \item{size: } {File size.}
#' \item{url: } {Link to download the file.}
#' \item{checksum: } {Checksum code.}}
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APICheckFileAvailability = function(APIHandler, token) {

  statusInfo = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(token)) {
    stop("You need to provide a valid token")
  }
   url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'jobs/',token)

    Res = httr::GET(url = url_datafile,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      statusInfo = serverResponse
      names(statusInfo) = toupper(names(statusInfo))

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }

  return(statusInfo)
}

##################
# CANCEL REQUEST #
##################
#' @title RP_APICancelRequest
#' @description  Cancels a Request. Only "Enqueued" queries can be cancelled.
#' Please note that if the job has finished, a 404 response will be returned as the job token is no longer valid.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param token A string that identifies the request to be cancelled.
#' @return An informative message.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APICancelRequest = function(APIHandler, token) {

  dataDump = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(token)) {
    stop("You need to provide a valid token")
  }

  url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'jobs/', token)

    Res = httr::DELETE(url = url_datafile,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     encode = "json")
    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("token"%in% names(serverResponse)) {

        dataDump = list(TOKEN = serverResponse$token, ETA= serverResponse$estimated_completion)
        token = serverResponse$token


      } else {

        dataDump = serverResponse
        print(serverResponse)

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }


#############################################
#####  ADHOC QUERIES ENDPOINT BEGINS   ######
#############################################
#######################
# GET DATASET PREVIEW #
#######################
#' @title RP_APIGetDataSetPreview
#' @description Gets a preview from a dataset. Please note: Currently this endpoint only supports datasets with “daily” frequency. The sample will contain up to five entities from the entities supported by the dataset, and a maximum of 10 days per entities.
#' In addition, a rollup for the whole dataset is never returned in the preview.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier to preview.
#' @return A data.table with the preview.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
#' @import data.table
RP_APIGetDataSetPreview = function(APIHandler, payload, datasetUUID) {

  dataResponse = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_preview = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'json/',datasetUUID,'/preview')

    Res = httr::POST(url = url_preview,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("records"%in% names(serverResponse)) {

        dataResponse = data.table::data.table(serverResponse$records)
        setnames(dataResponse,toupper(colnames(dataResponse)))

      } else {

        dataResponse = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(dataResponse)

}

#######################
# GET DATASET JSON #
#######################
#' @title RP_APIGetDataSetJSON
#' @description The JSON dataset endpoint allows data to be requested synchronously and in JSON format. A predefined dataset must be supplied and the fields property may be overriden.
#' Please note: Currently this endpoint only supports datasets with “daily” frequency.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier.
#' @return A data.table with the requested dataset.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite

RP_APIGetDataSetJSON = function(APIHandler, payload, datasetUUID) {

  dataResponse = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  if (missing(datasetUUID)) {
    stop("You need to provide a valid datasetUUID")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_json = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'json/',datasetUUID)

    Res = httr::POST(url = url_json,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("records"%in% names(serverResponse)) {

        dataResponse = data.table::data.table(serverResponse$records)
        setnames(dataResponse,toupper(colnames(dataResponse)))

      } else {

        dataResponse = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(dataResponse)

}


##################
# GET ADHOC JSON #
##################
#' @title RP_APIGetFullAdhocJSON
#' @description The JSON dataset endpoint allows data to be requested synchronously in JSON format and without having previously defined a dataset.
#' The endpoint provides similar parameters to the ones used when creating a dataset so that RavenPack Analytics data can be queried in a more adhoc way.
#' Please note: Currently this endpoint only supports datasets with “daily” frequency.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @param datasetUUID A string with the dataset identifier to preview.
#' @return A data.table with the preview.
#' @details Limitations: will show the top 500 entities (in terms of volume), max lookback window will be 366 days, and max time range will be 366 days.
#' In the case of a timeout, the response will be a generic bad-request HTTP 400 code specifying that the requested data is too large and to split the request into smaller chunks.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetFullAdhocJSON = function(APIHandler, payload) {

  dataResponse = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }

  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_json = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'json/')

    Res = httr::POST(url = url_json,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      if ("records"%in% names(serverResponse)) {

        dataResponse = data.table::data.table(serverResponse$records)
        setnames(dataResponse,toupper(colnames(dataResponse)))

      } else {

        dataResponse = serverResponse

      }

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(dataResponse)

}

###########################################
#####  ADHOC QUERIES ENDPOINT ENDS   ######
###########################################


##############################################
#####  ENTITY MAPPING ENDPOINT BEGINS   ######
##############################################
##########################
# ENTITY MAPPING REQUEST #
##########################
#' @title RP_APIMappingRequest
#' @description The entity-mapping endpoint may be used to map from a universe of entity or security identifiers into RavenPack’s entity universe.
#' One may pass in identifiers such as entity names, listings, ISIN values, CUSIP values, etc. and the endpoint will return the corresponding RP_ENTITY_ID for the possible matches.
#' In the event that the entity mapping API is unable to match the requested entity to an entity in the RavenPack entity universe, there will be no mapped entities and the requested data is returned as an error.
#' In the event that multiple entities are matched, the entities will be returned ranked with a relative score, which may be used to automatically filter or sort for further analysis.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param payload A string in JSON format with the request body parameters.
#' @return A list with the mapping information, upon success. Error information otherwise.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIMappingRequest = function(APIHandler, payload) {

  mappingInfo = NULL
  if (missing(APIHandler)) {
    stop("You have to provide a valid APIHandler.")
  }
  if (missing(payload)) {
    stop("You have to provide a valid payload.")
  }

  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {
    url_entityMap = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'entity-mapping')

    Res = httr::POST(url = url_entityMap,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")
    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      mappingInfo = serverResponse
      names(mappingInfo) = toupper(names(mappingInfo))

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }



  }
  return(mappingInfo)
}

############################################
#####  ENTITY MAPPING ENDPOINT ENDS   ######
############################################

################################################
#####  ENTITY REFERENCE ENDPOINT BEGINS   ######
################################################
###########################
# GET FULL REFERENCE DATA #
###########################
#' @title RP_APIGetReferenceData
#' @description Retrieve an entity reference data file. An entity mapping file contains information pertaining to entities in RavenPack’s entity universe.
#' Files are updated on a daily basis after midnight UTC. It is possible to request a reference data file for a specific entity type by supplying the entity_type parameter.
#' For more information, please see the Reference Service section in the RavenPack Analytics User Guide.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param params A list with the request query parameters.
#' \itemize{\item{entity_type: }{Optional. A single entity type. If not provided all are requested.}}
#' @return An url with a link to the csv file upon success. An http server response otherwise.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetReferenceData = function(APIHandler, params = list()) {

  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (length(params)>0) {

    if (!"entity_type"%in%names(params)) {

      stop("Invalid parameter names. Only 'entity_type' accepted.")
    } else {

      if (length(params)>1) {

        warning("Only considering entity_type, ignoring other parameters.")
        params = params["entity_type"]

      }
    }

  }
  url_entityRef = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'entity-reference')
  # Preparing the query of the GET
  query = paste0(
    unlist(lapply(seq_along(params), FUN = function(values,keys,i) {RP_APIParamsParsing(key = keys[[i]], value =values[[i]])}, values = params, keys = names(params))),
    collapse = '&')

  Res = httr::GET(url = url_entityRef,
                  httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                  query = URLencode(query),
                  encode = "json")
  # Parsing Results
  if (Res$status_code==200) {

    linkToFile = Res$url
  } else {
    linkToFile = Res
  }
  return(linkToFile)

}

########################
# GET ENTITY REFERENCE #
########################
#' @title RP_APIGetEntityReference
#' @description Request reference data for a single entity in RavenPack’s entity universe.
#' It is possible to have more than one value for a particular type of data. This is encoded as separate EntityData objects with possibly different time ranges associated.
#' Please note that it is also normal to have more than one value for a particular type of data over the same time range.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param entity_id A valid RP_ENTITY_ID.
#' @return A list with the mapping information.
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetEntityReference = function(APIHandler, entity_id) {

  entityInfo = NULL
  if (missing(APIHandler)) {
    stop("You have to provide a valid APIHandler.")
  }

  if (missing(entity_id)) {
    stop("You have to provide a valid entity_id. ")
  }


  url_entityRef = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'entity-reference/',entity_id)
  Res = httr::GET(url = url_entityRef,
                  httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                  encode = "json")

  # Parsing Results
  ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
  if (jsonlite::validate(ResStr)) {

    serverResponse = jsonlite::fromJSON(ResStr)
    entityInfo = serverResponse
    names(entityInfo) = toupper(names(entityInfo))

  } else {

    stop(paste("There was an error receiving the httr::content.", ResStr))

  }
  return(entityInfo)

}
##############################################
#####  ENTITY REFERENCE ENDPOINT ENDS   ######
##############################################

########################################
#####  TAXONOMY ENDPOINT BEGINS   ######
########################################
####################
# REQUEST TAXONOMY #
####################
#' @title RP_APITaxonomy
#' @description The RavenPack taxonomy is a comprehensive structure for httr::content classification.
#' It provides a definitive system categorizing structured and unstructured information, enabling analysis on thousands of entities including companies, products, people, organizations, places, and more.
#'  This endpoint allows you to query and browse the RavenPack taxonomy.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler.
#' @param payload A string in JSON format with the request body parameters.
#' @return A list with the taxonomy information (topic, group, type,...)
#' @author Jose A. Guerrero-Colon
#' @export
#' @import httr
#' @import jsonlite
RP_APITaxonomy = function(APIHandler, payload) {

  taxonomyData = NULL
  if (missing(APIHandler)) {
    stop("You need to provide a valid APIHandler.")
  }

  if (missing(payload)) {
    stop("You need to provide a valid payload")
  }
  # Validating payload - must be a JSON format
  if (jsonlite::validate(payload)!=TRUE) {

    stop("The payload is not in JSON format. Please check the specs")

  } else {

    url_datafile = paste0(APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'taxonomy')

    Res = httr::POST(url = url_datafile,
                     httr::add_headers(api_key = APIHandler$APIKEY, accept = "application/json", content_type = "application/json"),
                     body = payload,
                     encode = "json")

    # Parsing Results
    ResStr = httr::content(Res, as = 'text', encoding = 'UTF-8')
    if (jsonlite::validate(ResStr)) {

      serverResponse = jsonlite::fromJSON(ResStr)
      taxonomyData = serverResponse
      names(taxonomyData) = toupper(names(taxonomyData))

    } else {

      stop(paste("There was an error receiving the httr::content.", ResStr))

    }
  }

  return(taxonomyData)

}
########################################
#####   TAXONOMY ENDPOINT ENDS    ######
########################################
