xquery version "1.0-ml";

module namespace waaw = "http://ps.marklogic.com/waaw";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $HIGHLIGH-OPTIMIZE := true();
declare variable $ASSUME-MAX-CHARS-PER-WORD := 7;


declare variable $stops as map:map :=
  let $m := map:map()
  let $add :=
    for $w in ("p", "ul", "li", "br", "a", "about", "above", "above", "across", "after", "afterwards", "again", "against", "all", "almost", "alone", "along", "already", "also","although","always","am","among", "amongst", "amoungst", "amount",  "an", "and", "another", "any","anyhow","anyone","anything","anyway", "anywhere", "are", "around", "as",  "at", "back","be","became", "because","become","becomes", "becoming", "been", "before", "beforehand", "behind", "being", "below", "beside", "besides", "between", "beyond", "bill", "both", "bottom","but", "by", "call", "can", "cannot", "cant", "co", "con", "could", "couldnt", "cry", "de", "describe", "detail", "do", "done", "down", "due", "during", "each", "eg", "eight", "either", "eleven","else", "elsewhere", "empty", "enough", "etc", "even", "ever", "every", "everyone", "everything", "everywhere", "except", "few", "fifteen", "fify", "fill", "find", "fire", "first", "five", "for", "former", "formerly", "forty", "found", "four", "from", "front", "full", "further", "get", "give", "go", "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter", "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his", "how", "however", "hundred", "ie", "if", "in", "inc", "indeed", "interest", "into", "is", "it", "its", "itself", "keep", "last", "latter", "latterly", "least", "less", "ltd", "made", "many", "may", "me", "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly", "move", "much", "must", "my", "myself", "name", "namely", "neither", "never", "nevertheless", "next", "nine", "no", "nobody", "none", "noone", "nor", "not", "nothing", "now", "nowhere", "of", "off", "often", "on", "once", "one", "only", "onto", "or", "other", "others", "otherwise", "our", "ours", "ourselves", "out", "over", "own","part", "per", "perhaps", "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming", "seems", "serious", "several", "she", "should", "show", "side", "since", "sincere", "six", "sixty", "so", "some", "somehow", "someone", "something", "sometime", "sometimes", "somewhere", "still", "such", "system", "take", "ten", "than", "that", "the", "their", "them", "themselves", "then", "thence", "there", "thereafter", "thereby", "therefore", "therein", "thereupon", "these", "they", "thickv", "thin", "third", "this", "those", "though", "three", "through", "throughout", "thru", "thus", "to", "together", "too", "top", "toward", "towards", "twelve", "twenty", "two", "un", "under", "until", "up", "upon", "us", "very", "via", "was", "we", "well", "were", "what", "whatever", "when", "whence", "whenever", "where", "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", "whether", "which", "while", "whither", "who", "whoever", "whole", "whom", "whose", "why", "will", "with", "within", "without", "would", "yet", "you", "your", "yours", "yourself", "yourselves", "the")
    return map:put($m, $w, true())
  return $m;

(: optimization method to get a text envelope around a keyword. Restrictign area of interest avoids cts:stem of every word :)
declare function waaw:match-area-around($text-elem as element(), $kwd as xs:string, $chars-before-and-after as xs:int) as element(area)* {
  let $n := $chars-before-and-after
  let $word-q := cts:word-query($kwd, ("case-insensitive", "punctuation-insensitive"))
  let $match-areas := cts:walk($text-elem, $word-q, <area>{substring(string-join($text-elem/text(), " "), $cts:start - $n, 2*$n)}</area>)
  (:   let $log := xdmp:log(text{"*** match areas= ", $match-areas})  :)
  return $match-areas
  };

(: return the top $n map keys, based on a numeric value associated with each key in the map :)
declare function waaw:top-n($m as map:map, $n as xs:int) as element(word)* {
 (for $k in map:keys($m)
  let $val := map:get($m, $k)
  order by $val descending
  return <word freq="{$val}">{$k}</word>
  )[1 to $n]
};


declare function waaw:get-stemmed-words-within-envelope($text-node as text(), $match-pos as xs:int, $words-around as xs:int) as xs:string* {

  let $chars-around := $words-around * $ASSUME-MAX-CHARS-PER-WORD
  let $char-envelope := substring($text-node, $match-pos - $chars-around, $chars-around *2)
  let $toks := cts:tokenize(lower-case($char-envelope))[ . instance of cts:word ]
  return subsequence($toks, 2, count($toks)-2) ! cts:stem(.)[1]
};

declare function waaw:words-around-for-doc($d, $q, $env-size-words) as xs:string* {
  cts:walk( $d, $q, waaw:get-stemmed-words-within-envelope($cts:node, $cts:start, $env-size-words))
};

declare function waaw:words-around(
    $records as element()*, $kwds as xs:string*,
    $env-size-words as xs:int, $max-num as xs:int
   )

{
  let $update-stops := for $k in $kwds return map:put($stops, $k, true()) (: consider $kwd a stop word so we do not return it for the phrase-size=1 case:)

  let $q := cts:or-query($kwds)
  let $all-words :=
    for $doc in $records
    return waaw:words-around-for-doc($doc, $q, $env-size-words)

  let $freq-map := map:map()
  let $put-in-map :=
    for $w in $all-words
      let $old-count := map:get($freq-map, $w)
      where not(map:get($stops, $w))
      return map:put($freq-map, $w, if ($old-count) then $old-count + 1 else 1)

  return waaw:top-n($freq-map, $max-num) (: only return the top n matches :)
};

(: Get words around a list of input words
   $words: Words to search for, e.g., ("chest", "pain")
   $sample-size: How big of a sample size to use (e.g., 25).  Higher values are more useful, but slower.
   $envelope-size: Number of words before and after a hit, not counting the hit word itself or stop words
   $top-matches-num: Number of top matches to return; e.g., 10 to get the 10 top matches.
 :)
declare function waaw:get-words-around-words($words as xs:string*, $sample-size as xs:int, $envelope-size as xs:int, $top-matches-num)
{
    if ($envelope-size < 2) then
      fn:error((),"'$envelope-size' must be greater than 2")
    else
      (: let $records := cts:search(doc(), cts:or-query($words))[1 to $sample-size] :)
      let $records := cts:search(doc(), cts:and-query(($words, cts:directory-query("/vpr/", "infinity"))))[1 to $sample-size]
      return waaw:words-around($records/node() , $words, $envelope-size, $top-matches-num)
};
