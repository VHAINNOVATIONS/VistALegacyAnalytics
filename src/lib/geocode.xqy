xquery version "1.0-ml";

module namespace geo = "http://marklogic.com/geocode";
declare namespace http = "xdmp:http";

declare variable $DEBUG := fn:false() ;

declare variable $PAT-ADDRESS := fn:concat(
  "^(.*?)(\d{1,7} (([^ \n])*,?( |\n)?){1,7}",
  '(Alabama|AL|Alaska|AK|Arizona|AZ|Arkansas|AR|California|CA|Colorado|CO|Connecticut|CT|Delaware|DE|Florida|FL|Georgia|GA|Hawaii|HI|Idaho|ID|Illinois|IL|Indiana|IN|Iowa|IA|Kansas|KS|Kentucky|KY|Louisiana|LA|Maine|ME|Maryland|MD|Massachusetts|MA|Michigan|MI|Minnesota|MN|Mississippi|MS|Missouri|MO|Montana|MT|Nebraska|NE|Nevada|NV|New Hampshire|NH|New Jersey|NJ|New Mexico|NM|New York|NY|North Carolina|NC|North Dakota|ND|Ohio|OH|Oklahoma|OK|Oregon|OR|Pennsylvania|PA|Rhode Island|RI|South Carolina|SC|South Dakota|SD|Tennessee|TN|Texas|TX|Utah|UT|Vermont|VT|Virginia|VA|Washington|WA|West Virginia|WV|Wisconsin|WI|Wyoming|WY|District of Columbia|DC)',
  ",? (\d{5}|\d{5}-\d{4}))(.*?)$") ;

declare function geo:address-to-latlong($address-string as xs:string) {
  let $address-string := fn:replace(fn:normalize-space($address-string), " ", "+")
  let $log := if (fn:not($DEBUG)) then () else xdmp:log(text{"Sending geocoding request for address", $address-string})
  return
    if ($address-string) then

      let $url := fn:concat("http://maps.googleapis.com/maps/api/geocode/xml?address=", $address-string, "&amp;sensor=false")
      let $response := xdmp:http-get($url)
      let $log := if (fn:not($DEBUG)) then () else xdmp:log(text{"Response for request", $url, "is", $response[2]})
      let $status := $response[2]/GeocodeResponse/status

      return
          if ((fn:string($response[1]/http:code) = "200") and ($status = "OK")) then
            let $loc := $response[2]/GeocodeResponse/result/geometry/location
            return (fn:data($loc/lat), fn:data($loc/lng))
          else if ((fn:string($response[1]/http:code) = "200") and ($status = "ZERO_RESULTS")) then
            (: web service call was successful but the location of the address couldn't be resolved :)
            "true"
          else
            (: Web service call was not successful :)
            "false"
    else
        (: An address string was not passed in :)
        "false"
};

declare function geo:markup-addresses-in-text($text as xs:string)
as node()*
{
  (: TODO this relies on MarkLogic-specific regex behavior,
   : which might be a bug and might disappear in future release.
   : TODO Rewrite as a simple parser?
   :
   : The match for $2 will always be the last one available.
   : The suffix $3 will not contain another address.
   : The prefix $1 *may* contain another address.
   :)
  if (fn:not(fn:matches($text, $PAT-ADDRESS, 'is'))) then text { $text }
  else (
    let $addr := fn:replace($text, $PAT-ADDRESS, "$2", "is")
    return (
      if (fn:not(fn:normalize-space($addr))) then $text
      else (
        geo:markup-addresses-in-text(
          fn:replace($text, $PAT-ADDRESS, "$1", "is")),
        let $geo := element geo:address { $addr }
        return geo:resolve-addresses($geo),
        fn:replace($text, $PAT-ADDRESS, "$3", "is") ! text { . })))
};

declare function geo:resolve-addresses($nodes as node()*) {
  for $node in $nodes
    return
    typeswitch($node)
      case text() return $node
      case element(geo:address) return
        let $normalized := fn:normalize-space($node/text())
        let $latlong := geo:address-to-latlong($normalized)
        return if ($latlong != "true" and $latlong != "false") then
          element {xs:QName("geo:address")} {
            (: Call to google earth webservice was successful :)
            attribute googleEarthSuccess {"true"},
            attribute normalized {$normalized},
            attribute {xs:QName("geo:lat")} {$latlong[1]},
            attribute {xs:QName("geo:lon")} {$latlong[2]},
            $node/text()
          }
        else
          element {xs:QName("geo:address")} {
            (: Call to google earth webservice was successful :)
            attribute googleEarthSuccess {$latlong},
            attribute normalized {$normalized},
            $node/text()
          }
      default return geo:resolve-addresses($node/node())
};
