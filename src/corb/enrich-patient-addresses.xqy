xquery version "1.0-ml";

declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util="ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace geo = "http://marklogic.com/geocode" at "/lib/geocode.xqy";

declare variable $URI as xs:string external;

declare function local:enrich-address($address as element(va:address))
{
  let $lat-long := geo:address-to-latlong(
    string-join(
      ($address/@streetLine1, $address/@city,
        $address/@stateProvince, $address/@postalCode),
      ', '))
  return
    if($lat-long = "true" or $lat-long = "false") then
        $lat-long
    else
        ( attribute { xs:QName("geo:lat") } { $lat-long[1] },
          attribute { xs:QName("geo:lon") } { $lat-long[2] } )
};

declare function local:add-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return if ($element/@*[node-name(.) = $attrName])
                           then ()
                           else attribute {$attrName}
                                          {$attrValues[$seq]},
                    $element/@*,
                    $element/node() }
};

declare function local:add-patient-location-element($vpr as element(), $patientAddress as element())
   as xs:boolean
{
  (:
    create an element with the following example structure
    <patient-location geo:lat="31.82978" geo:lon="-81.17022" xmlns:va="ns://va.gov/2012/ip401" xmlns:geo="http://marklogic.com/geocode"/>
    and add it to the patient address.  Return true if the address was enriched, false if it wasn't.
  :)

  let $geo-attributes := local:enrich-address($patientAddress)
  let $wasEnriched := (
     if ($geo-attributes = "true") then
        true()
     else if ($geo-attributes = "false") then
        false()
     else
        let $geo-element := element { "va:patient-location"} { $geo-attributes }
        let $geo-element-enhanced := local:add-attributes($geo-element, xs:QName('xmlns:va'), "ns://va.gov/2012/ip401")
        let $_ := xdmp:node-insert-child($patientAddress, $geo-element-enhanced)
        return true()
  )
  return $wasEnriched
};

let $vpr := doc($URI)/va:vpr
let $patientAddress := $vpr/va:results/va:demographics/va:patient/va:address
return
    if($patientAddress) then
        let $_ := xdmp:node-delete($patientAddress/va:patient-location)
        let $googleEnrichedAddress := local:add-patient-location-element($vpr, $patientAddress)
        return
            if($googleEnrichedAddress) then
                let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:patientAddressEnrichment'))
                return $URI
            else
                (: Geo-coding limit was either exceeded or an error occurred in the web service call. :)
                $URI
    else
        (: There were no patient addresses to enrich, set the indicator so the record is not submitted again in the future :)
        let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:patientAddressEnrichment'))
        return $URI