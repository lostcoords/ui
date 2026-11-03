#!/usr/bin/env ruby

require "json"
require "open3"
require "optparse"
require "ripper"

module HelperMigration
  LIBRARY = File.expand_path("..", __dir__)
  NAMES = JSON.parse(File.read(File.join(LIBRARY, "config/helper_renames.json"))).freeze
  PARTIALS = %w[dialog disclosure].to_h do |name|
    [ "lostcoords/ui/components/ui_#{name}", "lostcoords/ui/components/lc_#{name}" ]
  end.freeze

  def self.method_locations(node, locations = {})
    return locations unless node.is_a?(Array)

    name = case node.first
    when :def, :vcall, :fcall, :command, :symbol then node[1]
    when :defs, :call, :command_call then node[3]
    end
    locations[name[2]] = true if name.is_a?(Array) && name.first == :@ident
    node.each { |child| method_locations(child, locations) }
    locations
  end

  def self.rewrite(source, program: source, prefix_lines: 0)
    syntax = Ripper.sexp(program)
    raise ArgumentError, "Cannot parse Ruby source for helper migration" unless syntax

    methods = method_locations(syntax)
    offsets = [ 0 ]
    source.each_line { |line| offsets << offsets.last + line.bytesize }
    contexts = []
    edits = Ripper.lex(program).filter_map do |position, type, value, _|
      replacement = case type
      when :on_ident then NAMES[value] if methods[position]
      when :on_tstring_content then contexts.last == :symbol ? NAMES[value] : PARTIALS[value]
      end
      case type
      when :on_symbeg then contexts << :symbol unless value == ":"
      when :on_qsymbols_beg, :on_symbols_beg then contexts << :symbol
      when :on_tstring_beg, :on_heredoc_beg, :on_qwords_beg, :on_words_beg, :on_regexp_beg then contexts << :string
      when :on_tstring_end, :on_heredoc_end, :on_regexp_end then contexts.pop
      end
      line = position[0] - prefix_lines
      [ offsets.fetch(line - 1) + position[1], value.bytesize, replacement ] if replacement && line.positive?
    end
    updated = source.b
    edits.reverse_each { |offset, length, value| updated[offset, length] = value.b }
    updated.force_encoding(source.encoding)
  end

  def self.ruby(source)
    rewrite(source)
  end

  def self.erb(source)
    program = source.b.gsub(/[^\r\n]/n, " ")
    source.to_enum(:scan, /(<%(?!%)(?:==?|-)?)(.*?)(-?%>)/m).each do
      match = Regexp.last_match
      opening, body, closing = match.captures
      next if body.start_with?("#")

      start = match.pre_match.bytesize + opening.bytesize
      program[start, body.bytesize] = body.b
      program[start + body.bytesize, closing.bytesize] = ";" + " " * (closing.bytesize - 1)
    end
    signature = source[/<%#\s*locals:\s*\((.*?)\)\s*%>/m, 1]
    prefix = "def __template(#{signature})\n"
    suffix = "\nend"
    rewrite(source, program: prefix + program.force_encoding(source.encoding) + suffix, prefix_lines: prefix.count("\n"))
  end

  def self.markdown(source)
    source = source.gsub(/(^```(ruby|rb|erb)[^\n]*\n)(.*?)(^```[ \t]*$)/m) do
      opening, language, body, closing = Regexp.last_match.captures
      "#{opening}#{language == 'erb' ? erb(body) : ruby(body)}#{closing}"
    end
    source.gsub(/`([^`\n]+)`/) { |match| NAMES.key?(Regexp.last_match[1]) ? "`#{NAMES.fetch(Regexp.last_match[1])}`" : match }
  end

  def self.changes(root)
    output, error, status = Open3.capture3("rg", "--files", "--hidden", "-0", "-g", "!.git", "-g", "!.jj", chdir: root)
    abort error unless status.success? || status.exitstatus == 1
    output.split("\0").sort.filter_map do |relative|
      path = File.join(root, relative)
      next if File.symlink?(path) || relative.start_with?("vendor/")
      next if root == LIBRARY && (relative == "README.md" || relative.start_with?("docs/", "plans/"))

      extension = File.extname(path)
      next unless %w[.rb .erb .md].include?(extension) || extension.empty?

      source = File.binread(path).force_encoding(Encoding::UTF_8)
      updated = case extension
      when ".rb" then ruby(source)
      when ".erb" then erb(source)
      when ".md" then markdown(source)
      else ruby(source) if source.lines.first&.match?(/\A#!.*ruby/)
      end
      next unless updated

      name = File.basename(path).sub(/\A_ui_(dialog|disclosure)\.html\.erb\z/, '_lc_\1.html.erb')
      destination = File.join(File.dirname(path), name)
      abort "Refusing to overwrite #{destination}" if destination != path && (File.exist?(destination) || File.symlink?(destination))
      [ path, destination, updated ] if updated != source || destination != path
    end
  end
end

if $PROGRAM_NAME == __FILE__
  write = false
  OptionParser.new do |options|
    options.banner = "Usage: ruby migrate_helpers.rb [checkout] [--write]"
    options.on("--write", "Apply the migration after checking every destination") { write = true }
  end.parse!
  abort "Expected one checkout path" if ARGV.size > 1
  root = File.realpath(ARGV.first || Dir.pwd)
  changes = HelperMigration.changes(root)
  changes.each do |path, destination, source|
    puts path.delete_prefix("#{root}/")
    next unless write

    File.binwrite(path, source)
    File.rename(path, destination) unless path == destination
  end
  puts "#{changes.size} files #{write ? 'updated' : 'would change'}"
  exit 1 if changes.any? && !write
end
