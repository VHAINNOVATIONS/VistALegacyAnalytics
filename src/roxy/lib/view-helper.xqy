(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)
xquery version "1.0-ml";

module namespace vh = "http://marklogic.com/roxy/view-helper";

import module namespace rh = "http://marklogic.com/roxy/routing-helper" at "/roxy/lib/routing-helper.xqy";

declare option xdmp:mapping "false";

declare variable $vh:map as map:map external;

declare variable $HEAD-SCRIPTS := (
  <head xmlns="http://www.w3.org/1999/xhtml">
  {
    for $src in (
      "/js/lib/less-1.3.3.min.js",
      "/js/lib/jquery-1.10.1.min.js",
      "/js/lib/jquery-ui-1.9.2.custom.min.js",
      "/js/lib/jquery.cookie.js",
      "/js/lib/jquery.dataTables.min.js",
      "/js/lib/jquery.deserialize.js",
      "/js/app.js")
    return element script {
      attribute src { $src },
      attribute type { 'text/javascript' } }
  }
  </head>/*
);

declare function vh:required($name as xs:string)
{
  let $value := map:get($vh:map, $name)
  return
    if (fn:exists($value)) then
      $value
    else
      fn:error(xs:QName("MISSING-PARAM"), $name)
};

declare function vh:render($view as xs:string, $format as xs:string)
{
  rh:render-view($view, $format, $vh:map)
};

declare function vh:render($view as xs:string, $format as xs:string, $data as map:map)
{
  rh:render-view($view, $format, $data)
};

declare function vh:get($name as xs:string)
{
  map:get($vh:map, $name)
};

declare function vh:add-value($key as xs:string, $value as item()*)
{
  map:put($vh:map, $key, (map:get($vh:map, $key), $value))
};

declare function vh:set-value($key as xs:string, $value as item()*)
{
  map:put($vh:map, $key, $value)
};
