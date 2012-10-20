package com.github.jknack.handlebars.internal;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.antlr.runtime.CommonToken;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;

import com.github.jknack.handlebars.Handlebars;

@RunWith(Parameterized.class)
public class HbsRunnerTest {

  protected String input;

  public HbsRunnerTest(final String input) {
    this.input = input;
  }

  public static Object[] $(final String input) {
    return new Object[] {input };
  }

  @Parameters
  public static Collection<Object[]> data() {
    Collection<Object[]> data = Arrays.asList(
        $("Hello {{this}}!"),
        $("Block {{#world}}!{{/world}}"),
        $("Delimiters {{=<< >>=}}\n<<#world>> aja <</world>>{{html}}!"),
        $("IF/ELSE {{#world}}...{{else}}***{{/world}}"),
        $("Unescaped {{{world}}}"),
        $("Unescaped {{&world}}"),
        $("Comment {{! ... world ... }}"),
        $("Parent {{../../p.[0].name}}"),
        $("DOT {{.}}"),
        $("QID {{user.name}}"),
        $("QID {{user.[10]}}"),
        $("QID {{user.['foo bar]}}"),
        $("var {{var context param0 hash=1 hashStr=\"str\" bool=true}}"),
        $("true false"),
        $("{{helper . b=true}}"),
        $("{{array.[0]}}"),
        $("{{=<% %>=}}(<%text%>)")
        );

    return data;
  }

  @Test
  public void tokens() throws RecognitionException {
    HbsParser parser =
        HbsParserFactory.create(new Handlebars(), "inline.hbs", input);

    try {
      parser.template();
    } finally {
      printTokens(parser);
    }
  }

  private void printTokens(final HbsParser parser) {
    CommonTokenStream tokenStream = (CommonTokenStream) parser.getTokenStream();
    @SuppressWarnings("unchecked")
    List<CommonToken> tokens = tokenStream.getTokens();
    String[] tokenNames = parser.getTokenNames();
    String format = "%s: '%s'\n";
    for (int i = 0; i < tokens.size(); i++) {
      CommonToken token = tokens.get(i);
      String tokenName =
          token.getType() == -1 ? "EOF" : tokenNames[token.getType()];
      System.out.printf(format, tokenName, token.getText());
    }
    System.out.println();
  }
}
