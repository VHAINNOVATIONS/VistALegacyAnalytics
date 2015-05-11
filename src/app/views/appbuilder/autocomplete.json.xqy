xquery version "1.0-ml";

import module namespace c = "http://marklogic.com/roxy/config"
 at "/app/config/config.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
 at "/roxy/lib/view-helper.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
 at "/MarkLogic/json/json.xqy";

declare variable $M := (
  let $m := map:map()
  (: Split each label into code and short-description. :)
  let $_ := map:keys(vh:get("results")) ! map:put(
    $m, substring-before(., ' '), substring-after(., ' '))
  return $m) ;

(: Expect an identity map of on:concept labels,
 : formatted like 'E001.1 Running'
 : Return a json array of these strings.
 :)
xdmp:to-json($M)

(: autocomplete.json.xqy :)