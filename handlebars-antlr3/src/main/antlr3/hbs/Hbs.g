grammar Hbs;

options {
  language = Java;
}

@header {
package hbs;
}

@lexer::header {
package hbs;
}

template:
  body
  ;

body:
  (
    freeText |
    expression
  )*
  ;

expression:
  OPEN
  (
    HASH block     |
    INVERTED block     |
    INCLUDE partial     |
    AMP variable[false]     |
    LEFT variable[false] RIGHT |
    EQ delimiter EQ |
    COMMENT COMMENT_BODY     |
    variable[true]
  )
  CLOSE
  ;

block:
  ID argument* hash* CLOSE body OPEN SLASH ID
  ;

argument:
  ID |
  STRING |
  INT |
  BOOLEAN;

hash:
  ID '=' ID |
  ID '=' STRING |
  ID '=' INT |
  ID '=' BOOLEAN;

partial:
  ID;

variable[boolean escape]:
  ID argument* hash*
  ;

delimiter:
  DELIM DELIM
  ;

freeText:
  TEXT
  | WS
  ;

STRING:
  '"' ~('\n' | '"')* '"'
  {
    setText($text.substring(1, $text.length()-1));
  }
  ;

INT:
  ('0'..'9')+
  ;

BOOLEAN:
  'true' |
  'false'
 ;

COMMENT_BODY:
  //Hack
  '.'
  ;

DELIM:
  //Hack
  '..'
  ;

HASH: '#';

INVERTED: '^';

INCLUDE: '>';

AMP: '&';

SLASH: '/';

LEFT: '{';

RIGHT: '}';

EQ: '=';

COMMENT: '!';

OPEN:
  '{{'
  ;

CLOSE:
  '}}'
  ;

ID :
  ID_START ID_PART*
  ;

fragment
ID_START :
  ('a'..'z'|'A'..'Z' | '_' | '$' | '@')
  ;

fragment
ID_PART :
  (ID_START | '-')
  ;

TEXT:
  //Hack!
  '*'
  ;

WS:
  (' ' | '\t' | '\r' | '\n')
  ;
