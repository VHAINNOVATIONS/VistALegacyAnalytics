xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

declare option xdmp:mapping "false";
declare variable $_user := vh:get("user");

(: use the vh:required method to force a variable to be passed. it will throw an error
 : if the variable is not provided by the controller :)
(:
  declare variable $title as xs:string := vh:required("title");
    or
  let $title as xs:string := vh:required("title");
:)

(: grab optional data :)
(:
  declare variable $stuff := vh:get("stuff");
    or
  let $stuff := vh:get("stuff")
:)

vh:add-value("view-css",<link href="/css/saved-search.less" type="text/css" rel="stylesheet/less"/>),
<div xmlns="http://www.w3.org/1999/xhtml" class="resultsContainer">
  <h2>Saved searches</h2>
  <div>
       <table id="savedSearches" class="data_table">
            <thead>
               <tr>
                    <th style="width:150px">Date</th>
                    <th>Description</th>
                    <th style="width:30px">Delete</th>
               </tr>
            </thead>
           <tbody>
           </tbody>
       </table>
   </div>

</div>,
vh:add-value("view-js", <scripts xmlns="http://www.w3.org/1999/xhtml"><script src="/js/saved-search.js" type="text/javascript"></script></scripts>/*)



