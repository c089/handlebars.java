package hbs;

import java.util.List;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

public class HbsRunner {

  /**
   * @param args
   * @throws RecognitionException
   */
  public static void main(final String[] args) throws RecognitionException {
    run("Hello {{this}}!");

    run("Block {{#world}}!{{/world}}");

    run("Delimiters {{=<< >>=}}\n<<#world>> aja <</world>>{{html}}!");

    run("IF/ELSE {{#world}}...{{else}}***{{/world}}");

    run("Unescaped {{{world}}}");

    run("Unescaped {{&world}}");

    run("Comment {{! ... world ... }}");
  }

  private static void run(final String input) throws RecognitionException {
    ANTLRStringStream stream = new ANTLRStringStream(input);
    System.err.println(stream);

    HbsLexer lexer = new HbsLexer(stream);

    CommonTokenStream tokenStream = new CommonTokenStream(lexer);

    HbsParser parser = new HbsParser(tokenStream);

    parser.template();

    @SuppressWarnings("unchecked")
    List<CommonToken> tokens = tokenStream.getTokens();
    String[] tokenNames = parser.getTokenNames();
    String format = "%s: '%s'\n";
    for (int i = 0; i < tokens.size() - 1; i++) {
      CommonToken token = tokens.get(i);
      System.out.printf(format, tokenNames[token.getType()], token.getText());
    }
  }
}
