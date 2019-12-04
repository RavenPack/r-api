-   [Introduction](#introduction)
-   [Installation](#installation)
    -   [Option 1: Installing from
        Sources](#option-1-installing-from-sources)
    -   [Option 2: Installing from
        Package](#option-2-installing-from-package)
-   [Authentication](#authentication)
-   [Status](#status)
-   [Datasets](#datasets)
    -   [Create a Dataset](#create-a-dataset)
    -   [List all Datasets](#list-all-datasets)
    -   [Get Details for a Dataset](#get-details-for-a-dataset)
    -   [Modify an Existing Dataset](#modify-an-existing-dataset)
    -   [Delete a Dataset](#delete-a-dataset)
-   [Datafiles](#datafiles)
    -   [Generate a data file](#generate-a-data-file)
    -   [Analytics Count](#analytics-count)
    -   [Datafile Generation Status](#datafile-generation-status)
    -   [Cancel a Request](#cancel-a-request)
    -   [Download a Request](#download-a-request)
    -   [Download a Request when Ready](#download-a-request-when-ready)
-   [JSON Queries](#json-queries)
    -   [Adhoc Request for Data](#adhoc-request-for-data)
    -   [Adhoc Request for Dataset](#adhoc-request-for-dataset)
    -   [Preview of a Dataset](#preview-of-a-dataset)
-   [Entities](#entities)
    -   [Map Entity Identifiers into RavenPack’s Entity
        Universe](#map-entity-identifiers-into-ravenpacks-entity-universe)
    -   [Get a Reference Data File](#get-a-reference-data-file)
    -   [Get Reference Data for an
        Entity](#get-reference-data-for-an-entity)
-   [Taxonomy](#taxonomy)
    -   [Querying the Event Taxonomy](#querying-the-event-taxonomy)
-   [Full History](#full-history)
-   [Document](#document)
-   [Real Time Feed](#real-time-feed)
    -   [Subscribing to a Feed](#subscribing-to-a-feed)
-   [FAQ](#faq)
    -   [Authentication issues](#authentication-issues)

Introduction
------------

The RavenPack Self Service R API allows users to request and filter data
from RavenPack Analytics in order to retrieve smaller, more concise
datasets right into R. Our goal with this API is to enable users to
extract RavenPack data in the most efficient way possible, offering a
Streaming function for subscribing to data in real-time, Data query
functions for querying data historically and Reference functions for
accessing our entity reference master and taxonomy.

This document provides detailed information about RPSelfServiceAPI
Package and examples for each of the functions. For further information
on Filter syntax, available Indicators, etc.. please refer to our [API
documentation](https://app.ravenpack.com/api-documentation/).

Installation
------------

There are 2 options to install the library:

1.  From library sources

2.  From the compiled package.

Select the option you prefer.

### Option 1: Installing from Sources

First, you need to install the *devtools* package. You can do this from
CRAN. Invoke R and then type:

    install.packages("devtools")

At this point, you can install the package directly from R using the
code below.

    library(devtools)
    install_github("RavenPack/r-api")

### Option 2: Installing from Package

Download **/r-api-package/RPSelfServiceAPI\_&lt;VERSION&gt;.tar.gz**
file to your machine. Then, invoke R and execute the following
instruction.

NOTE: *PATH\_TO\_FILE* must be replaced by the path of the
RPSelfServiceAPI\_&lt;VERSION&gt;.tar.gz file in your machine.
*&lt;VERSION&gt;* must be replaced by the available version number. For
example *RPSelfServiceAPI\_1\_102.tar.gz*.

    install.packages( "PATH_TO_FILE", repos = NULL, type="source")

    # For example:
    # install.packages( "/home/r-api-package/RPSelfServiceAPI_1_102.tar.gz", repos = NULL, type="source") 

Authentication
--------------

In order to use this API you must authenticate against the server. This
can be performed as follows:

    library(RPSelfServiceAPI)

    APIKey = "<A_VALID_API_KEY>"
    APIHandler = RP_CreateAPIHandler(APIKey)

Status
------

General Status of server.

    Status = RP_APIStatus(APIHandler = APIHandler)
    print(Status)

    ## [1] "OK"

Datasets
--------

Creating and managing datasets.

### Create a Dataset

Use the following to create a dataset:

    datasetUUID = RP_APICreateDataSet(APIHandler = APIHandler, payload = payload_createDS)

Here is a full example, including payload:

    payload_createDS = '{
      "name": "Testing RPSelfServiceAPI",
      "description": "This dataset is used for testing the Web API from R",
      "tags": [
        "Testing"
      ],
      "product": "RPA",
      "product_version": "1.0",
      "frequency": "granular",
      "fields": [
        "TIMESTAMP_UTC",
        "RP_STORY_ID",
        "RP_ENTITY_ID",
        "ENTITY_NAME"
      ],
      "filters": {
        "and": [
          {
            "RP_ENTITY_ID": {
              "in": [
                "0157B1",
                "228D42"
              ]
            }
          },
          {
            "EVENT_RELEVANCE": {
              "gte": 90
            }
          }
        ]
      }
    }'
    datasetUUID = RP_APICreateDataSet(APIHandler = APIHandler, payload = payload_createDS)
    print(datasetUUID)

    ## [1] "8A26BDF050EE99445D6BCCF8A252F672"

### List all Datasets

Get a list of the datasets that you have permission to access. You may
filter the list by tags and search for only the list of datasets that
have the tags specified. You may also filter by scope, and return only
the datasets that are *Public* to everyone, *Shared* with you by someone
else using RavenPack, or *Private* datasets that were created by you.
Filtering by frequency allows you to retrieve *granular* or *daily*
datasets.

The list of datasets returns the dataset\_uuid, name and creation time
(if available) for each dataset.

    payload_list = list( scope = list("private","public"),
                         tags = list("Europe_Countries"),
                         frequency = list('daily','granular') )
    dataSetList = RP_APIListDataSet(APIHandler = APIHandler, params = payload_list)
    dataSetList

    ##           UUID                   NAME             TAGS CREATION_TIME
    ##  1: country-be                Belgium Europe_Countries            NA
    ##  2: country-gr                 Greece Europe_Countries            NA
    ##  3: country-fi                Finland Europe_Countries            NA
    ##  4: country-ax          Aland Islands Europe_Countries            NA
    ##  5: country-fo          Faroe Islands Europe_Countries            NA
    ##  6: country-at                Austria Europe_Countries            NA
    ##  7: country-hr                Croatia Europe_Countries            NA
    ##  8: country-is                Iceland Europe_Countries            NA
    ##  9: country-hu                Hungary Europe_Countries            NA
    ## 10: country-fr                 France Europe_Countries            NA
    ## 11: country-dk                Denmark Europe_Countries            NA
    ## 12: country-ad                Andorra Europe_Countries            NA
    ## 13: country-ie                Ireland Europe_Countries            NA
    ## 14: country-de                Germany Europe_Countries            NA
    ## 15: country-cy                 Cyprus Europe_Countries            NA
    ## 16: country-bg               Bulgaria Europe_Countries            NA
    ## 17: country-gi              Gibraltar Europe_Countries            NA
    ## 18: country-al                Albania Europe_Countries            NA
    ## 19: country-gg               Guernsey Europe_Countries            NA
    ## 20: country-ee                Estonia Europe_Countries            NA
    ## 21: country-by                Belarus Europe_Countries            NA
    ## 22: country-it                  Italy Europe_Countries            NA
    ## 23: country-cz         Czech Republic Europe_Countries            NA
    ## 24: country-ba Bosnia and Herzegovina Europe_Countries            NA
    ## 25: country-im            Isle of Man Europe_Countries            NA
    ## 26: country-mc                 Monaco Europe_Countries            NA
    ## 27: country-mk        North Macedonia Europe_Countries            NA
    ## 28: country-xk                 Kosovo Europe_Countries            NA
    ## 29: country-me             Montenegro Europe_Countries            NA
    ## 30: country-pt               Portugal Europe_Countries            NA
    ## 31: country-li          Liechtenstein Europe_Countries            NA
    ## 32: country-se                 Sweden Europe_Countries            NA
    ## 33: country-si               Slovenia Europe_Countries            NA
    ## 34: country-pl                 Poland Europe_Countries            NA
    ## 35: country-sk               Slovakia Europe_Countries            NA
    ## 36: country-lu             Luxembourg Europe_Countries            NA
    ## 37: country-md                Moldova Europe_Countries            NA
    ## 38: country-ch            Switzerland Europe_Countries            NA
    ## 39: country-ro                Romania Europe_Countries            NA
    ## 40: country-sj Svalbard and Jan Mayen Europe_Countries            NA
    ## 41: country-rs                 Serbia Europe_Countries            NA
    ## 42: country-sm             San Marino Europe_Countries            NA
    ## 43: country-va                Vatican Europe_Countries            NA
    ## 44: country-je                 Jersey Europe_Countries            NA
    ## 45: country-es                  Spain Europe_Countries            NA
    ## 46: country-gb         United Kingdom Europe_Countries            NA
    ## 47: country-ru                 Russia Europe_Countries            NA
    ## 48: country-ua                Ukraine Europe_Countries            NA
    ## 49: country-no                 Norway Europe_Countries            NA
    ## 50: country-mt                  Malta Europe_Countries            NA
    ## 51: country-nl        The Netherlands Europe_Countries            NA
    ## 52: country-lt              Lithuania Europe_Countries            NA
    ## 53: country-lv                 Latvia Europe_Countries            NA
    ##           UUID                   NAME             TAGS CREATION_TIME

### Get Details for a Dataset

Get the full specification for a single dataset.

    RP_APIGetDataSet(APIHandler = APIHandler, datasetUUID = datasetUUID)

### Modify an Existing Dataset

Modify an existing dataset. When modifying a dataset, it is possible to
provide just the parameters that you wish to modify. Any parameters that
are not included in the request will retain their value and will not be
modified.

    RP_APIModifyDataSet(APIHandler = APIHandler, payload = payload_modify, datasetUUID = datasetUUID)

Here is a full example including payload syntax:

    payload_modify = '{
      "name": "Modifying RPSelfServiceAPI",
      "description": "This dataset is used for testing the Web API from R - Modified",
      "tags": [
        "Testing"
      ],
      "product": "RPA",
      "product_version": "1.0",
      "frequency": "granular",
      "fields": [
        "TIMESTAMP_UTC",
        "RP_STORY_ID",
        "RP_ENTITY_ID",
        "ENTITY_NAME"
      ],
      "filters": {
        "and": [
          {
            "RP_ENTITY_ID": {
              "in": [
                "0157B1",
                "228D42"
              ]
            }
          },
          {
            "EVENT_RELEVANCE": {
              "gte": 90
            }
          }
        ]
      }
    }'
    serverResponse = RP_APIModifyDataSet(APIHandler = APIHandler, payload = payload_modify, datasetUUID = datasetUUID)

    ## [1] "Dataset 8A26BDF050EE99445D6BCCF8A252F672 successfully modified."

### Delete a Dataset

Delete a single dataset.

    serverResponse = RP_APIDeleteDataSet(APIHandler = APIHandler, datasetUUID = datasetUUID)

    ## [1] "Dataset deleted"

Datafiles
---------

Generating datafiles for a particular dataset for any period from the
year 2000 to present. Data may be retrieved in CSV or Excel format and
may be compressed (.ZIP) for transmission via HTTP.

Notes:

-   There is a limitation of 50 million records for generating granular
    data and 10 million records for aggregated data.
-   There is a limit to the number of datafiles that may be generated
    concurrently for a single user via the RavenPack API.
-   In the event that too many requests have been made, a HTTP 429
    response will be returned.

### Generate a data file

Use the following to create a datafile:

    requestToken = RP_APIRequestDataFile(APIHandler = APIHandler, payload = payload_filerequest, datasetUUID = datasetUUID)

Here is a full example including the payload syntax:

    payload_filerequest = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "time_zone": "Europe/Madrid",
      "format": "csv",
      "compressed": true,
      "notify": false
    }'
    requestToken = RP_APIRequestDataFile(APIHandler = APIHandler, payload = payload_filerequest, datasetUUID = datasetUUID)
    # Request Token
    requestToken$TOKEN

    ## [1] "FA691B71052C803513F5A70709FA9C42"

    # Expected availability
    requestToken$ETA

    ## [1] "2019-11-26 12:34:18 UTC"

### Analytics Count

You can find out how many rows a particular datafile will contain before
actually generating it. In general, it is a good idea to use this in
order to determine if a particular datafile will be too large and will
need to be broken up into smaller subsets.

    payload_count = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "time_zone": "Europe/Madrid"
    }'
    rowCount = RP_APIGetDataFileCount(APIHandler = APIHandler, payload = payload_count, datasetUUID = datasetUUID)
    rowCount

    ## [1] 2

### Datafile Generation Status

After submitting a request to generate a datafile, you can check the
request status using the following code:

    status = RP_APICheckFileAvailability(APIHandler = APIHandler, token = requestToken$TOKEN)
    status

    ## $STATUS
    ## [1] "processing"
    ## 
    ## $START_DATE
    ## [1] "2017-01-01 00:00:00"
    ## 
    ## $END_DATE
    ## [1] "2017-01-02 00:00:00"
    ## 
    ## $TIME_ZONE
    ## [1] "Europe/Madrid"
    ## 
    ## $SUBMITTED
    ## [1] "2019-11-26 12:34:18 UTC"
    ## 
    ## $TOKEN
    ## [1] "FA691B71052C803513F5A70709FA9C42"
    ## 
    ## $SIZE
    ## NULL
    ## 
    ## $URL
    ## NULL
    ## 
    ## $CHECKSUM
    ## NULL
    ## 
    ## $TAGS
    ## list()

When the job is complete, the status will be updated to “completed”.

### Cancel a Request

If a datafile generation job has the status “enqueued”, it may be
cancelled. To cancel a job:

    serverResponse = RP_APICancelRequest(APIHandler = APIHandler, token = requestToken$TOKEN)

If the job is finished or processing, you will get an error.

### Download a Request

Once the status of the request is “completed”, the datafile can be
downloaded. You have to provide a name for the datafile. Make sure your
extension matches the format you requested (csv, xls,…). In particular,
if compression was requested, you will be receiving a zip file.

If you try to download the dataset before the request has completed, you
will receive an error message: ‘The Request status is not complete.’.
Please wait until the request is completed to perform the download. You
can use the *RP\_APIWaitForJobCompletion* function to wait until the
request is completed. The *timeout* parameter specifies the maximum
waiting time (in seconds).

    # Wait until job is completed
    jobStatus = RP_APIWaitForJobCompletion (APIHandler = APIHandler, token = requestToken$TOKEN, timeout = 120)

    # Checking completion
    if (jobStatus$STATUS == "completed") {
      
      RP_APIDownloadFile(APIHandler = APIHandler, statusInfo = jobStatus$STATUSINFO, outputFile = 'datafile.zip')
      
    }

### Download a Request when Ready

It is also possible to automate the download by using the
*RP\_APIDownloadFileWhenReady* function. This function waits until the
file is ready to download. You must provide the maximum waiting time (in
seconds) using the *timeout* parameter.

    RP_APIDownloadFileWhenReady(APIHandler = APIHandler, token = requestToken$TOKEN, outputFile = 'datafile.zip', timeout = 120)

JSON Queries
------------

Request data in JSON format.

### Adhoc Request for Data

This function allows data to be requested synchronously in JSON format,
without having previously defined a dataset. The function requires
similar parameters to the ones used when creating a dataset.

Here is a full example:

    payload_jsonfull = '{
      "product": "RPA",
      "product_version": "1.0",
      "frequency": "daily",
      "fields": [
        {
          "average_ess": {
            "avg": {
              "field": "event_sentiment_score"
            }
          }
        }
      ],
      "filters": {
        "and": [
          {
            "RP_ENTITY_ID": {
              "in": [
                "D8442A"
              ]
            }
          },
          {
            "EVENT_RELEVANCE": {
              "eq": 100
            }
          }
        ]
      },
      "having": [],
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "time_zone": "Europe/Madrid"
    }'
    data = RP_APIGetFullAdhocJSON(APIHandler = APIHandler, payload = payload_jsonfull)
    data

    ##          TIMESTAMP_UTC     TIMESTAMP_LOCAL RP_ENTITY_ID
    ## 1: 2017-01-01 23:00:00 2017-01-02 00:00:00       D8442A
    ## 2: 2017-01-01 23:00:00 2017-01-02 00:00:00       ROLLUP
    ##                        ENTITY_NAME AVERAGE_ESS
    ## 1:                      Apple Inc.       0.159
    ## 2: Rollup of data for all entities       0.159

### Adhoc Request for Dataset

This function allows data to be requested synchronously and received in
a data.table. A predefined dataset must be supplied and the fields
property may be overriden. Here is a full example:

    payload_jsonDS = '{
      "frequency": "daily",
      "fields": [
        {
          "average_ess": {
            "avg": {
              "field": "event_sentiment_score"
            }
          }
        }
      ],
      "having": [],
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "time_zone": "Europe/Madrid"
    }'
    data = RP_APIGetDataSetJSON(APIHandler = APIHandler, payload = payload_jsonDS, datasetUUID = datasetUUID)
    data

    ##          TIMESTAMP_UTC     TIMESTAMP_LOCAL RP_ENTITY_ID
    ## 1: 2017-01-01 23:00:00 2017-01-02 00:00:00       0157B1
    ## 2: 2017-01-01 23:00:00 2017-01-02 00:00:00       228D42
    ## 3: 2017-01-01 23:00:00 2017-01-02 00:00:00       ROLLUP
    ##                        ENTITY_NAME AVERAGE_ESS
    ## 1:                 Amazon.com Inc.       -0.34
    ## 2:                 Microsoft Corp.        0.44
    ## 3: Rollup of data for all entities        0.05

### Preview of a Dataset

This function allows a a small sample of a dataset to be returned in a
data.table. Here is how:

    payload_preview = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "time_zone": "Europe/Madrid"
    }'
    data = RP_APIGetDataSetPreview(APIHandler = APIHandler, payload = payload_preview, datasetUUID = datasetUUID)
    data

    ##              TIMESTAMP_UTC                      RP_STORY_ID RP_ENTITY_ID
    ## 1: 2017-01-01 18:32:25.966 0F48455C2AC2506D8E4C8C43846A89E2       0157B1
    ## 2: 2017-01-01 09:15:07.886 F8079AB7E421364BF9D960B16CC70F85       228D42
    ##        ENTITY_NAME
    ## 1: Amazon.com Inc.
    ## 2: Microsoft Corp.

Entities
--------

### Map Entity Identifiers into RavenPack’s Entity Universe

The entity-mapping endpoint may be used to map from a universe of entity
or security identifiers into RavenPack’s entity universe. One may pass
in identifiers such as entity names, listings, ISIN values, CUSIP
values, etc. and the endpoint will return the corresponding
RP\_ENTITY\_ID for the possible matches. Find a full example below:

    payload_maprequest = '{
      "identifiers": [
        {
          "client_id": "12345-A",
          "date": "2017-01-01",
          "name": "Amazon Inc.",
          "entity_type": "COMP",
          "isin": "US0231351067",
          "cusip": "023135106",
          "sedol": "B58WM62",
          "listing": "XNAS:AMZN"
        }
      ]
    }'
    mapData = RP_APIMappingRequest(APIHandler = APIHandler, payload = payload_maprequest)

In the event that it is unable to match the requested entity to an
entity in the RavenPack entity universe, there will be no mapped
entities and the requested data is returned as an error.

In the event that multiple entities are matched, the entities will be
returned ranked with a relative score, which may be used to
automatically filter or sort for further analysis.

### Get a Reference Data File

It provides a link to the entity reference data file.

    params_ref = list( entity_type = 'COMP' )
    fileURL = RP_APIGetReferenceData( APIHandler = APIHandler, params = params_ref )

    # Load data from file
    refData = read.csv( fileURL, stringsAsFactors = FALSE )

### Get Reference Data for an Entity

Request reference data for a single entity in RavenPack’s entity
universe. It is possible to have more than one value for a particular
type of data.

    rp_entity_id = '0157B1' 
    refData = RP_APIGetEntityReference(APIHandler = APIHandler, entity_id = rp_entity_id )

Taxonomy
--------

The RavenPack taxonomy is a comprehensive structure for content
classification. It provides a definitive system categorizing structured
and unstructured information, enabling analysis on thousands of entities
including companies, products, people, organizations, places, and more.

### Querying the Event Taxonomy

This function allow to query the event taxonomy. Here is an example:

    payload_taxonomy = '{
      "topics": [],
      "groups": [],
      "types": [],
      "sub_types": [],
      "properties": [],
      "categories": [
        "earnings-above-expectations",
        "product-recall"
      ]
    }'
    taxonomyData = RP_APITaxonomy(APIHandler = APIHandler, payload = payload_taxonomy)

Full History
------------

The *History API* allows to download the full historical archive of
RavenPack analytics (from 2000 to previous month). The archive is
composed by yearly zip files containing monthly *CSV* files, up to the
end of the prior month, relative to today.

The function offers the possibility to only retrieve analytics for
companies or all analytics for all entity types.

**IMPORTANT**. This action will download the **full** analytics archive.
This operation can take several hours to complete. This option is
normally used for bulk loading the archive into a database.

    # Download analytics only for comapnies
    RP_APIDownloadFullHistory( APIHandler = APIHandler, outFolderPath = "~/Downloads", onlyCompany = TRUE )

    # Download analytics for all entities
    RP_APIDownloadFullHistory( APIHandler = APIHandler, outFolderPath = "~/Downloads", onlyCompany = FALSE )

Document
--------

The *RavenPack Document API* provides access to the news stories. In
particular it retrieves the URL for accessing the content of a story.

You must provide the RavenPack story identifier (i.e., *rp\_story\_id*)
of the story to access.

    url = RP_APIGetStoryURL( APIHandler = APIHandler, rpStoryId = "5A30583B902BF39B1D4E6C5BA7053F44"  ) 

Real Time Feed
--------------

The RavenPack Streaming API allows users to subscribe to a dataset from
RavenPack in real-time. At this time, only datasets defined with
granular frequency are supported by this endpoint.

### Subscribing to a Feed

You can use the following code to subscribe to a feed:

    funPath = "process-stream.R"
    data = RP_APISubscribeRT(APIHandler = APIHandler, datasetUUID = datasetUUID, funPath = funPath)

Bear in mind that, under the hood, the data will be passed from a curl
to your defined R function using a pipe. Example:

    curl -s -H "api-key:XXX" "https://feed.ravenpack.com/1.0/json/<datasetUUID>" | r -f funPath

Here there is a simple example for processing the stream that you may
use as skeleton:

     f <- file("stdin")
     open(f)
     while(length(line <- readLines(f,n=1)) > 0) {
       write(line, stderr())
       # do any other process
     }

FAQ
---

### Authentication issues

If you are behind a firewall or a proxy, you may experience problems
with SSL authentication:

    > status = RP_APIStatus(APIHandler = APIHandler)
     Error in curl::curl_fetch_memory(url, handle = handle) :
     Peer certificate cannot be authenticated with given CA certificates

As a workaround, you can run the following code:

    > library(httr)
    > set_config(config(ssl_verifypeer = 0L))
