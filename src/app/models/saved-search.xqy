xquery version "1.0-ml";

module namespace this = "http://marklogic.com/roxy/models/saved-search";
import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare option xdmp:mapping "false";

declare variable $USER-MATCHES-DOC-URI := "/users/" || xdmp:get-current-user() || "/" || "savedsearch-match.xml";

declare function this:save($user, $query, $date)
{

  let $id := this:create-id($user, $date)

  let $doc :=
    <savedSearch>
      <id>{$id}</id>
      <date>{$date}</date>
      <search>{$query}</search>
    </savedSearch>

  let $uri := this:create-uri($user, $id)
  let $_ := if (fn:exists(fn:doc($USER-MATCHES-DOC-URI))) then () else xdmp:document-insert($USER-MATCHES-DOC-URI, <savedsearch-match/>)
  let $rule-name := fn:concat("saved-query-", $user, "-", xdmp:hash32($query))
  let $cts-query := cts:query(search:parse($query, $c:SEARCH-OPTIONS, "cts:query"))
  let $alert-rule := alert:make-rule(
    $rule-name,
    "saved query alert",
    xdmp:user($user),
    $cts-query,
    "vista:savedsearch-match",
    <alert:options/>
  )
  return (
    if (alert:get-my-rules("/config/savedsearch-alert-config.xml", $cts-query)) then ()
    else
      alert:rule-insert("/config/savedsearch-alert-config.xml", $alert-rule),
    xdmp:document-insert($uri, $doc,xdmp:default-permissions())
  )

};

declare function this:delete($user, $id)
{
  let $saved-searches := xdmp:directory(this:create-directory-uri($user))//search
  let $uri := this:create-directory-uri($user) || $id || ".xml"
  let $query := fn:doc($uri)/savedSearch/search/fn:string()
  let $cts-query := cts:query(search:parse($query, $c:SEARCH-OPTIONS, "cts:query"))
  let $matching-rule := alert:get-my-rules("/config/savedsearch-alert-config.xml", $cts-query)
  let $matches := fn:count(for $s in $saved-searches return if (alert:get-my-rules("/config/savedsearch-alert-config.xml", cts:query(search:parse($s, $c:SEARCH-OPTIONS, "cts:query")))) then 1 else ())
  let $_ := if ($matches le 1 and fn:exists($matching-rule/@id/fn:string())) then alert:rule-remove("/config/savedsearch-alert-config.xml", xs:unsignedLong($matching-rule/@id/fn:string())) else ()
  return xdmp:document-delete($uri)
};

declare function this:create-directory-uri($user)
{
   "/users/" || $user || "/saved/"

};

declare function this:create-uri($user, $id)
{
    this:create-directory-uri($user) || $id || ".xml"
};


declare function this:get-results-as-query($user as xs:string, $id as xs:string) as cts:query
{
    let $savedsearch := fn:doc(this:create-uri($user, $id))/savedSearch
    let $query := $savedsearch/search/fn:string()
    let $created := xs:dateTime($savedsearch/date/fn:string())
    return
      cts:and-query((
        cts:query(search:parse($query, $c:SEARCH-OPTIONS, "cts:query")),
        cts:element-range-query(xs:QName("va:ingested"), "<=", $created)
      ))
};



declare function this:find-all($user as xs:string) as element(savedSearches)*
{
    let $uri := this:create-directory-uri($user)
    let $docs := xdmp:directory($uri, "infinity" )

    let $out :=
      <savedSearches>{
        $docs
      }</savedSearches>

    return $out
};


declare function this:create-id($user, $date)
{
  xdmp:hash32($user || fn:format-dateTime($date, "[Y01][M01][D01][H01][s01][f01]"))
};

declare function this:search-parse($ctext as xs:string, $right as schema-element(cts:query))
  as schema-element(cts:query)
{
  let $saved-searches := xdmp:directory("/users/" || xdmp:get-current-user() || "/saved/", "infinity")/savedSearch
  let $id := $right//cts:text
  return
    <cts:or-query qtextpre="saved-search:" qtextref="cts:text">
    {
      if ($id = 'all') then
        for $s in $saved-searches/search/fn:string()
        return search:parse($s, $c:SEARCH-OPTIONS, "cts:query")
      else
        for $i in $id
        for $search in $saved-searches[id = $i]
        let $s := $search/search/fn:string()
        let $date := xs:dateTime($search/date)
        return
          cts:and-query((
            cts:query(search:parse($s, $c:SEARCH-OPTIONS, "cts:query")),
            cts:element-range-query(xs:QName("va:ingested"), "<=", $date)
          ))
    }
    </cts:or-query>
};