xquery version "1.0-ml";

(: Generates a tab bar, using the tabs defined in config.xqy
 :)

module namespace t = "http://marklogic.com/roxy/tabs-lib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace c = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";
import module namespace lh = "http://www.marklogic.com/roxy/view-helper/layout"
  at "/app/views/helpers/layout-lib.xqy";

declare variable $TAB-COUNT := 0;

declare function t:tabs(
  $tabset as element(c:tabset),
  $active as xs:integer,
  $query-string as xs:string?)
as element()
{
  element ul {
    attribute role { "tablist" },
    attribute class {
      "ui-tabs-nav", 'ui-helper-reset', 'ui-helper-clearfix',
      'ui-widget-content', 'ui-corner-all' },
    for $tab at $x in $tabset/c:tab
    let $is-active := ($x eq $active)
    return element li {
      attribute class {
        "ui-state-default", 'ui-corner-top',
        if (not($is-active)) then ()
        else ('ui-tabs-active', 'ui-state-active')  },
      element a {
        (: Handle subtabs without reusing access keys. :)
        attribute accesskey { $TAB-COUNT + $x },
        $tab/@* ! (
          typeswitch(.)
          case attribute(href) return (
            if ($is-active) then ()
            else attribute href {
              .||(
                if (not(contains(., '?'))) then $query-string
                else replace($query-string, '\?', '&amp;')) })
          default return .),
        $tab/string() } } },
  xdmp:set($TAB-COUNT, count($tabset/c:tab))
};

declare function t:maybe-wrap(
  $tabset as element(c:tabset)?,
  $active as xs:integer?,
  $query-string as xs:string?,
  $body as node()*)
as node()*
{
  lh:maybe-wrap(
    exists($tabset) and exists($active),
    element div {
      attribute id { "tabs" },
      attribute class {
        "ui-tabs", 'ui-widget', 'ui-widget-header', "ui-corner-all",
        'web-interface' },
      t:tabs($tabset, $active, $query-string) },
      $body)
};

declare function t:maybe-wrap(
  $tabset as element(c:tabset)?,
  $active as xs:integer?,
  $query-string as xs:string?)
as node()*
{
  t:maybe-wrap($tabset, $active, $query-string, ())
};

(: tabs-lib.xqy :)
