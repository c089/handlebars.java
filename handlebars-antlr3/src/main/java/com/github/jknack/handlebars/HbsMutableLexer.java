package hbs;

import java.util.LinkedList;

import org.antlr.runtime.CharStream;
import org.antlr.runtime.MismatchedSetException;
import org.antlr.runtime.RecognitionException;

public class HbsMutableLexer extends HbsLexer {

  private String open;

  private String close;

  private LinkedList<Integer> stack = new LinkedList<Integer>();

  public HbsMutableLexer(final CharStream input, final String open,
      final String close) {
    super(input);
    this.open = open;
    this.close = close;
    stack.add(TEXT);
  }

  public HbsMutableLexer(final CharStream input) {
    this(input, "{{", "}}");
  }

  @Override
  public void mOPEN() throws RecognitionException {
    match(open, OPEN);
  }

  @Override
  public void mCLOSE() throws RecognitionException {
    match(close, CLOSE);
  }

  public void mWS(final int channel) throws RecognitionException {
    super.mWS();
    state.channel = channel;
  }

  @Override
  public void mDELIM() throws RecognitionException {
    int nextChar = input.LA(1);
    while (nextChar != EOF && !Character.isWhitespace(nextChar)
        && !Character.isJavaIdentifierPart(nextChar)) {
      input.consume();
      nextChar = input.LA(1);
    }
    state.type = TEXT;
    state.channel = DEFAULT_TOKEN_CHANNEL;
  }

  @Override
  public void mTokens() throws RecognitionException {
    int type = peek();
    switch (type) {
      case TEXT:
        text();
        break;
      case OPEN:
        expression();
        break;
      case COMMENT:
        mCOMMENT_BODY();
        break;
    }
  }

  private void text() throws RecognitionException {
    if (matches(open)) {
      // {{
      push(OPEN);
      mOPEN();
    } else {
      int ch = input.LA(1);
      if (Character.isWhitespace(ch)) {
        mWS(DEFAULT_TOKEN_CHANNEL);
      } else {
        mTEXT();
      }
    }
  }

  private void expression() throws RecognitionException {
    if (matches(close)) {
      // }}
      pop();
      mCLOSE();
      return;
    }
    char ch = token(1).charAt(0);
    switch (ch) {
      case '#':
        mHASH();
        break;
      case '^':
        mINVERTED();
        break;
      case '>':
        mINCLUDE();
        break;
      case '{':
        mLEFT();
        break;
      case '}':
        mRIGHT();
        break;
      case '=':
        mEQ();
        break;
      case '/':
        mSLASH();
        break;
      case '!':
        push(COMMENT);
        mCOMMENT();
        break;
      default:
        if (matches("true") || matches("false")) {
          mBOOLEAN();
        } else if (Character.isJavaIdentifierStart(ch)) {
          mID();
        } else if (Character.isWhitespace(ch)) {
          mWS(HIDDEN);
        } else if (Character.isDigit(ch)) {
          mINT();
        } else if (ch == '"') {
          mSTRING();
        } else if (!Character.isJavaIdentifierPart(ch)) {
          mDELIM();
        } else {
          MismatchedSetException ex = new MismatchedSetException(null, input);
          recover(ex);
          throw ex;
        }
    }
  }

  @Override
  public void mCOMMENT_BODY() throws RecognitionException {
    int nextChar = input.LA(1);
    while (nextChar != EOF && !matches(close)) {
      input.consume();
      nextChar = input.LA(1);
    }
    state.type = COMMENT_BODY;
    state.channel = DEFAULT_TOKEN_CHANNEL;
    pop();
  }

  private void match(final String token, final int type)
      throws RecognitionException {
    match(token, type, DEFAULT_TOKEN_CHANNEL);
  }

  private void match(final String token, final int type, final int channel)
      throws RecognitionException {
    match(token);
    state.type = type;
    state.channel = channel;
  }

  @Override
  public void mTEXT() throws RecognitionException {
    int nextChar = input.LA(1);
    while (nextChar != EOF && !Character.isWhitespace(nextChar)
        && !matches(open)) {
      input.consume();
      nextChar = input.LA(1);
    }
    state.type = TEXT;
    state.channel = DEFAULT_TOKEN_CHANNEL;
  }

  public void push(final int type) {
    stack.add(type);
  }

  public int pop() {
    return stack.removeLast();
  }

  public int peek() {
    return stack.getLast();
  }

  protected boolean matches(final String token) {
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
}
