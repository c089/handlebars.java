package hbs;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

public class HbsRunner {

  /**
   * @param args
   * @throws RecognitionException
   */
  public static void main(final String[] args) throws RecognitionException {
    ANTLRStringStream input = new ANTLRStringStream("Hello {{this}}!");

    HbsMutableLexer lexer = new HbsMutableLexer(input);

    CommonTokenStream stream = new CommonTokenStream(lexer);

    HbsParser parser = new HbsParser(stream);

    parser.template();
  }

}
