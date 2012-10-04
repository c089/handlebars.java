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
  body*
  ;

body:
  expression |
  TEXT {System.out.println("text: " + $TEXT);}
  ;

expression:
  OPEN
  (
    HASH ID |
    INCLUDE ID |
    AMP ID |
    ID
  )
  CLOSE
  {System.out.println("expr: " + $expression.text);}
  ;

HASH:
  '#'
  ;

INCLUDE:
  '>'
  ;

AMP:
  '&'
  ;

OPEN:
  '{{'
  ;

CLOSE:
  '}}'
  ;

ID :
  ('a'..'z'|'A'..'Z')+
  ;

TEXT:
  (~OPEN)+
  ;

