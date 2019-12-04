#######################
# GET STORY URL       #
#######################
#' @title RP_APIGetStoryURL
#' @description This function retrieves a URL for accessing the content of a story.
#' In the case of a story from MoreOver provider, the original_url will be returned.
#' In the case of premium providers, a URL to the RavenPack secure platform will be returned.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param rpStoryId A RavenPack identifier for a story (i.e. rp_story_id)
#' @return It returns a URL to access the content of a story.
#' @author Maria Gomez
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetStoryURL = function( APIHandler, rpStoryId ) {

  # Parameter checking
  if ( missing( APIHandler) ) {
    stop("You have to provide a valid APIHandler.")
  }

  if( missing(rpStoryId) ) {
    stop("You need to provide a unique identifier for a story (rpStoryId).")
  }


  # Get story url
  res = RP_APIGetDocumentProperties( APIHandler, rpStoryId )

  # Check response status
  checkAPIResponse( res$status_code )

  # Process query results
  resStr = httr::content(res, as = 'text', encoding = 'UTF-8')
  storyUrl = jsonlite::fromJSON(resStr)$url

  return(storyUrl)
}
