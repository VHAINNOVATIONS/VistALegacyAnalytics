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

import module namespace req = "http://marklogic.com/roxy/request"
  at "/roxy/lib/request.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

import module namespace rv = "http://marklogic.com/roxy/views/reports"
  at "lib.xqy";
import module namespace vpr = "ns://va.gov/2012/ip401/vpr"
  at "/lib/vpr.xqy";

import module namespace admin = "http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml" ;

declare namespace db = "http://marklogic.com/xdmp/database";

declare namespace va = "ns://va.gov/2012/ip401";

declare namespace enr = "ns://va.gov/2012/ip401/enrichment";

declare variable $CONFIG := admin:get-configuration() ;

declare variable $DB := xdmp:database() ;

declare variable $MAP := local:report($VLI) ;

declare variable $VLI := vh:get('vli') ;

declare variable $VPR-QUERY := vpr:site-query() ;

declare variable $LABELS := map:map(
  <map:map xmlns:map="http://marklogic.com/xdmp/map">
    <map:entry key="/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:admissionDate">
      <map:value xsi:type="xs:string">Admissions</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:dischargeDate">
      <map:value xsi:type="xs:string">Discharges</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:fld501/va:movementRecord/va:transferDate">
      <map:value xsi:type="xs:string">Transfers</map:value>
    </map:entry>
    <map:entry key="icd">
      <map:value xsi:type="xs:string">Diagnoses</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:consults/va:consult/va:requested">
      <map:value xsi:type="xs:string">Consults</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:documents/va:document/va:referenceDateTime">
      <map:value xsi:type="xs:string">Documents</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:exams/va:exam/va:dateTime">
      <map:value xsi:type="xs:string">Exams</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:flags/va:flag/va:dateTime">
      <map:value xsi:type="xs:string">Flags</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:healthFactors/va:factor/va:recorded">
      <map:value xsi:type="xs:string">Health Factors</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:immunizations/va:immunization/va:administered">
      <map:value xsi:type="xs:string">Immunizations</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:labs/va:lab/va:collected">
      <map:value xsi:type="xs:string">Labs</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:meds/va:med/va:start">
      <map:value xsi:type="xs:string">Meds</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:reactions/va:allergy/va:facility/va:facility-name">
      <map:value xsi:type="xs:string">Reactions</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:visits/va:visit/va:dateTime">
      <map:value xsi:type="xs:string">Visits</map:value>
    </map:entry>
    <map:entry key="/va:vpr/va:results/va:vitals/va:vital">
      <map:value xsi:type="xs:string">Vitals</map:value>
    </map:entry>
  </map:map>) ;

declare function local:put(
  $m as map:map,
  $key as xs:string,
  $reference as cts:reference,
  $options as xs:string*,
  $query as cts:query)
as empty-sequence()
{
  (:if (map:get($LABELS, $key) eq 'HIDE') then ():)
  if (not(map:get($LABELS, $key))) then ()
  else map:put($m, $key, cts:count-aggregate($reference, $options, $query))
};

declare function local:total-put(
  $m as map:map,
  $vli as cts:query,
  $name as xs:string)
as empty-sequence()
{
  map:put(
    $m,
    $name,
    cts:sum-aggregate(
      cts:element-attribute-reference(
        QName($vpr:NAMESPACE, $name), QName('', 'total')),
      ('item-frequency'),
      $VPR-QUERY))
};

declare function local:element-put(
  $m as map:map,
  $name as xs:string,
  $query as cts:query)
as empty-sequence()
{
  local:put(
    $m, $name,
    cts:element-reference(QName($vpr:NAMESPACE, $name)),
    ('item-frequency'), $query)
};

declare function local:path-put(
  $m as map:map,
  $path as xs:string,
  $query as cts:query)
as empty-sequence()
{
  local:put(
    $m, $path, cts:path-reference($path),
    ('item-frequency'), $query)
};

declare function local:report(
  $m as map:map, $query as cts:query, $count as xs:integer)
as map:map
{
  if ($count lt 1) then $m else (
    map:put($m, 'vpr', $count),
    (: TODO observations missing from test data, so there is nothing to facet.
     : Fix this once we have data.
     :)
    ('observations') ! local:total-put($m, $query, .),
    (: Use all VA-NS element range indexes. :)
    admin:database-get-range-element-indexes($CONFIG, $DB)[
      db:namespace-uri eq $vpr:NAMESPACE]/db:localname/xs:NMTOKENS(.)
    ! local:element-put($m, ., $query),
    (: Use most available path range indexes. :)
    admin:database-get-range-path-indexes($CONFIG, $DB)/db:path-expression[
      not(ends-with(., '/@total')
        or ends-with(., '/@label')) ]
    ! local:path-put($m, ., $query),
    $m)
};

declare function local:report($m as map:map, $query as cts:query)
as map:map
{
  local:report(
    $m, $query,
    xdmp:estimate(
      cts:search(
        collection(),
        cts:and-query(
          ($query,
            cts:element-query(
              QName($vpr:NAMESPACE, 'vpr'), cts:and-query(())))))))
};

declare function local:report($vli as xs:string)
as map:map
{
  local:report(map:map(), vpr:site-query($vli))
};

declare function local:format-key($key as xs:string)
as xs:string
{
  let $label := map:get($LABELS, $key)
  return (
    if ($label) then $label
    else if (ends-with($key, '/va:dateTime')) then local:format-key(
      replace($key, '/va:dateTime$', ''))
    else if (ends-with($key, '/va:entered')) then local:format-key(
      replace($key, '/va:entered', ''))
    else if (ends-with($key, '-name')) then local:format-key(
      replace($key, '-name', 's'))
    else if (contains($key, '/')) then local:format-key(
      tokenize($key, '/')[last()] ! (
      if (not(starts-with(., 'va:'))) then . else substring-after(., 'va:')))
    else $key ! (
      upper-case(substring(., 1, 1))
      ||replace(substring(., 2), '([A-Z])', ' $1'))
    ! replace(., '(Date|Topic)$', '$1s'))
};

declare function local:format-row($label as xs:string, $value as xs:decimal)
as element(tr)
{
  element tr {
    element th { $label },
    element td { $value } }
};

rv:page(
  'vli',
<div id="report">
  <form id="vli-form">
  <label accesskey="v">
{
  element select {
    attribute name { 'vli' },
    for $v in cts:element-values(
      xs:QName('va:site'), (),
      ('collation=http://marklogic.com/collation/codepoint'))
    return element option {
      attribute value { $v },
      if ($v ne $VLI) then () else attribute selected { 1 },
      $v } }
}
      <input type="submit" value="Report" />
    </label>
  </form>
  <div id="site">
  {
    if (not($VLI)) then ()
    else if (not(map:get($MAP, 'vpr'))) then element p {
      'no data for site', xdmp:describe($VLI) }
    else element table {
      attribute id { 'site-data' },
      attribute class { 'report-table' },
      local:format-row('Patients', map:get($MAP, 'vpr')),
      for $key in map:keys($MAP)
      let $label := local:format-key($key)
      where $key ne 'vpr'
      order by $label
      return local:format-row($label, map:get($MAP, $key)) }
  }
  </div>
</div>)

(: reports/vli.html.xqy :)
