xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/patient";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace va = "ns://va.gov/2012/ip401";

import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare namespace db = "http://marklogic.com/xdmp/database";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";

declare variable $site := req:get("site", "", "type=xs:string");
declare variable $id := req:get("id", "", "type=xs:string");

declare function c:summary()
{
    let $patient := (/va:vpr[va:meta/va:site = $site and va:meta/va:id = $id])[1]
    return (
      ch:set-value("patient", $patient),
      ch:use-layout((), "html"),
      ch:add-value("title", "Health Summary"),
      ch:use-layout("full-page", "html")
    )
};
