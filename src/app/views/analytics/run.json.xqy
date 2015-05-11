xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace s = "http://marklogic.com/roxy/models/search" at "/app/models/search-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";
xdmp:set-response-content-type("text/html"),
xdmp:to-json(vh:get('co-occurrences'))