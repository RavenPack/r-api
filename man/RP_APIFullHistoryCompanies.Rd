% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EndPoints_History.R
\name{RP_APIFullHistoryCompanies}
\alias{RP_APIFullHistoryCompanies}
\title{RP_APIFullHistoryCompanies}
\usage{
RP_APIFullHistoryCompanies(APIHandler)
}
\arguments{
\item{APIHandler}{An API handler, created using RP_CreateAPIHandler.}
}
\value{
The output of the call will be an array of objects listing the files available.
}
\description{
Download a list of files containing the RavenPack Analytics archive for company-only data.
This option is normally used for bulk loading the archive into a database.
Files listed are yearly zip files containing monthly CSV files, up to the end of the prior month, relative to today.
}
\author{
Maria Gomez
}
