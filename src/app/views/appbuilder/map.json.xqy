xquery version "1.0-ml";

(: views/appbuilder/map.json.xqy :)

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

declare variable $RESPONSE as element()? := vh:get("response");

(: Using the json library is not worth it for this case. :)
'[',
string-join(
  $RESPONSE/search:boxes/search:box[ @count gt 0 ] ! text {
    '[', string-join(xs:string((@s, @w, @n, @e, @count)), ','), ']' },
  ','),
']'

(: views/appbuilder/map.json.xqy :)