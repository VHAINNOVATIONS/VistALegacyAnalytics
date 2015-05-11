xquery version "1.0-ml";

import module namespace uv = "http://www.marklogic.com/roxy/user-view"
  at "/app/views/helpers/user-lib.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
 at "/roxy/lib/view-helper.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";


if (xdmp:get-request-method() = 'POST'
    and xdmp:login(vh:required("username"), vh:required("password")))
then xdmp:redirect-response((vh:get("redirect-to"), '/')[1])
else uv:login-form(vh:get("redirect-to"))

(: login.html.xqy :)
