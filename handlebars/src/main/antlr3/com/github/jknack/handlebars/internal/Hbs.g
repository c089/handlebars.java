grammar Hbs;

@header {
package com.github.jknack.handlebars.internal;

import java.util.*;
import org.antlr.runtime.BitSet;
import com.github.jknack.handlebars.*;
import java.net.URI;
import java.io.IOException;
}

@lexer::header {
package com.github.jknack.handlebars.internal;
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

  protected boolean partial = false;

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
    this.open = open.trim();
    this.close = close.trim();
  }

}

@members {
  protected Handlebars handlebars;

  protected String filename;

  protected Map<String, Partial> partials;

  protected LinkedList<Stacktrace> stacktraceList;

  public HbsParser(Handlebars handlebars, String filename, TokenStream input,
    Map<String, Partial> partials, final LinkedList<Stacktrace> stacktraceList) {
    this(input, new RecognizerSharedState());
    this.filename = filename;
    this.handlebars = handlebars;
    this.partials = partials;
    this.stacktraceList = stacktraceList;
  }

  protected Variable newVar(Variable.Type type, String text, Token token,
    List<Object> params, Map<String, Object> hashes) {
    Variable variable = new Variable(handlebars, text, type, params,
      hashes);

    variable
      .filename(filename)
      .position(token.getLine(), token.getCharPositionInLine());
    return variable;
  }

  @Override
  public void displayRecognitionError(final String[] tokenNames,
      final RecognitionException e) {
    String hdr = getErrorHeader(e);
    String msg = getErrorMessage(e, tokenNames);
    throw new HandlebarsException(new HandlebarsError(filename, e.line,
        e.charPositionInLine, msg, msg,
        hdr + msg));
  }

  @Override
  public String getSourceName() {
    return filename;
  }
}

template returns[BaseTemplate root]
  :
    body {root=$body.template;}
  ;

body returns [TemplateList template = new TemplateList()]
  :
  (
    TEXT                {template.add(new Text($TEXT.getText()));} // text
  | WS                  {template.add(new Blank($WS.getText()));}  // spaces
  | NL                  {template.add(new Blank($NL.getText()));}  // new lines
  | b=block             {template.add($b.template);}               // {{#each}}
  | i=inverted          {template.add($i.template);}               // {{^ }}
  | p=partial           {template.add($p.template);}               // {{> }}
  | setDelimiters       // {{= =}}
  | a=ampersandVariable {template.add($a.template);}               // {{&variable}}
  | t=tripleVariable    {template.add($t.template);}               // {{{variable}}}
  | v=variable          {template.add($v.template);}               // {{variable}}
  )*
  ;

block returns[Block template]
  :
    OPEN_BLOCK openId=QID params hashes CLOSE
    {
      HbsLexer lexer = (HbsLexer) input.getTokenSource();
      template = new Block(handlebars, $openId.text, false, $params.result,
        $hashes.result);

      template
        .startDelimiter(lexer.open)
        .endDelimiter(lexer.close)
        .position($openId.getLine(), $openId.getCharPositionInLine())
        .filename(filename);

    }
      b=body
    (
      OPEN_INVERTED CLOSE
      i=body
      {
        template.inverse($i.template);
      }
    )?
    OPEN_ENDBLOCK closeId=QID CLOSE
    {
      if (!$openId.text.equals($closeId.text)) {
        throw new IllegalStateException("Make me better");
      }
      template.body($b.template);
    }
  ;

inverted returns[Block template]
  :
    OPEN_INVERTED openId=QID params hashes CLOSE
    {
      HbsLexer lexer = (HbsLexer) input.getTokenSource();
      template = new Block(handlebars, $openId.text, true, $params.result,
        $hashes.result);

      template
        .startDelimiter(lexer.open)
        .endDelimiter(lexer.close)
        .position($openId.getLine(), $openId.getCharPositionInLine())
        .filename(filename);
    }
      b=body
    OPEN_ENDBLOCK closeId=QID CLOSE
    {
      if (!$openId.text.equals($closeId.text)) {
        throw new IllegalStateException("Make me better");
      }
      template.body($b.template);
    }
  ;

partial returns[Partial template]
  :
    OPEN_PARTIAL p=PATH CLOSE
    {
      String uri = $p.getText();
      TemplateLoader loader = handlebars.getTemplateLoader();
      if (uri.startsWith("/")) {
        throw new IllegalStateException(
            "found: '" + loader.resolve(uri)
                + "', partial shouldn't start with '/'");
      }
      template = partials.get(uri);
      if (template == null) {
        try {
          HbsLexer lexer = (HbsLexer) input.getTokenSource();
          Stacktrace stacktrace =
              new Stacktrace($p.getLine(), $p.getCharPositionInLine(), filename);
          stacktraceList.addFirst(stacktrace);
          String input = loader.loadAsString(URI.create(uri));
          HbsParser parser =
              HbsParserFactory.create(handlebars, uri, input, partials,
                  lexer.open, lexer.close, stacktraceList);
          // Avoid stack overflow exceptions
          template = new Partial();
          partials.put(uri, template);
          template.template(uri, parser.template());
        } catch (IOException ex) {
          throw new IllegalStateException("The partial '" + loader.resolve(uri)
              + "' could not be found", ex);
        } finally {
          stacktraceList.removeLast();
        }
      }
    }
  ;

variable returns[Variable template]
  :
    OPEN QID params hashes CLOSE
  {
    template = newVar(Variable.Type.VAR, $QID.text, $QID, $params.result,
      $hashes.result);
  }
  ;

ampersandVariable returns[Variable template]
  :
    OPEN_AMP_UNESCAPED QID params hashes CLOSE
  {
    template = newVar(Variable.Type.AMPERSAND_VAR, $QID.text, $QID,
      $params.result, $hashes.result);
  }
  ;

tripleVariable returns[Variable template]
  :
    OPEN_UNESCAPED QID params hashes CLOSE_UNESCAPED
  {
    template = newVar(Variable.Type.TRIPLE_VAR, $QID.text, $QID,
      $params.result, $hashes.result);
  }
  ;

setDelimiters
  :
    // {{=?? ??=}}
    OPEN_DELIM WS* SET_OPEN WS+ SET_CLOSE WS*
    {
      HbsLexer lexer = (HbsLexer) input.getTokenSource();
      lexer.setDelimiters($SET_OPEN.text, $SET_CLOSE.text);
    }
    CLOSE_DELIM
  ;

params returns[List<Object> result = new ArrayList<Object>();]
  :
    (p=param {result.add(p);})*
  ;

param returns[Object value]
  :
    STRING      {value = $STRING.getText();}
  | INT         {value = Integer.parseInt($INT.getText());}
  | BOOLEAN     {value = Boolean.valueOf($BOOLEAN.getText());}
  | QID         {value = $QID.text;}
  ;

hashes returns [Map<String, Object> result = new HashMap<String, Object>();]
  :
    (h = hash {result.put(h.key, h.value);})*
  ;

hash returns [String key, Object value]
  :
  id=QID {$hash.key=$id.getText();} EQ
  (
      STRING      {$hash.value = $STRING.getText();}
    | INT         {$hash.value = Integer.parseInt($INT.getText());}
    | BOOLEAN     {$hash.value = Boolean.valueOf($BOOLEAN.getText());}
    | v=QID {$hash.value = $v.getText();}
  )
  ;

/*
qid
  :
    (
        DOT
      | PARENT+ ID (DOT ID)*
      | ID (DOT ID)*
    )
  ;
*/

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
    {ahead(open + ">")}?=> {match(open + ">"); inside = true; partial = true;}
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

BOOLEAN
  :
    {inside}?=> ('true' | 'false')
  ;

PATH
  :
    {partial}?=> NAME_START (NAME_END | '/' | '\\')* {partial=false;}
  ;

fragment
DOT
  :
    {inside}?=> '.'
  ;

QID
  :
    DOT
  | PARENT+ ID (DOT (ID | SUFFIX))*
  | ID (DOT (ID | SUFFIX))*
  ;

ID:
  {inside}?=> NAME_START NAME_END*
  ;

fragment
NAME_START
  :
    ('a'..'z' | 'A'..'Z' | '_' | '$' | '@')
  ;

fragment
NAME_END
  :
    (NAME_START | '0'..'9' | '-')
  ;

fragment
PARENT
  :
    {inside}?=> '../'
  ;

fragment
SUFFIX
  :
    {inside}?=> '[' .* ']'
  ;

STRING
  :
  {inside}?=> '"' (ESC | ~( '\\' | '"' | '\r' | '\n' ))* '"'
    {
      String text = $text;
      setText(text.replace("\\\"", "\""));
    }
  ;

fragment
ESC
  :
    '\\'
    (
         'b'
     |   't'
     |   'n'
     |   'f'
     |   'r'
     |   '\"'
     |   '\''
     |   '\\'
     )
  ;

INT
  :
  {inside}?=> ('0'..'9')+
  ;

EQ
  :
  {inside}?=> '='
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
  {!inside && !ahead(open)}?=> {matchText();}
  ;
