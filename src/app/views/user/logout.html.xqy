xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper"
 at "/roxy/lib/view-helper.xqy";

declare option xdmp:mapping "false";

declare variable $REDIRECT-TO as xs:string := vh:required("redirect-to");

xdmp:logout(),
xdmp:redirect-response($REDIRECT-TO)

(: main.logout :)
