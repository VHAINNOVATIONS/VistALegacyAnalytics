xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/saved-search";
import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace saved-search = "http://marklogic.com/roxy/models/saved-search" at "/app/models/saved-search.xqy";
import module namespace config = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare option xdmp:mapping "false";
declare option xdmp:update "false";
declare variable $_query := req:get("q", "", "type=xs:string");
declare variable $_id := req:get("id", "", "type=xs:string");
declare variable $_user := xdmp:get-current-user();
declare variable $savedsearch-match-doc := fn:doc(fn:concat("/users/", xdmp:get-current-user(), "/savedsearch-match.xml"));

(:
 : Usage Notes:
 :
 : use the ch library to pass variables to the view
 :
 : use the request (req) library to get access to request parameters easily
 :
 :)

declare function c:sortSavedSearches($savedSearches, $sortColumnIndex, $sortDirection)
{
  let $ascending :=  c:getSortDirection($sortDirection)
  let $sortedSavedSearches := (
    if ($sortColumnIndex eq "0") then
      for $savedSearch in $savedSearches/savedSearch
        order by
          if ($ascending) then $savedSearch/fn:data(date) else () ascending,
          if ($ascending) then () else $savedSearch/fn:data(date) descending
        return $savedSearch
    else if ($sortColumnIndex eq "1") then
      for $savedSearch in $savedSearches/savedSearch
        order by
          if ($ascending) then $savedSearch/fn:data(search) else () ascending,
          if ($ascending) then () else $savedSearch/fn:data(search) descending
        return $savedSearch
    else
      for $savedSearch in $savedSearches/savedSearch
        order by
          if ($ascending) then $savedSearch/fn:data(id) else () ascending,
          if ($ascending) then () else $savedSearch/fn:data(id) descending
        return $savedSearch
  )
  return $sortedSavedSearches
};

declare function c:getSortDirection($sortDirectionString as xs:string) as xs:boolean
{
  let $result := (
    if ($sortDirectionString eq "asc") then
      fn:true()
    else
      fn:false()
   )
  return $result
};

declare function c:convertSavedSearchXmlToJson($savedSearches, $totalSearchesCount)
{
  let $end := "]}"
  let $jsonRows := c:buildJsonRows($savedSearches)
  let $start := '{ "iTotalRecords": "' || fn:count($savedSearches) || '", "iTotalDisplayRecords": "' || $totalSearchesCount || '", "aaData": ['
  let $combinedJsonRows := fn:string-join($jsonRows, ",")
  let $jsonResponse := $start || $combinedJsonRows || $end
  let $_ := xdmp:log("$jsonResponse: " || $jsonResponse)
  return $jsonResponse
};

declare function c:json-escape-string($string)
{
  let $string := fn:replace($string, '"', '\\"')
  return $string
};

declare function c:buildJsonRows($savedSearches)
{
  (: ["07/01/13 02:35 pm", "birthdecade:1930s", "797053167"] :)
  for $savedSearch in $savedSearches
      return '["' || c:json-escape-string($savedSearch/date) || '","' ||
       c:json-escape-string($savedSearch/search) || '","' ||
       c:json-escape-string($savedSearch/id) || '"]'
};

declare function c:getFilteredSavedSearches($allSavedSearches, $filterText)
{
  let $_ := ""
  return
    if (fn:string-length($filterText) gt 0) then
      $allSavedSearches[savedSearch/fn:contains(fn:upper-case(search/text()), fn:upper-case($filterText))]
    else
      $allSavedSearches
};

declare function c:pageSavedSearches($savedSearches, $displayStart, $displayLength)
{
    let $startPagingIndex := fn:sum(($displayStart,1))
    let $endPagingIndex := fn:sum(($displayStart,$displayLength))
    return $savedSearches[$startPagingIndex to $endPagingIndex]
};

declare function c:getSavedSearches() as item()*
{
    (: paging parameters :)
    let $displayStart := xs:int(xdmp:get-request-field("iDisplayStart"))
    let $displayLength := xs:int(xdmp:get-request-field("iDisplayLength"))
    (: sort parameters :)
    let $sortColIndex := xdmp:get-request-field("iSortCol_0")
    let $sortDirection := xdmp:get-request-field("sSortDir_0")
    (: filtering :)
    let $searchFieldText := xdmp:get-request-field("sSearch")

    (:
    let $_ := xdmp:log("paging-iDisplayStart: " || $displayStart )
    let $_ := xdmp:log("paging-iDisplayLength: " || $displayLength )
    let $_ := xdmp:log("sort-iSortCol_0: " || $sortColIndex )
    let $_ := xdmp:log("sSortDir_0: " || $sortDirection )
    let $_ := xdmp:log("searchFieldText: " || $searchFieldText )
    :)

    let $allSavedSearches := xdmp:directory("/users/" || xdmp:get-current-user() || "/saved/", "infinity")
    let $filteredSavedSearches := c:getFilteredSavedSearches($allSavedSearches, $searchFieldText)
    let $sortedSavedSearches := c:sortSavedSearches($filteredSavedSearches, $sortColIndex, $sortDirection)
    let $pagedSavedSearches := c:pageSavedSearches($sortedSavedSearches, $displayStart, $displayLength)

    let $totalSearchesCount := fn:count($allSavedSearches)
    let $convertedXml := c:convertSavedSearchXmlToJson($pagedSavedSearches, $totalSearchesCount)
    return $convertedXml
};

declare function c:list() as item()*
{
 (: get saved queries from database  :)

  let $items := saved-search:find-all($_user)
  let $_ := xdmp:log( text {$_user})
  let $_ := xdmp:log( text {$items })
  return(
      ch:add-value("title", "VistA Analytics"),  (: TODO: Move to layout :)
      ch:add-value("user", $_user ),
      ch:add-value("items", $items ),
      ch:use-view("list", "xml"),
      ch:use-layout("full-page", "html")
   )
};

(: save query to database   :)
declare function c:create() as item()*
{
  let $date := fn:current-dateTime()
  let $_ := saved-search:save($_user, $_query, $date)

  return(
    ch:add-value("user", $_user ),
    ch:use-view(()),
    ch:use-layout(())
    )
};

declare function c:delete() as item()*
{
  let $id := req:required('id', 'type=xs:unsignedLong')
  return (
    ch:use-view(()),
    ch:use-layout(()),
    saved-search:delete($_user, $id),
    '{"status": "success"}'
  )
};

declare function c:new-match-check() as item()*
{
  let $since := req:get("since", (), "type=xs:dateTime")
  let $saved-searches := xdmp:directory("/users/" || xdmp:get-current-user() || "/saved/", "infinity")/savedSearch/search/fn:string()
  let $query :=
    cts:and-query((
      cts:or-query((
        for $s in $saved-searches
        return cts:query(search:parse($s, $config:SEARCH-OPTIONS, "cts:query"))
      )),
      cts:element-range-query(xs:QName("va:ingested"), ">=", $since)
    ))
  return (
    ch:use-view(()),
    ch:use-layout(()),
    fn:concat('{"matches": ', xdmp:estimate(cts:search(/va:vpr, $query)), '}')
  )
};

declare function c:clear-new-matches() as item()*
{
  let $match-doc := fn:doc(fn:concat("/users/", xdmp:get-current-user(), "/savedsearch-match.xml"))
  return (
    ch:use-view(()),
    ch:use-layout(()),
    for $node in $match-doc//uri
    return xdmp:node-delete($node),
    '{"status": "success"}'
  )
};