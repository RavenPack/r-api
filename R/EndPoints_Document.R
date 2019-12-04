################################
# DOCUMENT PROPERTIES ENDPOINT #
################################

#' @title RP_APIGetDocumentProperties
#' @description This function retrieves a URL for accessing the content of a story.
#' In the case of a story from MoreOver provider, the original_url will be returned.
#' In the case of premium providers, a URL to the RavenPack secure platform will be returned.
#' @param APIHandler An API handler, created using RP_CreateAPIHandler
#' @param rpStoryId A RavenPack identifier for a story (i.e. rp_story_id)
#' @return It returns a json containing the URL to access the content of a story.
#' @author Maria Gomez
#' @export
#' @import httr
#' @import jsonlite
RP_APIGetDocumentProperties = function( APIHandler, rpStoryId ) {

  # Parameter checking
  if ( missing( APIHandler) ) {
    stop("You have to provide a valid APIHandler.")
  }

  if( missing(rpStoryId) ) {
    stop("You need to provide a unique identifier for a story (rpStoryId).")
  }


  # Query API
  url_story = paste0( APIHandler$ENDPOINTS[TYPE == 'ASYNC']$BASE_ENDPOINT,'document/', rpStoryId, '/url')

  res = httr::GET(url = url_story,
                  httr::add_headers(api_key = APIHandler$APIKEY,
                                    accept = "application/json",
                                    content_type = "application/json"),
                  encode = "json")

  return(res)
}
