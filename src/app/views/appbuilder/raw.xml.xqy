xquery version "1.0-ml";

(:
 : Copyright 2012 MarkLogic Corporation
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :    http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
:)

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare option xdmp:output "indent=yes";

declare variable $path := vh:get("path");
declare variable $filename := vh:get("filename");
(
	xdmp:add-response-header('content-disposition', fn:concat("attachment; filename=", $filename)),
	xdmp:set-response-content-type('application/octet-stream'),
	xdmp:unpath($path)
)