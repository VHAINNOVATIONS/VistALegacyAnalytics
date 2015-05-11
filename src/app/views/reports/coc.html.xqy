xquery version "1.0-ml";

import module namespace req = "http://marklogic.com/roxy/request"
  at "/roxy/lib/request.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

import module namespace coc = "ns://va.gov/2012/ip401/chain-of-custody"
  at "/lib/chain-of-custody.xqy";
import module namespace rv = "http://marklogic.com/roxy/views/reports"
  at "lib.xqy";
import module namespace vpr = "ns://va.gov/2012/ip401/vpr"
  at "/lib/vpr.xqy";

import module namespace admin = "http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml" ;

declare namespace db = "http://marklogic.com/xdmp/database";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $COC-LIST := vh:get('coc-list') ;
declare variable $SITE := vh:get('site') ;

declare function local:audit($results as element()*)
as element()*
{
  if (empty($results)) then <div>No differences found.</div>
  else element ul {
    for $r in $results
    let $is-missing := local-name($r) eq 'missing'
    order by $is-missing descending, $r/@id ascending
    return typeswitch($r)
    case element(coc:missing) return element li {
      <span class="coc_missing">MISSING</span>,
      element span {
        attribute class { 'coc_value' }, $r/@id/string() } }
    default return element li {
      attribute class { 'coc_diff' },
      'Difference for id', $r/@id/string(),
      element ul {
        for $f in $r/coc:field
        return element li {
          attribute class { 'coc_diff' },
          text {
            $f/@name||':',
            'expected', $f/@expected,
            'actual', $f/@actual } } } } }
};

rv:page(
  'coc',
  element div {
    <form id="coc-form" method="POST" enctype="multipart/form-data">
      <label  accesskey="c">
    Select a site, then upload a file with one id on each line.
    {
      element select {
        attribute name { 'site' },
        for $v in cts:element-values(
          xs:QName('va:site'), (),
          ('collation=http://marklogic.com/collation/codepoint'))
        return element option {
          attribute value { $v },
          if (not($v eq $SITE)) then ()
          else attribute selected { 1 },
          $v } }
    }
      <input type="file" name="coc-data" />
      <input type="submit" value="upload" />
    </label>
    </form>,

    if (empty($SITE) or empty($COC-LIST)) then ()
    else element div {
      element h2 { 'Report for CoC ids:' },
      local:audit(coc:csv-audit($SITE, $COC-LIST)),
      element h3 { 'End report' } } })

(: views/coc.html.xqy :)