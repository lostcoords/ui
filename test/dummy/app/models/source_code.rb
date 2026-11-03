require "prism"

class SourceCode
  STYLES = {
    keyword: "text-(--syntax-keyword)",
    string: "text-(--syntax-string)",
    symbol: "text-(--syntax-symbol)",
    call: "text-(--syntax-call)",
    tag: "text-(--syntax-tag)",
    comment: "text-(--syntax-comment)"
  }.freeze

  LEXERS = {
    javascript: %r{(?<comment>//[^\n]*|/\*.*?\*/)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)|(?<keyword>\b(?:async|await|break|case|catch|class|const|continue|default|else|export|extends|false|finally|for|from|function|if|import|let|new|null|of|return|static|super|switch|this|throw|true|try|typeof|var|while)\b)|(?<symbol>\b\d+(?:\.\d+)?\b)|(?<call>\b[a-zA-Z_$][\w$]*(?=\s*\())}m,
    css: %r{(?<comment>/\*.*?\*/)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?<keyword>@[\w-]+)|(?<symbol>--[\w-]+|\#[\da-fA-F]{3,8}\b|\b\d+(?:\.\d+)?(?:px|rem|em|ms|s|%|ch|vh|vw)?\b)|(?<call>[a-zA-Z-]+(?=\s*:))}m
  }.freeze

  def self.tokens(source, language: :erb)
    return ruby_tokens(source) if language == :ruby
    return scanned_tokens(source, LEXERS.fetch(language)) if LEXERS.key?(language)
    return [ [ nil, source ] ] unless language == :erb

    source.split(/(<%.*?%>)/m).flat_map do |part|
      if (match = part.match(/\A(<%[=#-]?)(.*?)(-?%>)\z/m))
        body = match[1].end_with?("#") ? [ [ :comment, match[2] ] ] : ruby_tokens(match[2])
        [ [ :keyword, match[1] ], *body, [ :keyword, match[3] ] ]
      else
        part.split(/(<!--[\s\S]*?-->|<\/?[a-zA-Z][\w:-]*|\/?>|[\w:-]+(?=\s*=)|"[^"]*"|'[^']*')/).map do |text|
          type = if text.start_with?("<!--") then :comment
          elsif text.start_with?("<", ">", "/>") then :tag
          elsif text.start_with?('"', "'") then :string
          elsif text.match?(/\A[\w:-]+\z/) then :symbol
          end
          [ type, text ]
        end
      end
    end
  end

  def self.scanned_tokens(source, lexer)
    position = 0
    tokens = []
    source.to_enum(:scan, lexer).each do
      match = Regexp.last_match
      type = match.names.find { |name| match[name] }
      tokens << [ nil, source[position...match.begin(0)] ]
      tokens << [ type.to_sym, match[0] ]
      position = match.end(0)
    end
    tokens << [ nil, source[position..] ]
  end
  private_class_method :scanned_tokens

  def self.ruby_tokens(source)
    position = 0
    tokens = Prism.lex(source).value.filter_map do |token, _state|
      next if token.type == :EOF

      start = token.location.start_offset
      finish = token.location.end_offset
      next if start < position

      gap = source.byteslice(position...start)
      position = finish
      type = case token.type.to_s
      when /KEYWORD/ then :keyword
      when /STRING|HEREDOC|REGEXP/ then :string
      when /SYMBOL|LABEL|INTEGER|FLOAT|CONSTANT/ then :symbol
      when /COMMENT/ then :comment
      when /IDENTIFIER/ then :call
      end
      [ [ nil, gap ], [ type, source.byteslice(start...finish) ] ]
    end.flatten(1)
    tokens << [ nil, source.byteslice(position..) ]
  end
  private_class_method :ruby_tokens
end
