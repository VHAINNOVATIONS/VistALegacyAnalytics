xquery version "1.0-ml";

module namespace rv = "http://marklogic.com/roxy/views/reports";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare default element namespace "http://www.w3.org/1999/xhtml" ;

import module namespace c = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

declare function rv:page(
  $id as xs:string?,
  $body as node()*)
as node()*
{
  vh:add-value(
    "sidebar",
    <div id="reports">
      <div id="availReportsList">
          <h3 style="padding-left:8px;">Available Reports</h3>
          <hr />
          <ul>
    {
      $c:REPORTS/* ! element li {
        if ($id eq @id) then string()
        else element a { @*, string() } }
    }
          </ul>
      </div>
    </div>),
  $body
};

(: reports/lib.xqy :)
