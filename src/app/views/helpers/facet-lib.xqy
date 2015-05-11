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

module namespace facet = "http://marklogic.com/roxy/facet-lib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace srch = "http://marklogic.com/appservices/search"
 at "/MarkLogic/appservices/search/search.xqy";
(: This module contains unsupported and undocumented APIs. :)
import module namespace srchimp = "http://marklogic.com/appservices/search-impl"
 at "/MarkLogic/appservices/search/search-impl.xqy";

import module namespace trans = "http://marklogic.com/translate"
    at "/MarkLogic/appservices/utils/translate.xqy";

import module namespace cfg = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

declare namespace lbl = "http://marklogic.com/xqutils/labels";

declare namespace search = "http://marklogic.com/appservices/search";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $FACET-LIMIT := 10;

declare variable $NAMESPACE := namespace-uri(<facet:x/>) ;

declare option xdmp:mapping "false";

declare function facet:value-maybe-quote(
  $v as xs:string)
as xs:string
{
  (: Make sure any non-word characters are quoted.
   : This may cause problems if we ever run into quotes within values.
   :)
  if (not(matches($v, '\W'))) then $v
  else '"'||$v||'"'
};

declare function facet:query-pair(
  $name as xs:string,
  $value as xs:anyAtomicType)
as xs:string
{
  $name||':'||$value
};

declare function facet:query-string(
  $request-extra as xs:string*,
  $query as xs:string*)
as xs:string
{
  if (empty(($query, $request-extra))) then ''
  else concat(
    '?',
    string-join($request-extra, '&amp;'),
    if (empty($request-extra)) then '' else '&amp;',
    if (empty($query)) then '' else 'q=',
    encode-for-uri(string-join($query[.], ' ')))

};

declare function facet:query-string(
  $query as xs:string*)
as xs:string
{
  facet:query-string((), $query)
};

declare function facet:path-rebuild(
  $request-extra as xs:string*,
  $query as xs:string?)
as xs:string
{
  facet:query-string($request-extra, $query)
};

declare function facet:constraint-remove(
  $qtext as xs:string,
  $options as element(srch:options),
  $ref as element(),
  $prefix as xs:string)
as xs:string
{
  srch:remove-constraint(
    $qtext,
    (: Handle quoting as needed for qtextconst. :)
    if ($ref/@qtextconst) then $ref/@qtextconst/string() ! (
        if (not(matches(., '\s+'))) then .
        else $prefix||xdmp:describe(substring-after(., $prefix), 1024))
    (: Handle prefix and postfix text, eg quotes. :)
    else concat(
      $prefix,
      $ref/cts:annotation/@qtextpre,
      $ref/cts:value,
      $ref/cts:annotation/@qtextpost),
    $options)
};

(: Do some pre-processing to encapsulate facet controller logic. :)
declare function facet:model(
  $facets as element(srch:facet)*,
  $pseudo-facets as element(facet:pseudo-facet)*,
  $qtext as xs:string?,
  $query as schema-element(cts:query)?,
  $req-extra as xs:string*,
  $options as element(srch:options))
 as element(facet:model)*
{
  (: This code expects the presence of some srch:parse annotations,
   : and will not work correctly without them.
   : Watch out for the cts:query constructor, which strips them out.
   :
   : First, look for selected vs unselected facets.
   : When creating new query terms we use
   : the first available joiner for the grammar.
   : There does not seem to be any good way to select the "best" one.
   :)
  let $joiner as xs:string := (
    $options/srch:grammar/srch:joiner[@apply eq 'constraint'])[1]
  for $f in $facets
  let $name := $f/@name/string()
  let $prefix := concat($name, $joiner)
  let $ref := ($query/descendant-or-self::*[
      @qtextpre eq $prefix or starts-with(@qtextconst, $prefix)])[1]
  return element facet:model {
    $f/@*,
    (: Build an href to remove the facet selection. :)
    if ($ref) then attribute href {
      facet:query-string(
        $req-extra,
        facet:constraint-remove($qtext, $options, $ref, $prefix)) }
    (: Build the values. :)
    else (
      for $v in $f/srch:facet-value
      let $new-term := (
        if (exists($ref)) then ()
        else $name||$joiner||facet:value-maybe-quote($v))
      return element facet:value {
        attribute href {
          facet:query-string(
            $req-extra,
            srch:unparse(srch:parse(($qtext, $new-term), $options))) },
        $v/@*,
        $v/node() }) }
,

  (: Pseudo-facets must supply a name and an href.
   : Change nothing.
   :)
  for $pf in $pseudo-facets
  return element facet:model {
    $pf/@name treat as attribute(),
    $pf/@selected,
    if ($pf[@selected]) then ($pf/@href treat as attribute())
    else $pf/facet:value }
};

declare function facet:facet(
  $facet as element(facet:model),
  $index as xs:integer,
  $labels as element(lbl:labels))
as element(div)
{
  let $match := exists($facet[@href])
  let $name as xs:string := $facet/@name
  let $translated-name := trans:translate($name, $labels, (), "en")
  let $values-count := count($facet/srch:facet-value)
  let $list-items := (
    for $value in $facet/facet:value
    let $title := (
      trans:translate($value/@name, $labels, (), "en"), $value/string())[1]
    return element li {
      element a {
        attribute href { $value/@href },
        if ($title eq "") then <em>(empty)</em> else $title },
      element i { concat(' (', $value/@count, ')') } })
  return element div {
    attribute class {
      "category", concat("category-", $index),
      if (not($match)) then () else "selected-category" },
    attribute data-facet {$name},
    element h4 {
      attribute title {
        "Collapse", $translated-name, "category" },
      $translated-name,
      element img {
        attribute class {"remove_facet"},
        attribute src {"/images/delete_remove.png"},
        attribute title {"Hide facet"}
        }},
    element ul { subsequence($list-items, 1, $FACET-LIMIT) },
    if ($values-count le $FACET-LIMIT) then () else element div {
      element ul {
        attribute id { concat("all_", $name) },
        subsequence($list-items, 1 + $FACET-LIMIT) },
      element li {
        attribute id { concat("view_toggle_", $name) },
        attribute class { "list-toggle" },
        '&#x2026;More' } } }
};

declare function facet:facets(
  $facets as element(facet:model)*,
  $qtext as xs:string?,
  $query as schema-element(cts:query)?,
  $req-extra as xs:string*,
  $options as element(srch:options),
  $labels as element(lbl:labels))
 as element(div)+
{
  (: header :)
  <div class="sidebar-header" arcsize="5 0 0 0">
  {
    if (exists($facets[@href])) then "Patients filtered by"
    else "Filter patients"
  }
  </div>,

  (: controls :)
  for $c in $facets[@href]
  return facet:chiclet(
    $c/@href, facet:chiclet-title($c/@name, $c/@selected, $labels))
  ,

  (: display :)
  for $f at $x in $facets return facet:facet($f, $x, $labels)
  ,

  <div class="category" id="diagnosisDateInputs">
    <h4>Diagnosis Date</h4>
    <input type="text" id="start_date" class="datefield" placeholder="start date"/><br/>
    <input type="text" id="end_date" class="datefield" placeholder="end date"/><br/>
    <button id="apply_date">Apply</button>
  </div>
  ,

  <div>
    <select id="addfacet_select">
      <option value="none">--- Add Facet ---</option>
  {
    let $facet-names := $facets/@name/string()
    for $name in $cfg:SEARCH-OPTIONS/search:constraint[
      node()/@facet eq true()]/@name
    where not($name = $facet-names)
    return element option {
      attribute value { $name },
      trans:translate($name, $labels) }
  }
    </select>
  </div>
};

declare function facet:facets(
  $facets as element(srch:facet)*,
  $pseudo-facets as element(facet:pseudo-facet)*,
  $qtext as xs:string?,
  $query as schema-element(cts:query)?,
  $req-extra as xs:string*,
  $options as element(srch:options),
  $labels as element(lbl:labels))
 as element(div)+
{
  facet:facets(
    facet:model($facets, $pseudo-facets, $qtext, $query, $req-extra, $options),
    $qtext, $query, $req-extra,
    $options, $labels)
};

declare function facet:chiclet-title(
  $name as xs:string,
  $value as xs:string?,
  $labels as element(lbl:labels))
as xs:string
{
  text {
    trans:translate($name, $labels, (), "en"),
    if (not($value)) then ()
    else xdmp:describe(trans:translate($value, $labels, (), "en")) }
};

declare function facet:chiclet(
  $href as xs:string,
  $title as xs:string)
{
  element div {
    attribute class { "facet" },
    attribute title { "Remove", $title },
    element a {
      attribute href { $href },
      attribute class { "close" },
      element span { '&#160;' } },
    element div {
      attribute class { "label" },
      attribute title { $title },
      $title } }
};

(:~ Parse custom facet. :)
declare function facet:facet-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query),
  $element as element(cts:element)*,
  $attribute as element(cts:attribute)*,
  $path as xs:string*)
as schema-element(cts:query)
{
  (: The $element and $attribute *must* declare any prefixes in-scope. :)
  element {
    xs:QName(
      if (exists($attribute)) then 'cts:element-attribute-range-query'
    else if (exists($element)) then 'cts:element-range-query'
    else if (exists($path)) then 'cts:path-range-query'
    else error((), 'UNIMPLEMENTED')) } {
    attribute operator { "=" },
    attribute qtextconst {
      $ctext||facet:value-maybe-quote($right/cts:text) },
    $element,
    $attribute,
    if (empty($path)) then () else element cts:path { $path },
    <cts:value xsi:type="xs:string">{ $right/cts:text/string() }</cts:value>,
    <cts:option>collation=http://marklogic.com/collation/codepoint</cts:option>
  }
};

(:~ Parse custom facet. :)
declare function facet:facet-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query),
  $element as element(cts:element)+)
as schema-element(cts:query)
{
  facet:facet-parse($ctext, $right, $element, (), ())
};

(:~ Parse custom facet. :)
declare function facet:facet-substanceAbuse-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query))
{
  facet:facet-parse(
    $ctext, $right, (), (),
    '/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:substanceAbuse')
};

(:~ Parse custom facet. :)
declare function facet:facet-psychiatryClassSeverity-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query))
{
  facet:facet-parse(
    $ctext, $right, (), (),
    '/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:psychiatryClassSeverity')
};

(:~ Parse custom facet. :)
declare function facet:facet-suicideSelfInflictIndicator-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query))
{
  facet:facet-parse(
    $ctext, $right, (), (),
    '/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:suicideSelfInflictIndicator')
};

(: Directly copied from search-impl.xqy
 : and extended to handle facet-start-value.
 :)
declare function facet:facet-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
{
  cts:values(
    srchimp:construct-reference(
      (: Expect the true constraint to be nested,
       : and use strong typing to enforce the requirement.
       : However the options must be on the custom constraint.
       : Extend this list as needed using an XPath union.
       :)
      $constraint/srch:custom/(srch:range) treat as element()),
    $constraint/srch:custom/srch:facet-start-value,
    ($facet-options, "concurrent"),
    $query,
    $quality-weight,
    $forests)
};

(:~ Finish custom facet. :)
declare function facet:facet-finish(
  $start as item()*,
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as element(srch:facet)
{
  element srch:facet {
    $constraint/@name,
    $constraint/srch:custom/srch:range/@type,
    for $i in $start return element srch:facet-value {
      attribute name { $i },
      attribute count { cts:frequency($i) },
      $i } }
};

declare function facet:addQuotesToFacetUrl($link)
{

  if(not(contains($link, '%3A'))) then $link
  else
      let $q := substring-after($link, 'q=')
      let $url := substring-before($link, 'q=')
      let $tokens := tokenize($q, '%20')
      let $stringWithQuotes := ()
      let $_ := (
      for $token in $tokens
        return
          if(contains($token, '%3A')) then
            (: new string :)
            let $innerTokens := tokenize($token, '%3A')
            let $updatedValue := concat($stringWithQuotes, '%22%20', $innerTokens[1], '%3A%22', $innerTokens[2])
            let $_ := xdmp:set($stringWithQuotes, $updatedValue)
            return ()
          else
            (: append to previous token :)
            let $updatedValue := concat($stringWithQuotes || '%20' || $token)
            let $_ := xdmp:set($stringWithQuotes, $updatedValue)
            return ()
      )
      let $stringWithQuotes := concat($stringWithQuotes, '%22')
      let $stringWithQuotes := fn:substring($stringWithQuotes, 7, fn:string-length($stringWithQuotes) - 5)
      return concat($url,"q=", $stringWithQuotes)
};


(: facet-lib.xqy :)