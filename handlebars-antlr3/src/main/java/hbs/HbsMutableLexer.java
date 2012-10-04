package hbs;

import org.antlr.runtime.CharStream;
import org.antlr.runtime.MismatchedTokenException;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.RecognizerSharedState;

public class HbsMutableLexer extends HbsLexer {

  private String open = "{{";

  private String close = "}}";

  public HbsMutableLexer() {
  }

  public HbsMutableLexer(final CharStream input) {
    super(input);
  }

  public HbsMutableLexer(final CharStream input,
      final RecognizerSharedState state) {
    super(input, state);
  }

  @Override
  public void mOPEN() throws RecognitionException {
    match(open);
    state.type = OPEN;
    state.channel = DEFAULT_TOKEN_CHANNEL;
  }

  @Override
  public void mCLOSE() throws RecognitionException {
    match(close);
    state.type = CLOSE;
    state.channel = DEFAULT_TOKEN_CHANNEL;
  }

  protected String look(final int length) {
    StringBuilder look = new StringBuilder();
    for (int i = 1; i < length + 1; i++) {
      look.append((char) input.LA(i));
    }
    return look.toString();
  }

  @Override
  public void mTokens() throws RecognitionException {
    super.mTokens();
  }

  @Override
  public void mTEXT() throws RecognitionException {
    int idx = input.index();
    int nextChar = input.LA(1);
    while (nextChar != EOF && !open.equals(look(open.length()))) {
      input.consume();
      nextChar = input.LA(1);
    }
    if (idx == input.index()) {
      MismatchedTokenException mte =
          new MismatchedTokenException(nextChar, input);
      recover(mte);
      throw mte;
    }
    state.type = TEXT;
    state.channel = DEFAULT_TOKEN_CHANNEL;
  }
}
