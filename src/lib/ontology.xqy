xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : lib/ontology.xqy
 :
 : @author Brad Mann
 :
 : This library module implements ontology transformation for ICD-9 and SNOMED
 :
 :)
module namespace on = "ns://va.gov/2012/ip401/ontology";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: TODO maybe separate namespaces for ICD9, SNOMED, etc? :)
declare default element namespace "ns://va.gov/2012/ip401/ontology" ;

declare namespace va = "ns://va.gov/2012/ip401" ;

declare namespace dea = "ns://va.gov/2012/ip401/ontology/dea" ;
declare namespace enr = "ns://va.gov/2012/ip401/enrichment" ;
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;

import module namespace srch = "http://marklogic.com/appservices/search"
 at "/MarkLogic/appservices/search/search.xqy";
(: Yes, this is dangerous. :)
import module namespace srchimp = "http://marklogic.com/appservices/search-impl"
 at "/MarkLogic/appservices/search/search-impl.xqy";

declare variable $NAMESPACE := namespace-uri(<on:concept/>) ;
declare variable $NAMESPACE-DEA := namespace-uri(<dea:dea/>) ;
declare variable $NAMESPACE-ENRICH := namespace-uri(<enr:x/>) ;
declare variable $NAMESPACE-RXNORM := namespace-uri(<rx:rxnorm/>) ;
declare variable $NAMESPACE-VPR := namespace-uri(<va:vpr/>) ;
declare variable $ONTOLOGY-URI := '/ontology/' ;
declare variable $ICD9-URI := $ONTOLOGY-URI||'ICD9/' ;
declare variable $RXNORM-URI := $ONTOLOGY-URI||'rxnorm/' ;

declare variable $WORD-QUERY-OPTIONS := ('case-insensitive', 'stemmed') ;

declare function on:query()
as cts:directory-query
{
  cts:directory-query($ONTOLOGY-URI, 'infinity')
};

declare function on:query-icd9()
as cts:directory-query
{
  cts:directory-query($ICD9-URI, 'infinity')
};

declare function on:query-rx()
as cts:directory-query
{
  cts:directory-query($RXNORM-URI, 'infinity')
};

(:~ Construct an ICD9 node :)
declare function on:concept-icd9(
  $code as xs:string,
  $description as xs:string,
  $short-description as xs:string)
as element(on:concept)
{
  <concept>
  {
    attribute code { $code },
    attribute description { $description },
    attribute short-description { $short-description },
    element query {
      attribute code { $code },
      cts:element-word-query(
        (: The elements where we expect to find ontology concepts. :)
        (xs:QName('va:content'), xs:QName('va:commentText')),
        distinct-values(($description, $short-description)),
        $WORD-QUERY-OPTIONS) }
  }
  </concept>
};

(:~ Construct an RXNORM reverse-query node :)
declare function on:rxnorm-reverse-query(
  $atom as element(rx:atom)+)
as element(rx:query)
{
  (: This means we have a bug in our code,
   : putting distinct concepts into the same document. :)
  if (count(distinct-values($atom/rx:rxcui)) eq 1) then ()
  else error((), 'BAD', text { 'Bad input:', $atom/rx:rxcui }),
  element rx:query
  {
    attribute rxcui { $atom[1]/rx:rxcui },
    cts:element-word-query(
      (: The elements where we expect to find ontology concepts. :)
      (xs:QName('va:content'), xs:QName('va:commentText')),
      distinct-values($atom/rx:str ! normalize-space(lower-case(.))),
      $WORD-QUERY-OPTIONS) }
};

(:~ Construct an ontology concept node :)
declare function on:concept(
  $type as xs:string,
  $raw as element())
as element(on:concept)
{
  if ($type eq 'ICD9') then on:concept-icd9(
    $raw/on:icd9code, $raw/on:long_description, $raw/on:short_description)
  else error((), 'UNIMPLEMENTED', $type)
};

(:~ Construct an ICD9 uri :)
declare function on:uri-icd9(
  $code as xs:string)
as xs:string
{
  concat(
    $ICD9-URI,
    (: handle trailing-dot codes :)
    if (ends-with($code, '.')) then $code
    else replace($code, '\.', '/'))
};

(:~ Construct an ontology uri :)
declare function on:uri(
  $type as xs:string,
  $code as xs:string)
as xs:string
{
  if ($type eq 'ICD9') then on:uri-icd9($code)
  else error((), 'UNIMPLEMENTED', $type)
};

(:~
 : Transforms an ICD-9 string into XML and stores it in the database,
 : along with cts:query elements for cts:reverse-query()
 : @param $input The string representation of the input document
 :)
declare function on:transform-icd9($input as xs:string)
as empty-sequence()
{
  for $line in subsequence(fn:tokenize($input, "&#10;"), 2)
  let $tokens := fn:tokenize($line, ",")
  let $concept := on:concept-icd9($tokens[1], $tokens[2], $tokens[3])
  let $uri := on:uri-icd9($concept/@code)
  return xdmp:document-insert($uri, $concept)
};

(:~
 : Transforms a SNOMED string into XML and stores it in the database,
 : along with cts:query elements for cts:reverse-query()
 : NOTE: We probably won't be using this.
 : @param $input the string representation of the input document
 :)
declare function on:transform-snomed($input as xs:string) as node() {
  error((), 'UNIMPLEMENTED')
};

(:~
 : Transforms an ontology entry into XML and stores it in the database,
 : along with cts:query elements for cts:reverse-query()
 : @param $input The string representation of the input document
 : @param $type The type of ontology document this is
 :)
declare function on:transform($input as xs:string, $type as xs:string) {
  if ($type = 'ICD9') then on:transform-icd9($input)
  else if ($type = 'SNOMED') then on:transform-snomed($input)
  else error((), 'UNIMPLEMENTED')
};


(:~ Produce a map key for a cts:query.
 : Map keys must be xs:string.
 : Happily we know that cts:register returns deterministic results,
 : and is cheap to call.
 :)
declare function on:query-key(
  $query as cts:query)
as xs:string
{
  xdmp:integer-to-hex(cts:register($query))
};

declare function on:enrichment-nodes(
  $list as xs:string+)
as attribute()+
{
  attribute code { $list[1] },
  (: concatenate both code and short description :)
  attribute label { $list }
};

(:~ Parse on:concept custom facet. :)
declare function on:facet-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query),
  $element as element(cts:element)+,
  $attribute as element(cts:attribute)*)
as schema-element(cts:query)
{
  (: The $element and $attribute *must* declare any prefixes in-scope. :)
  element {
    if (exists($attribute)) then xs:QName('cts:element-attribute-range-query')
    else xs:QName('cts:element-range-query') } {
    attribute operator { "=" },
    attribute qtextconst { $ctext||$right/cts:text },
    $element,
    $attribute,
    <cts:value xsi:type="xs:string">{ $right/cts:text/string() }</cts:value>,
    <cts:option>collation=http://marklogic.com/collation/codepoint</cts:option>
  }
};

(:~ Parse on:concept custom facet. :)
declare function on:facet-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query),
  $element as element(cts:element)+)
as schema-element(cts:query)
{
  on:facet-parse($ctext, $right, $element, ())
};

(:~ Start custom facet with code-label format. :)
declare function on:facet-start-label(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*,
  $element as xs:QName+,
  $attribute as xs:QName+)
as item()*
{
  (: NB - Use of undocumented, but non-private, API. :)
  srchimp:element-attribute-range-facet-start(
    <constraint xmlns="http://marklogic.com/appservices/search">
      { $constraint/@* }
      <range type="xs:string" facet="true">
    {
      $element ! element element {
        attribute ns { namespace-uri-from-QName(.) },
        attribute name { local-name-from-QName(.) } },
      $attribute ! element attribute {
        attribute ns { namespace-uri-from-QName(.) },
        attribute name { local-name-from-QName(.) } },
      $facet-options ! element facet-option { . }
    }
      </range>
    </constraint>,
    $query, $facet-options, $quality-weight, $forests)
};

(:~ Finish custom facet with code-label format. :)
declare function on:facet-finish-label(
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
    $constraint/srch:range/@type,
    $start ! element srch:facet-value {
      attribute name { substring-after(., ' ') },
      attribute count { cts:frequency(.) },
      substring-before(., ' ') } }
};

(:~ Parse on:concept custom facet. :)
declare function on:facet-concept-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query) )
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:on="ns://va.gov/2012/ip401/ontology">on:concept</cts:element>,
    <cts:attribute>code</cts:attribute>)
};

(:~ Start on:concept custom facet. :)
declare function on:facet-concept-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('on:concept'), QName('', 'label'))
};

(:~ Parse va:icd custom facet. :)
declare function on:facet-diag-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:va="ns://va.gov/2012/ip401">va:icd</cts:element>)
};

(:~ Start va:icd custom facet. :)
declare function on:facet-diag-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('va:icd'), QName('', 'label'))
};

(:~ Parse va:class custom facet. :)
declare function on:facet-vadc-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query) )
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:va="ns://va.gov/2012/ip401">va:class</cts:element>,
    <cts:attribute>code</cts:attribute>)
};

(:~ Start va:class custom facet. :)
declare function on:facet-vadc-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('va:class'), QName('', 'label'))
};

(:~ Parse rx:concept custom facet. :)
declare function on:facet-rxnorm-note-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query) )
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:rx="ns://va.gov/2012/ip401/ontology/rxnorm">rx:concept</cts:element>,
    <cts:attribute>code</cts:attribute>)
};

(:~ Start rx:concept custom facet. :)
declare function on:facet-rxnorm-note-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('rx:concept'), QName('', 'label'))
};

(:~ Parse rx:concept vadc custom facet. :)
declare function on:facet-vadc-note-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query) )
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:rx="ns://va.gov/2012/ip401/ontology/rxnorm">rx:concept</cts:element>,
    <cts:attribute>vadc-code</cts:attribute>)
};

(:~ Start rx:concept vadc custom facet. :)
declare function on:facet-vadc-note-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('rx:concept'), QName('', 'vadc-label'))
};

(:~ Parse enr:loinc custom facet. :)
declare function on:facet-loinc-parse(
  $ctext as xs:string,
  $right as schema-element(cts:query) )
as schema-element(cts:query)
{
  on:facet-parse(
    $ctext, $right,
    <cts:element
      xmlns:enr="ns://va.gov/2012/ip401/enrichment">enr:loinc</cts:element>,
    <cts:attribute>code</cts:attribute>)
};

(:~ Start enr:loinc custom facet. :)
declare function on:facet-loinc-start(
  $constraint as element(srch:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  on:facet-start-label(
    $constraint, $query, $facet-options, $quality-weight, $forests,
    xs:QName('enr:loinc'), QName('', 'label'))
};

declare function on:prep-code($code)
{
  if(contains($code, '.')) then
    $code
  else
    $code || '.'
};

declare function on:get-icd9-concept($code)
{
  let $code := on:prep-code($code)
  let $decimal := substring-after($code, '.')
  return
    if ( string-length($decimal) lt 3 ) then
      let $description := doc(on:uri-icd9($code))
      return
        if ( not(empty($description)) ) then
          $description
        else
          on:get-icd9-concept($code || '0')
    else ()
};

declare function on:get-concept-by-code($code)
{
  let $description := on:get-icd9-concept($code)
  return
    if ( not(empty($description)) ) then
      $description
    else
      let $_ := xdmp:log('Warning: get-icd9-description-by-code() Unable to find icd9 description for icd9 code of: ' || $code)
      return ()
};

(: lib/ontology.xqy :)
