xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/user";

(: The controller helper methods control view and template rendering. :)
import module namespace ch = "http://marklogic.com/roxy/controller-helper"
  at "/roxy/lib/controller-helper.xqy";

(: The request helper methods abstract get-request-field. :)
import module namespace req = "http://marklogic.com/roxy/request" at
 "/roxy/lib/request.xqy";

declare option xdmp:mapping "false";

(:
 : Usage Notes:
 :
 : use the ch library to pass variables to the view
 :
 : use the request (req) library to get access to request parameters easily
 :
 :)
declare function c:profile() as item()*
{
  ch:set-value('title', 'VistA Analytics'),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};

declare function c:login() as item()*
{
  ch:set-value('title', 'VistA Analytics'),
  ch:set-value("username"),
  ch:set-value("password"),
  ch:set-value("redirect-to"),
  ch:use-view((), "xml"),
  ch:use-layout('minimal', "html")
};

declare function c:logout() as item()*
{
  ch:set-value('title', 'VistA Analytics'),
  ch:set-value("redirect-to", '/user/login'),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};

(: controllers/user.xqy :)
