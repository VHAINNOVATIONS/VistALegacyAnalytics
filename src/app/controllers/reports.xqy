xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/reports";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace va = "ns://va.gov/2012/ip401";

import module namespace ch = "http://marklogic.com/roxy/controller-helper"
  at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request"
  at "/roxy/lib/request.xqy";

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace cfg = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

import module namespace waaw = "http://ps.marklogic.com/waaw" at "/lib/words-around-a-word.xqy";

declare function c:main() as item()*
{
  ch:set-value('tab-active', 2),
  ch:set-value("title", "Reports"),
  let $q as xs:string := req:get("q", "", "type=xs:string")
  let $mature := req:get('mature', false(), 'type=xs:boolean')
  let $page := req:get("page", 1, "type=xs:int")
  let $options := cfg:search-options($mature, false())
  return (
    ch:set-value('search-options', $options),
    ch:set-value(
      "response",
      search:search(
        $q, $options,
        ($page - 1) * $cfg:DEFAULT-PAGE-LENGTH + 1,
        $cfg:DEFAULT-PAGE-LENGTH)),
    ch:set-value("q", $q),
    ch:set-value("mature", $mature),
    ch:set-value("page", $page)),
  ch:set-value("wide-form", true()),
  ch:add-value('additional-js', <script src="/js/reports.js">&nbsp;</script>),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};

declare function c:coc() as item()*
{
  ch:set-value('tab-active', 2),
  ch:set-value("title", "Chain of Custody Report"),
  ch:set-value('site'),
  ch:set-value(
    "coc-list",
    if (xdmp:get-request-method() ne 'POST') then ()
    else tokenize(xdmp:get-request-field('coc-data'), '[\n\r]+')[.]),
  ch:add-value('additional-js', <script src="/js/reports.js">&nbsp;</script>),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};

declare function c:vli() as item()*
{
  ch:set-value('tab-active', 2),
  ch:set-value(
    "title",
    string-join(
      ("VLI Report",
        ch:get('vli') ! (' &mdash; ', .)), '')),
  ch:set-value('vli'),
  ch:add-value('additional-js', <script src="/js/reports.js">&nbsp;</script>),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};

declare function c:transform-snippet($nodes as node()*)
{
  for $n in $nodes
  return
    typeswitch($n)
      case element(search:highlight) return
        <span class="highlight">{fn:data($n)}</span>
      case element() return
        element div
        {
          attribute class { fn:local-name($n) },
          c:transform-snippet(($n/@*, $n/node()))
        }
      default return $n
};

declare function c:buildDelimitedContextExamplesString($seed-words, $word, $numberOfWorkContextExamples,
    $envelope, $enableContextExamples)
{
    if ( fn:upper-case($enableContextExamples) eq "ENABLED") then
        let $searchResults := cts:search(doc(), cts:near-query(($seed-words, $word), $envelope, "unordered"))[1 to $numberOfWorkContextExamples]
        (: let $searchResults := cts:search(doc(), cts:near-query((cts:and-query(($seed-words, cts:directory-query(("/vpr/"), "infinity"))), $word), $envelope, "unordered"))[1 to $numberOfWorkContextExamples] :)
        return
            if(count($searchResults) > 0) then
               for $searchResult in $searchResults
                return
                  c:transform-snippet(
                    search:snippet(
                      $searchResult,
                      search:parse($word),
                      <transform-results apply="snippet"
                        xmlns="http://marklogic.com/appservices/search">
                          <per-match-tokens>30</per-match-tokens>
                          <max-matches>1</max-matches>
                          <max-snippet-chars>70</max-snippet-chars>
                      </transform-results>
                    )
                  )
            else
                ""
    else
        ""
};

declare function c:waaw() as item()*
{
  let $seed-words := fn:tokenize(req:get("words", "", "type=xs:string"), " ")
  let $sample := req:get("sample", 25, "type=xs:int")
  let $envelope := req:get("envelope", 10, "type=xs:int")
  let $reportmatches := req:get("reportmatches", 10, "type=xs:int")
  let $numberOfWorkContextExamples := req:get("wordContextExamples", 10, "type=xs:int")
  let $enableContextExamples := req:get("enableContextEx", "", "type=xs:string")
  let $words :=
    if (fn:count($seed-words) gt 0) then
      for $word in waaw:get-words-around-words($seed-words, $sample, $envelope, $reportmatches)
      let $delimitedContextExamples := c:buildDelimitedContextExamplesString($seed-words, $word,
        $numberOfWorkContextExamples, $envelope, $enableContextExamples)
      let $m := map:map()
      let $build-map :=
        (
            map:put($m, "word", $word/fn:string()),
            map:put($m, "frequency", $word/@freq/fn:string()),
            map:put($m, "contextExamples", $delimitedContextExamples)
        )
      return $m
    else
      ()
  return (
    ch:set-value('tab-active', 2),
    ch:set-value(
      "title",
      "Term Context Report"),
    ch:set-value('words', $words),
    ch:set-value('seed-words', $seed-words),
    ch:set-value('sample', $sample),
    ch:set-value('envelope', $envelope),
    ch:set-value('reportmatches', $reportmatches),
    ch:set-value('numberOfWorkContextExamples', $numberOfWorkContextExamples),
    ch:add-value('additional-js', <script src="/js/reports.js">&nbsp;</script>),
    ch:use-view((), "xml"),
    ch:use-layout((), "xml")
  )
};


(: controllers/reports.xqy :)
