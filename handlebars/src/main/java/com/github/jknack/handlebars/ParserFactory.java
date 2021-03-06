/**
 * Copyright (c) 2012 Edgar Espina
 *
 * This file is part of Handlebars.java.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.github.jknack.handlebars;

/**
 * Creates a new Handlebars parser.
 *
 * @author edgar.espina
 * @since 0.10.0
 */
public interface ParserFactory {

  /**
   * Creates a new {@link Parser}.
   *
   * @param handlebars The parser owner.
   * @param filename The file's name.
   * @param startDelimiter The start delimiter.
   * @param endDelimiter The end delimiter.
   * @return A new {@link Parser}.
   */
  Parser create(final Handlebars handlebars, final String filename, final String startDelimiter,
      final String endDelimiter);
}
