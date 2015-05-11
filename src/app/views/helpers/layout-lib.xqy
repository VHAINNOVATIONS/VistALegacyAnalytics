xquery version "1.0-ml";

module namespace lh = "http://www.marklogic.com/roxy/view-helper/layout";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function lh:maybe-wrap(
  $do as xs:boolean,
  $wrapper as element(),
  $body as element()*)
as element()*
{
  if (not($do)) then $body
  else element { node-name($wrapper) } {
    $wrapper/namespace::*,
    $wrapper/@*,
    $body[ . instance of attribute() ],
    $wrapper/node(),
    $body[ not(. instance of attribute()) ] }
};

(: helpers/layout-lib.xqy :)
