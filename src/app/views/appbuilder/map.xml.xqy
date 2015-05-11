xquery version "1.0-ml";

(: views/appbuilder/map.xml.xqy
 :
 : The map view uses this to refresh heatmap and facets.
 :)

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace c = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";
import module namespace facet = "http://marklogic.com/roxy/facet-lib"
  at "/app/views/helpers/facet-lib.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

declare variable $MATCHES-HREF as xs:string := vh:get("matches-href");
declare variable $PSEUDO-FACETS as element()? := vh:get("pseudo-facets");
declare variable $Q as xs:string? := vh:get("q");
declare variable $QUERY as element()? := vh:get("query");
declare variable $RESPONSE as element(search:response)? := vh:get("response");
declare variable $SUBTAB as xs:integer := vh:get("subtab-active");

xdmp:set-response-content-type('application/xml'),
(: Make it look like html, for IE8 :)
element div {
  if (empty($RESPONSE/search:facet)) then ()
  else element div {
    attribute id { 'sidebar' }, attribute class { 'sidebar' },
    facet:facets(
      $RESPONSE/search:facet, $PSEUDO-FACETS, $Q, $QUERY,
      $MATCHES-HREF, vh:get('search-options'), $c:LABELS) },
  element div {
    attribute id { 'heatmap' },
    (: Using the json library is not worth it for this case. :)
    '[',
    string-join(
      $RESPONSE/search:boxes/search:box[ @count gt 0 ] ! text {
        '[', string-join(xs:string((@s, @w, @n, @e, @count)), ','), ']' },
      ','), ']' } }

(: views/appbuilder/map.xml.xqy :)