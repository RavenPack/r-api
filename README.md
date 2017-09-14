Introduction
------------

The RavenPack Self Service R API allows users to request and filter data
from RavenPack Analytics in order to retrieve smaller, more concise
datasets right into R. Our goal with this API is to enable users to
extract RavenPack data in the most efficient way possible, offering a
Streaming function for subscribing to data in real-time, Data query
functions for querying data historically and a Reference functions for
accessing our entity reference master and taxonomy.

This document provides detailed information about RPSelfServiceAPI
Package and examples for each of the functions. For further information
on Filter syntax, available Indicators, etc.. please refer to our [API
documentation](https://staging.ravenpack.com/api-documentation/).

Installation
------------

You can install the package directly from R using the code below

    library(devtools)
    install_github("RavenPack/RPSelfServiceAPI")

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

Creating and managing datasets

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

    ## [1] "0286C6999C7D3DB8EFDAD71CBA7B5AF5"

### List all Datasets

    payload_list = list(scope = list("private","public"), tags = list("Europe Countries"))
    dataSetList = RP_APIListDataSet(APIHandler = APIHandler, params = payload_list)
    dataSetList

    ##       UUID     NAME   TAGS CREATION_TIME
    ## 1: swiss20 SWISS 20 Europe            NA
    ## 2:   eu600   EU 600 Europe            NA
    ## 3:    eu50    EU 50 Europe            NA
    ## 4:    fr40    FR 40 Europe            NA
    ## 5:   uk100   UK 100 Europe            NA
    ## 6:  ibex35  IBEX 35 Europe            NA
    ## 7:    de30    DE 30 Europe            NA

### Get Details for a Dataset

    RP_APIGetDataSet(APIHandler = APIHandler, datasetUUID = datasetUUID)

### Modify an Existing Dataset

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

    ## [1] "Dataset 0286C6999C7D3DB8EFDAD71CBA7B5AF5 successfully modified."

### Delete a Dataset

    serverResponse = RP_APIDeleteDataSet(APIHandler = APIHandler, datasetUUID = datasetUUID)

    ## [1] "Dataset 0286C6999C7D3DB8EFDAD71CBA7B5AF5 successfully deleted."

Datafiles
---------

Generating data files.

### Generate a data file

Use the following to create a datafile:

    requestToken = RP_APIRequestDataFile(APIHandler = APIHandler, payload = payload_filerequest, datasetUUID = datasetUUID)

Here is a full example including the payload syntax:

    payload_filerequest = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00",
      "format": "csv",
      "compressed": true,
      "notify": false
    }'
    requestToken = RP_APIRequestDataFile(APIHandler = APIHandler, payload = payload_filerequest, datasetUUID = datasetUUID)
    # Request Token
    requestToken$TOKEN

    ## [1] "B0A48D59F0E2EC7CF9F66E1DEDA7E9C0"

    # Expected availability
    requestToken$ETA

    ## [1] "2017-09-14 13:18:13"

### Analytics Count

You can find out how many rows a particular datafile will contain before
actually generating it. In general it is a good idea to use this in
order to determine if a particular datafile will be too large and will
need to be broken up into smaller subsets.

    payload_count = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00"
    }'
    rowCount = RP_APIGetDataFileCount(APIHandler = APIHandler, payload = payload_count, datasetUUID = datasetUUID)
    rowCount

    ## [1] 2

### Datafile Generation Status

You can check the data file request status using the following code:

    status = RP_APICheckFileAvailability(APIHandler = APIHandler, token = requestToken$TOKEN)
    status

    ## $STATUS
    ## [1] "processing"

### Cancel a Request

If a datafile generation job has the status "enqueued", it may be
cancelled. Here is how:

    serverResponse = RP_APICancelRequest(APIHandler = APIHandler, token = requestToken$TOKEN)

If the job is finished or processing, you will get an error.

JSON Queries
------------

Request data in JSON format

### Adhoc Request for Data

Using this function, you dont need to define a dataset in advance. All
can be done into the same call, providing the proper payload. Here is a
full example:

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
      "end_date": "2017-01-02 00:00:00"
    }'
    data = RP_APIGetFullAdhocJSON(APIHandler = APIHandler, payload = payload_jsonfull)
    data

    ##          TIMESTAMP_UTC RP_ENTITY_ID                     ENTITY_NAME
    ## 1: 2017-01-02 00:00:00       D8442A                      Apple Inc.
    ## 2: 2017-01-02 00:00:00       ROLLUP Rollup of data for all entities
    ##    AVERAGE_ESS
    ## 1:       0.159
    ## 2:       0.159

### Adhoc Request for Dataset

The JSON dataset endpoint allows data to be requested synchronously and
received in a data.table. A predefined dataset must be supplied and the
fields property may be overriden. Here is an full example:

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
      "end_date": "2017-01-02 00:00:00"
    }'
    data = RP_APIGetDataSetJSON(APIHandler = APIHandler, payload = payload_jsonDS, datasetUUID = datasetUUID)
    data

    ##          TIMESTAMP_UTC RP_ENTITY_ID                     ENTITY_NAME
    ## 1: 2017-01-02 00:00:00       0157B1                 Amazon.com Inc.
    ## 2: 2017-01-02 00:00:00       228D42                 Microsoft Corp.
    ## 3: 2017-01-02 00:00:00       ROLLUP Rollup of data for all entities
    ##    AVERAGE_ESS
    ## 1:       -0.34
    ## 2:        0.44
    ## 3:        0.05

### Preview of a Dataset

The preview endpoint allows a small sample of a dataset to be returned
as data.table. Here is how:

    payload_preview = '{
      "start_date": "2017-01-01 00:00:00",
      "end_date": "2017-01-02 00:00:00"
    }'
    data = RP_APIGetDataSetPreview(APIHandler = APIHandler, payload = payload_preview, datasetUUID = datasetUUID)
    data

    ##    REPORTING_START_DATE_UTC CSS BEE     ENTITY_NAME BMQ
    ## 1:                       NA   0   0 Amazon.com Inc.   0
    ## 2:                       NA   0   0 Microsoft Corp.   0
    ##                   TYPE BER BAM PRODUCT_KEY           TIMESTAMP_UTC   NIP
    ## 1:           ownership   0   0         RPA 2017-01-01 18:32:25.966  0.02
    ## 2: product-enhancement   0   0         RPA 2017-01-01 09:15:07.886 -0.30
    ##    PROPERTY EARNINGS_TYPE MCQ PEQ
    ## 1:     held            NA   0   0
    ## 2:       NA            NA   0   0
    ##                                                             EVENT_TEXT
    ## 1: Beech Hill Advisors Inc. Sells 76 Shares of Amazon.com, Inc. (AMZN)
    ## 2:                            Microsoft planning to launch Surface Pro
    ##                GROUP RP_POSITION_ID REPORTING_END_DATE_UTC MATURITY
    ## 1:    equity-actions             NA                     NA       NA
    ## 2: products-services             NA                     NA       NA
    ##    FACT_LEVEL RELEVANCE RELATED_ENTITY COUNTRY_CODE EVENT_START_DATE_UTC
    ## 1:       fact       100             NA           US                   NA
    ## 2:       fact       100         F3F581           US                   NA
    ##       TOPIC PROVIDER_ID BCA RP_STORY_EVENT_INDEX
    ## 1: business        MRVR   0                    1
    ## 2: business        MRVR   0                    1
    ##                         RP_STORY_ID EVENT_SENTIMENT_SCORE
    ## 1: 0F48455C2AC2506D8E4C8C43846A89E2                 -0.34
    ## 2: F8079AB7E421364BF9D960B16CC70F85                  0.44
    ##    RP_STORY_EVENT_COUNT EVALUATION_METHOD PROVIDER_STORY_ID RP_SOURCE_ID
    ## 1:                    2                NA    10:29089165359       C98333
    ## 2:                   13                NA    10:29085827333       0BFC0E
    ##    ANL_CHG    NEWS_TYPE SUB_TYPE RELATIONSHIP
    ## 1:       0 FULL-ARTICLE decrease           NA
    ## 2:       0 FULL-ARTICLE       NA      PRODUCT
    ##                                                                       HEADLINE
    ## 1:         Beech Hill Advisors Inc. Sells 76 Shares of Amazon.com, Inc. (AMZN)
    ## 2: Microsoft planning to launch Surface Pro 5 in first quarter of 2017: Report
    ##       SOURCE_NAME EVENT_RELEVANCE             EVENT_SIMILARITY_KEY
    ## 1:  Ticker Report             100 43256BF9B32648421FBBE7E6C6BFBED0
    ## 2: Indian Express             100 B943E40345A8C201830DEC62659EAA63
    ##    EVENT_END_DATE_UTC POSITION_NAME RP_ENTITY_ID ENTITY_TYPE
    ## 1:                 NA            NA       0157B1        COMP
    ## 2:                 NA            NA       228D42        COMP
    ##    EVENT_SIMILARITY_DAYS                                    ROW_ID
    ## 1:               3.78813 0F48455C2AC2506D8E4C8C43846A89E2-0157B1-1
    ## 2:             365.00000 F8079AB7E421364BF9D960B16CC70F85-228D42-1
    ##                   CATEGORY REPORTING_PERIOD
    ## 1: ownership-decrease-held               NA
    ## 2:     product-enhancement               NA

Entities
--------

### Map Identifiers into RavenPack Identifiers

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

### Get Reference data file

Provides a link to the entity reference data file

    params_Ref = list(entity_type = 'COMP')
    refData = RP_APIGetReferenceData(APIHandler = APIHandler,params = params_Ref)

### Get Reference data for an Entity

Taxonomy
--------

The RavenPack taxonomy is a comprehensive structure for content
classification. It provides a definitive system categorizing structured
and unstructured information, enabling analysis on thousands of entities
including companies, products, people, organizations, places, and more.

### Querying the Event Taxonomy

This function will allow you to query the event taxonomy. Here is an
example:

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
to your defined R function using a pipe. Something like:

    curl -s -H "api-key:XXX" "https://feed.ravenpack.com/1.0/json/<datasetUUID>" | r -f funPath

Here is a dummy example for processing the stream that you may use as
skeleton:

     f <- file("stdin")
     open(f)
     while(length(line <- readLines(f,n=1)) > 0) {
       write(line, stderr())
       # do any other process
     }
