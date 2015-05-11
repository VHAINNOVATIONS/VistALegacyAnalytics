xquery version "1.0-ml";
(:
 : Copyright (c) 2012-2013 Information Innovators Inc. All Rights Reserved.
 :
 : lib/ingest.xqy
 :
 : @author Michael Blakeley
 :
 : This library module implements patient record matching
 : and other ingestion routines.
 :
 :)
module namespace in = "ns://va.gov/2012/ip401/ingest";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace dea="ns://va.gov/2012/ip401/ontology/dea" ;
declare namespace rx="ns://va.gov/2012/ip401/ontology/rxnorm" ;
declare namespace va = "ns://va.gov/2012/ip401";

import module namespace geo = "http://marklogic.com/geocode"  at "/lib/geocode.xqy";
import module namespace cfg = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"  at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare variable $MONTHS := (
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC') ;

declare variable $NAMESPACE-VPR := namespace-uri(<va:x/>) ;

declare variable $RXNORM-VADC-STR-PAT := '^\[([A-Z][A-Z]\d\d\d)\]\s+(.+)$' ;

declare variable $VPR-URI := '/vpr/' ;

declare function in:split(
  $value as xs:string)
as xs:string*
{
  tokenize($value, ',')[. ne '']
};

declare function in:permissions(
  $value as xs:string,
  $capability as xs:string)
as element(sec:permission)*
{
  in:split($value) ! xdmp:permission(., $capability)
};

(: Canonicalize element QNames :)
declare function in:node-name($e as element())
as xs:QName
{
  QName(
    namespace-uri($e),
    local-name($e) ! (
      lower-case(substring(., 1, 1))||substring(., 2)))
};

(: copy value attribute to element value :)
declare function in:icd($e as element())
    as element(va:icd)
{
  element va:icd {
    (),
    $e/@value,
    $e/@value/string() }
};

(: Add facet label to med/class elements. :)
declare function in:class(
  $e as element())
as element(va:class)
{
  element va:class {
    (: In the test data, there are a few empty class elements. Skip them. :)
    if (not($e/@code and $e/@name)) then ()
    else attribute label {
      $e/@code
      ||' '
      ||$e/@name },
    $e/@*,
    for $a in $e/@*
    return element { in:attribute-name-map($e, $a) } {
      $a/string() } }
};

declare function in:attribute-name-map(
  $e as element(),
  $a as attribute())
as xs:QName
{
  QName(
    $NAMESPACE-VPR,
    local-name($a) ! (
      if (not(. = ('code', 'name'))) then .
      else concat(local-name($e), '-', .)))
};

declare function in:vpr-map(
  $e as element(),
  $site as xs:string)
as element()
{
  element { node-name($e) } {
    $e/@*,
    if ($e/@value
      and count($e/@*) eq 1 and empty($e/node())) then $e/@value/string()
    else (
      (: Copy attribute values to new elements with the same names.
       : Don't copy any @total.
       : Don't copy the xml attributes.
       : TODO What about xml:lang?
       :)
      $e/@*[
        not(
          node-name(.) = (QName('', 'total'))
          or namespace-uri() = ('http://www.w3.org/XML/1998/namespace'))]
      ! element { in:attribute-name-map($e, .) } {
        typeswitch(.)
        case attribute(commentText) return (.)
        default return string() },
      $e/node() ! (
        typeswitch(.)
        case element(va:content) return (.)
        case element(va:facility) return in:vpr-map(., $site)
        (: Add facet label to med/class elements. :)
        case element(va:class) return in:class(.)
        (: copy value attribute to element value :)
        case element(va:icd) return in:icd(.)
        (: Rewrite generic element names to be more descriptive. :)
        case element(va:name) return element {
          concat('va:', local-name($e), '-name') } {
          @*,
          @value/string() }
        case element() return in:vpr-map(., $site)
        default return .)) }
};

declare function in:prm-query(
  $uri as xs:string,
  $patient as element(va:patient))
as cts:query
{
  cts:and-not-query(
    cts:and-query(
      $patient/(va:ssn|va:familyName|va:givenNames|va:dob|va:died)
      ! cts:element-value-query(node-name(.), string())),
    cts:document-query($uri))
};

declare function in:identify(
  $uri as xs:string,
  $patient as element(va:patient))
as element(va:patient-references)
{
  (: Check for existing documents that appear to refer to this person.
   : Use markers specified in the PWS...
   : * SSN
   : * Last name, first name, middle name
   : * Date of birth
   : * Date of death
   : We could probably do this with cts:uris,
   : but the results would be unfiltered which might be a problem.
   : Because this is an update, any matching records will be read-locked.
   : This ensures that matching is transactional.
   :
   : As a side-effect, update the matching docs with their own pointers to $uri.
   :
   : Exclude existing copies of the same VPR.
   :)
  <patient-references xmlns="ns://va.gov/2012/ip401">
  {
    cts:search(doc(), in:prm-query($uri, $patient))/va:vpr/
    element patient-reference {
      xdmp:node-uri(.),
      if (va:patient-references/va:patient-reference = $uri)
      (: Remove any duplicated references. :)
      then xdmp:node-delete(
        subsequence(va:patient-references/va:patient-reference[. eq $uri], 2))
      (: Handle documents that have no reference parent. :)
      else if (not(va:patient-references)) then xdmp:node-insert-child(
        .,
        element patient-references { element patient-reference { $uri } })
      (: Add the new reference. :)
      else xdmp:node-insert-child(
        va:patient-references,
        element patient-reference { $uri }) }
  }
  </patient-references>
};

declare function in:add-meta(
  $uri as xs:string,
  $results as element(va:results))
as element(va:meta)
{
  <meta xmlns="ns://va.gov/2012/ip401">
  {
    element site { in:site-from-uri($uri) },
    element ingested { current-dateTime() },
    element id {fn:data($results/va:demographics/va:patient/va:id)}
  }
  </meta>
};

declare function in:vpr-wrap(
  $uri as xs:string,
  $results as element(va:results))
as element(va:vpr)
{
  <vpr xmlns="ns://va.gov/2012/ip401">
  {
    in:add-meta($uri, $results),
    $results
  }
  </vpr>
};

declare function in:site-from-uri(
  $uri as xs:string)
as xs:string
{
  (: extract site prefix from generated URI :)
  substring-before(
    if (starts-with($uri, $VPR-URI)) then substring-after($uri, $VPR-URI)
    else if (starts-with($uri, '/')) then substring-after($uri, '/')
    else if (contains($uri, '/')) then $uri
    else error((), 'UNEXPECTED', $uri),
    '/')
};

declare function in:uri(
  $site as xs:string,
  $patient as element(va:patient))
as xs:string
{
  (: extract site prefix from generated URI :)
  $VPR-URI || $site || '/' ||
  (: strong typing even with function mapping :)
  ($patient/va:id/@value treat as attribute())
};

declare function in:document-insert(
  $uri as xs:string,
  $root as node(),
  $roles-execute-csv as xs:string,
  $roles-insert-csv as xs:string,
  $roles-read-csv as xs:string,
  $roles-update-csv as xs:string,
  $collections-csv as xs:string,
  $quality as xs:int?,
  $forests-csv as xs:string)
as empty-sequence()
{
  xdmp:document-insert(
    $uri, $root,
    ('execute', 'insert', 'read', 'update') ! in:permissions(
      xdmp:value('$roles-'||.||'-csv'), .),
    in:split($collections-csv),
    $quality,
    xs:unsignedLong(in:split($forests-csv)))
};

declare function in:assert-namespace-debug($namespace as xs:string, $fragment as element()) as empty-sequence()
{
  try
  {
    in:assert-namespace($namespace)
  }
  catch($exception)
  {
     error( (), $exception, $fragment)
  }

};


declare function in:assert-namespace($namespace as xs:string)
  as empty-sequence()
{
  if ($namespace eq $NAMESPACE-VPR) then () else error(
    (), 'UNEXPECTED-NS',
  text { $namespace, 'does not match', $NAMESPACE-VPR })
};

declare function in:map-append(
  $map as map:map,
  $key as xs:string,
  $new as item()*)
as empty-sequence()
{
  map:put($map, $key, (map:get($map, $key), $new))
};

(: Find the corresponding VPR and merge.
 : This uses full name plus patied id and DFN.
 :)
declare function in:ptf-merge(
  $treatment as element(va:patientTreatment))
as empty-sequence()
{
  let $fullName as xs:string := $treatment/va:patient
  let $key := $treatment/va:key
  let $dfn as xs:string := $key/@PatientDfn
  let $number as xs:string := $key/@RecNum

  (: First try to find a record with matching id and full name   :)
  let $res as element(va:results)? := cts:search(
      xdmp:directory($VPR-URI, 'infinity'),
      cts:and-query(
        (cts:element-value-query(xs:QName('va:fullName'), $fullName),
          cts:element-value-query(xs:QName('va:id'), $dfn)))
     )/va:vpr/va:results

  return
      if (exists($res)) then
          let $pts := $res/va:patientTreatments
          let $ians := data($pts/va:patientTreatment/va:internalAdmission)
          return (
            if ($pts) then xdmp:node-insert-child($pts, $treatment)
            else xdmp:node-insert-child($res, element va:patientTreatments { $treatment }))
      else
         (: Second try to match decoded PTF terminalDigit + PTF patient name to VPR ssn + VPR fullname  :)
          let $terminalDigit := $treatment/va:terminalDigit
          let $convertedTerminalDigit := in:convertTerminalDigitToSsn($terminalDigit)
          let $res as element(va:results)? := cts:search(
            xdmp:directory($VPR-URI, 'infinity'),
                cts:and-query(
                    (cts:element-value-query(xs:QName('va:fullName'), $fullName),
                    cts:element-value-query(xs:QName('va:ssn'), $convertedTerminalDigit)))
            )/va:vpr/va:results
          return
              if (exists($res)) then
                let $pts := $res/va:patientTreatments
                let $ians := data($pts/va:patientTreatment/va:internalAdmission)
                return (
                    if ($pts) then xdmp:node-insert-child($pts, $treatment)
                    else xdmp:node-insert-child($res, element va:patientTreatments { $treatment }))
              else
                let $_ := error((), 'UNEXPECTED', 'missing VPR for PTF number: ' || $number || ', dfn: ' || $dfn
                        || ", fullName: " || $fullName || ", terminalDigit: " || $terminalDigit
                        || ", convertedTerminalDigit: " || $convertedTerminalDigit)
                return ""
};


declare function in:map-value(
  $v as xs:untypedAtomic)
as xs:anyAtomicType?
{
  (: Parse date and dateTime values,
   : and any other value parsing or mapping.
   : Cannot use xdmp:parse-dateTime()
   : because it does not like month values like SEP (SUPPORT-12451).
   :)
  let $pat := (
    '^([A-Za-z]{3})\s*(\d{2}),?'
    ||'\s*(\d{2,4})@?(\d{2})?:?(\d{2})?:?(\d{2})?$')
  return
  (
    if (not(matches($v, $pat))) then $v
    else (
      let $year := replace($v, $pat, '$3')
      let $month := replace($v, $pat, '$1')
      let $month := xs:string(index-of($MONTHS, $month))
      let $month := '0'[string-length($month) lt 2]||$month
      let $day := replace($v, $pat, '$2')
      let $date := string-join(($year, $month, $day), '-')
      let $hour := replace($v, $pat, '$4')
      let $minute := replace($v, $pat, '$5')
      let $second := (replace($v, $pat, '$6')[.], '00')[1]
      return try {
        if (not($hour and $minute)) then xs:dateTime($date||'T00:00:00')
        else xs:dateTime($date||'T'||$hour||':'||$minute||':'||$second) }
      catch ($ex) {
        if ($ex/error:code = 'XDMP-CAST') then $v
        else xdmp:rethrow() })
    )
};

declare function in:ptf-map-elem(
  $e as element())
as element()?
{
  if (empty($e/*) and deep-equal($e/@*, $e/@value) and not($e/@value/string())) then
    element { in:node-name($e) } { $e/@*, () }
  else element { in:node-name($e) } {
    $e/@*,
    if ($e/*) then in:ptf-map($e/node())
    else (
      in:map-value($e/@value) ! (
        typeswitch($e)
        case element(va:DischargeDate) return in:date-time(.)
        case element(va:AdmissionDate) return in:date-time(.)
        case element(va:TransferDate) return in:date-time(.)
        default return .)) }
};

declare function in:date-time(
  $v as xs:anyAtomicType)
as xs:dateTime?
{
  if ($v castable as xs:dateTime)
  then xs:dateTime($v)
  else ()
};

declare function in:ptf-map-fld501(
  $e as element())
as element()
{
  (: Skip a level, to avoid CODING_CLERK|FLD_535. :)
  in:ptf-map($e/node())
};

(: Split a raw PTF into treatment records.
 : Along the way, build structure from sequences of va:FLD501
 : and following-sibling::(va:CODING_CLERK|va:FLD535) as element()*.
 :)
declare function in:ptf-map(
  $n as node())
as node()*
{
  typeswitch($n)
  case document-node() return in:ptf-map($n/va:PTF)
  (: Handle "newPTF" from test data, or actual site "per". :)
  case element(va:PTF) return (
    if ($n/va:Patient/va:Patient) then in:ptf-map($n/va:Patient)
    else element va:patientTreatment { in:ptf-map($n/node()) })
  (: Disambiguate "Patient", which is used for the record and the record-id. :)
  case element(va:Patient) return (
    if (not($n/*)) then in:ptf-map-elem($n)
    else element va:patientTreatment { in:ptf-map($n/node()) })
  (: Nest FLD501 siblings. :)
  case element(va:CODING_CLERK) return ()
  case element(va:FLD501) return element va:fld501 {
    in:ptf-map($n/node()),
    let $next := $n/following-sibling::va:FLD501[1]
    let $includes := (xs:QName('va:CODING_CLERK'), xs:QName('va:FLD535'))
    return in:ptf-map-fld501(
      if (empty($next)) then $n/following-sibling::*[node-name(.) = $includes]
      else $n/following-sibling::*[node-name(.) = $includes][. << $next]) }
  (: Skip FLD535, handled elsewhere. :)
  case element(va:FLD535) return ()
  (: Default handlers. :)
  case element() return in:ptf-map-elem($n)
  default return $n
};

(: Find the corresponding VPR and merge.
 : Match on patient DFN = C&P record PatientDFN.
 :)
declare function in:cp-merge(
  $amieReport as element(va:cpRecord))
as empty-sequence()
{

  let $name := string($amieReport/va:name)
  let $dfn := string($amieReport/va:key/@PatientDfn)
  let $cpNum := string($amieReport/va:key/@RecNum)

  (: Only the fullname lookup will use indexes. :)
  (: The name test can be removed eventually.  MR 4/18/13 :)
  let $res as element(va:results)? := cts:search(
    xdmp:directory($VPR-URI, 'infinity'),
    cts:and-query(
      (cts:element-value-query(xs:QName('va:fullName'), $name),
        cts:element-value-query(xs:QName('va:id'), $dfn)))
   )/va:vpr/va:results

  let $_ := (
    if (exists($res)) then ()
    else error((), 'UNEXPECTED', 'missing VPR for CP '||$cpNum))

  let $pts := $res/va:cpRecords
  let $ians := data($pts/va:cpRecord/va:internalAdmissionN)

  where $res
  return (
    if ($pts) then xdmp:node-insert-child($pts, $amieReport)
    else xdmp:node-insert-child($res, element va:cpRecords { $amieReport }))
};


declare function in:race-merge( $raceRecord as element(va:patient)) as empty-sequence()
{
    let $dfn := string($raceRecord/va:dfn)
    let $site := string($raceRecord/va:site)
    let $uri := $VPR-URI || $raceRecord/$site || '/' || $dfn

    let $patient as element(va:patient)? := doc($uri)/va:vpr/va:results/va:demographics/va:patient

    let $_ := (
      if (exists($patient)) then ()
      else error( (), "UNEXPECTED", "missing VPR for race " || $dfn ))
    
    return 
      if ($patient/va:races) 
	then ()
      else
        let $insert := $raceRecord/va:races
	return xdmp:node-insert-child($patient, $insert)
};


declare function in:cp-map-elem(
  $e as element())
as element()
{
  element { in:node-name($e) } {
    $e/@*,
    if ($e/*) then in:cp-map($e/node())
    else in:map-value($e/@value) }
};

(: Split a raw CP into treatment records.
 :)
declare function in:cp-map(
  $n as node())
as node()*
{
  typeswitch($n)
  case document-node() return in:cp-map($n/va:AMIE_REPORT)
  case element(va:AMIE_REPORT) return in:cp-map($n/va:Name)
  (: Disambiguate "Name", which is used for the record and the record-id. :)
  case element(va:Name) return (
    if (not($n/*)) then in:cp-map-elem($n)
    else element va:cpRecord { in:cp-map($n/node()) })
  (: Default handlers. :)
  case element() return in:cp-map-elem($n)
  default return $n
};

declare function in:rxnorm-decode-vadc-str(
  $str as xs:string)
as xs:string+
{
  if (not(matches($str, $RXNORM-VADC-STR-PAT))) then $str
  else (
    replace($str, $RXNORM-VADC-STR-PAT, '$1'),
    replace($str, $RXNORM-VADC-STR-PAT, '$2'))
};

declare function in:rxnorm-append(
  $concept as element(rx:concept),
  $atom as element(rx:atom))
as empty-sequence()
{
  (: Update root attributes, but only if this atom has a VADC str. :)
  let $vadc-str := in:rxnorm-decode-vadc-str($atom/rx:str)
  return (
    if (count($vadc-str) eq 1) then ()
    else (
      xdmp:node-replace(
        $concept/@str, attribute str { $vadc-str[2] }),
      if ($concept/@vadc-code) then xdmp:node-replace(
        $concept/@vadc-code, attribute vadc-code { $vadc-str[1] })
      else xdmp:node-insert-child(
        $concept, attribute vadc-code { $vadc-str[1] }))),
  (: Update reverse-query. :)
  xdmp:node-replace(
    $concept/rx:query,
    on:rxnorm-reverse-query(($atom, $concept/rx:atom))),
  (: Update or append atom. :)
  let $atom-id as xs:string := $atom/rx:rxaui
  let $old := $concept/rx:atom[rx:rxaui eq $atom-id]
  return (
    if ($old) then xdmp:node-replace($old, $atom)
    else xdmp:node-insert-child($concept, $atom))
};

(: Handle two situations: new document
 : or merge with existing document.
 : This is necessary because documents are organized by rxcui (concept)
 : and there can be multiple entries (atoms) for each concept.
 : rxnorm reference
 : http://www.nlm.nih.gov/research/umls/rxnorm/docs/2013/rxnorm_doco_full_2013-2.html#conso
 :)
declare function in:rxnorm-insert(
  $uri as xs:string,
  $atom as element(rx:atom),
  $permissions as element(sec:permission)*,
  $collections as xs:string*,
  $quality as xs:integer?,
  $forest-ids as xs:unsignedLong*)
as empty-sequence()
{
  let $concept := doc($uri)/rx:concept
  return (
    if (exists($concept)) then in:rxnorm-append($concept, $atom)
    else xdmp:document-insert(
      $uri,
      element rx:concept {
        attribute rxcui { $atom/rx:rxcui },
        (: Set the preferred label for the concept.
         : This will be the str of the first atom found,
         : unless a later atom has a str with VADC encoded.
         : Any VADC-encoded str will be decoded.
         :)
        let $vadc-str := in:rxnorm-decode-vadc-str($atom/rx:str)
        return (
          if (count($vadc-str) eq 1) then attribute str { $atom/rx:str }
          else (
            attribute vadc-code { $vadc-str[1] },
            attribute str { $vadc-str[2] })),
        (: Build the reverse query. :)
        on:rxnorm-reverse-query($atom),
        $atom
      },
      $permissions,
      $collections,
      $quality,
      $forest-ids))
};

(: Merge DEA data into rxnorm concept.
 : Dependency: the rxnorm concepts must already be loaded.
 :)
declare function in:dea-insert(
  $uri as xs:string,
  $dea as element(dea:dea),
  $permissions as element(sec:permission)*,
  $collections as xs:string*,
  $quality as xs:integer?,
  $forest-ids as xs:unsignedLong*)
as empty-sequence()
{
  let $concept as element(rx:concept)? := cts:search(
    collection(),
    cts:and-query(
      (cts:directory-query('/ontology/rxnorm/', 'infinity'),
        cts:element-value-query(
          xs:QName('rx:str'), $dea/dea:name,
          ('case-insensitive'))))
    )[1]/rx:concept
  where $concept
  return (
    xdmp:log(
      text {
        'in:dea-insert',  xdmp:describe($concept),
        exists($concept/@dea-id) and exists($concept/@dea-schedule)},
      'debug' ),
    if (exists($concept/@dea-id) and exists($concept/@dea-schedule)) then ()
    else (
      xdmp:node-insert-child(
        $concept, attribute dea-id { $dea/dea:id }),
      xdmp:node-insert-child(
        $concept, attribute dea-schedule { $dea/dea:schedule })))
};

declare function in:convertSsnToTerminalDigit($ssn)
{
    if(string-length($ssn) = 9) then
        fn:concat( fn:substring($ssn, 8, 2),
        fn:substring($ssn, 6, 2),
        fn:substring($ssn, 4, 2),
        fn:substring($ssn, 1, 3) )
    else
        error((), 'BAD VALUE', 'ssn was not 9 digits ' || $ssn)
};

declare function in:convertTerminalDigitToSsn($terminalDigit)
{
    if(string-length($terminalDigit) = 9) then
        fn:concat( fn:substring($terminalDigit, 7, 3),
        fn:substring($terminalDigit, 5, 2),
        fn:substring($terminalDigit, 3, 2),
        fn:substring($terminalDigit, 1, 2) )
    else
        error((), 'BAD VALUE', 'terminalDigit was not 9 digits ' || $terminalDigit)
};

(: lib/ingest.xqy :)
