grammar Hbs;

@header {
package hbs;
}

@lexer::header {
package hbs;
}

@lexer::members {

  private abstract class Matcher {
    {
      int ch = input.LA(1);
      while(ch != EOF && whileNot(ch)) {
        input.consume();
        ch = input.LA(1);
      }
    }

    abstract boolean whileNot(int ch);
  }
      
  protected String open = "{{";

  protected String close = "}}";

  protected boolean inside = false;

  protected boolean delim = false;

  protected boolean setOpen = false;

  public HbsLexer(final CharStream input, final String open,
      final String close) {
    super(input);
    this.open = open;
    this.close = close;
  }

  protected boolean ahead(final String token) {
    if (input.LA(1) == EOF) {
      return false;
    }
    for (int i = 0, len = token.length(); i < len; i++) {
      char ch = (char) input.LA(i + 1);
      if (ch != token.charAt(i)) {
        return false;
      }
    }
    return true;
  }

  protected String token(final int len) {
    char[] chars = new char[len];
    for (int i = 1; i <= len; i++) {
      chars[i - 1] = (char) input.LA(i);
    }
    return new String(chars);
  }

  protected void matchText() {
    new Matcher() {
      public boolean whileNot(int ch) {
        return !Character.isWhitespace(ch) && !ahead(open);
      }
    };
  }

  protected void matchStartDelimiter() {
    new Matcher() {
      public boolean whileNot(int ch) {
        return !Character.isWhitespace(ch) && !Character.isLetterOrDigit(ch) &&
          !ahead(open) && !ahead(close);
      }
    };
  }

  protected void matchEndDelimiter() {
    new Matcher() {
      public boolean whileNot(int ch) {
        return !Character.isWhitespace(ch) && !Character.isLetterOrDigit(ch) &&
      ch != '=' && !ahead(open) && !ahead(close);
      }
    };
  }

  protected void matchComment() {
    new Matcher() {
      public boolean whileNot(int ch) {
        boolean matches = ahead(close);
        if (matches) {
          //eat the close mark too 
          for (int i = 0; i < close.length(); i++) {
            input.consume();
          }
        }
        return !matches;
      }
    };
  }

  protected void setDelimiters(String open, String close) {
    this.open = open;
    this.close = close;
  }
}

template:
  body
  ;

body
  :
  (
    TEXT              // text
  | WS                // spaces
  | NL                // new lines
  | block             // {{#each}}
  | inverted          // {{^ }}
  | partial           // {{> }}
  | setDelimiters     // {{= =}}
  | unescapedVariable // {{&variable}} OR {{{variable}}}
  | variable          // {{variable}}
  )*
  ;

block
  :
    OPEN_BLOCK ID CLOSE
      body
    (
      OPEN_INVERTED CLOSE
      body
    )?
    OPEN_ENDBLOCK ID CLOSE
  ;

inverted
  :
    OPEN_INVERTED ID CLOSE
      body
    OPEN_ENDBLOCK ID CLOSE
  ;

partial
  :
    OPEN_PARTIAL ID CLOSE
  ;

variable
  :
    OPEN ID CLOSE
  ;

unescapedVariable
  :
    OPEN_UNESCAPED ID CLOSE_UNESCAPED
  | OPEN_AMP_UNESCAPED ID CLOSE
  ;

setDelimiters
  :
    OPEN_DELIM SET_OPEN WS SET_CLOSE CLOSE_DELIM
    {
      HbsLexer lexer = (HbsLexer) input.getTokenSource();
      lexer.setDelimiters($SET_OPEN.text, $SET_CLOSE.text);
    }
  ;

// Lexer
// The order of the rules is very important

OPEN_BLOCK
  :
    {ahead(open + "#")}?=> {match(open + "#"); inside = true;}
  ;

OPEN_INVERTED
  :
    {ahead(open + "^")}?=> {match(open + "^"); inside = true;}
  | {ahead(open + "else")}?=> {match(open + "else"); inside = true;}
  ;

OPEN_UNESCAPED
  :
    {ahead(open + "{")}?=> {match(open + "{"); inside = true;}
  ;

OPEN_AMP_UNESCAPED
  :
    {ahead(open + "&")}?=> {match(open + "&"); inside = true;}
  ;

OPEN_PARTIAL
  :
    {ahead(open + ">")}?=> {match(open + ">"); inside = true;}
  ;

OPEN_ENDBLOCK
  :
    {ahead(open + "/")}?=> {match(open + "/"); inside = true;}
  ;

OPEN_DELIM
  :
    {ahead(open + "=")}?=> {match(open + "="); delim=true;}
  ;

COMMENT
  :
    {ahead(open + "!")}?=> {matchComment(); $channel=HIDDEN;}
  ;

OPEN
  :
    {ahead(open)}?=> {match(open); inside = true;}
  ;

CLOSE_UNESCAPED
  :
    {ahead("}" + close)}?=> {match("}" + close); inside = false;}
  ;

CLOSE_DELIM
  :
    {ahead("=" + close)}?=> {match("=" + close); inside = false; delim=false;}
  ;

CLOSE
  :
    {ahead(close)}?=> {match(close); inside = false;}
  ;

ID
  :
  {inside}?=> ('a'..'z' | 'A'..'Z')+
  ;

SET_OPEN
  :
  {delim && !setOpen}?=>
    {matchStartDelimiter(); setOpen=true;}
  ;

SET_CLOSE
  :
  {setOpen}?=>
    {matchEndDelimiter(); setOpen=false; delim=false;}
  ;

NL
  :
   ('\r'? '\n')+
   {
      if (inside) {
        $channel = HIDDEN;
      }
   }
  ;

WS
  :
   (' ' | '\t')+
   {
      if (inside && !delim) {
        $channel = HIDDEN;
      }
   }
  ;

TEXT:
  {!ahead(open)}?=> {matchText();}
  ;
