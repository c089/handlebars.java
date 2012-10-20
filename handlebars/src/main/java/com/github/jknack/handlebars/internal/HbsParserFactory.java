package com.github.jknack.handlebars.internal;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;

import com.github.jknack.handlebars.Handlebars;

public class HbsParserFactory {

  public static HbsParser create(final Handlebars handlebars,
      final String filename, final String input,
      final Map<String, Partial> partials,
      final String open, final String close,
      final LinkedList<Stacktrace> stacktraceList) {

    ANTLRStringStream stream = new ANTLRStringStream(input);

    HbsLexer lexer = new HbsLexer(stream);

    CommonTokenStream tokenStream = new CommonTokenStream(lexer);

    HbsParser parser =
        new HbsParser(handlebars, filename, tokenStream, partials,
            stacktraceList);

    return parser;
  }

  public static HbsParser create(final Handlebars handlebars,
      final String filename, final String input) {
    return create(handlebars, filename, input, "{{", "}}");
  }

  public static HbsParser create(final Handlebars handlebars,
      final String filename, final String input, final String open, final String close) {
    return create(handlebars, filename, input, new HashMap<String, Partial>(),
        open, close, new LinkedList<Stacktrace>());
  }
}
