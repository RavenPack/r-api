% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RP_SelfServiceAPI_EndPoints.R
\name{RP_APISubscribeRT}
\alias{RP_APISubscribeRT}
\title{RP_APISubscribeRT}
\usage{
RP_APISubscribeRT(APIHandler, datasetUUID, funPath)
}
\arguments{
\item{APIHandler}{An API handler, created using RP_CreateAPIHandler.}

\item{datasetUUID}{A string with the dataset identifier to subscribe.}

\item{funPath}{The path to an R function to process the stream. Bear in mind the data will be passed from a
curl call using a pipe. Something like: curl -s -H \"api-key:XXX\" \"https://feed.ravenpack.com/1.0/json/<datasetUUID>\" | R -f funPath
As a function example:
"f <- file("stdin")
open(f)
while(length(line <- readLines(f,n=1)) > 0) \{
write(line, stderr())
print(line)
# do any other process
\}"}
}
\value{
A stream of JSON objects separated by '\\n'
}
\description{
Subscribes to real-time analytics.
}
\author{
Jose A. Guerrero-Colon
}
