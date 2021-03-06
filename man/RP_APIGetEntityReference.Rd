% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RP_SelfServiceAPI_EndPoints.R
\name{RP_APIGetEntityReference}
\alias{RP_APIGetEntityReference}
\title{RP_APIGetEntityReference}
\usage{
RP_APIGetEntityReference(APIHandler, entity_id)
}
\arguments{
\item{APIHandler}{An API handler, created using RP_CreateAPIHandler}

\item{entity_id}{A valid RP_ENTITY_ID.}
}
\value{
A list with the mapping information.
}
\description{
Request reference data for a single entity in RavenPack’s entity universe.
It is possible to have more than one value for a particular type of data. This is encoded as separate EntityData objects with possibly different time ranges associated.
Please note that it is also normal to have more than one value for a particular type of data over the same time range.
}
\author{
Jose A. Guerrero-Colon
}
