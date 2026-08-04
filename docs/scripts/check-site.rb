# frozen_string_literal: true

require "pathname"
require "uri"

site_root = Pathname(ARGV.fetch(0, "_site")).expand_path
base_url = ARGV.fetch(1, "/glvigor").sub(%r{/$}, "")
errors = []

unless site_root.directory?
  warn "Site output does not exist: #{site_root}"
  exit 1
end

html_files = site_root.glob("**/*.html")
html_by_path = html_files.to_h { |file| [file.expand_path.to_s, file.read] }

resolve_target = lambda do |source, href|
  uri = URI.parse(href)
  return nil if uri.scheme || href.start_with?("//", "mailto:", "tel:")

  raw_path = uri.path.to_s
  path = if raw_path.empty?
           source
         elsif raw_path.start_with?("/")
           relative = raw_path.delete_prefix(base_url).delete_prefix("/")
           site_root.join(relative)
         else
           source.dirname.join(raw_path)
         end

  path = path.join("index.html") if raw_path.empty? || raw_path.end_with?("/")
  path = Pathname("#{path}.html") if path.extname.empty? && !path.directory?
  [path.cleanpath, uri.fragment]
rescue URI::InvalidURIError
  errors << "#{source.relative_path_from(site_root)}: invalid URL #{href.inspect}"
  nil
end

html_by_path.each do |file_name, html|
  file = Pathname(file_name)
  relative = file.relative_path_from(site_root)
  ids = html.scan(/\bid=["']([^"']+)["']/i).flatten
  duplicate_ids = ids.tally.select { |_id, count| count > 1 }.keys
  errors << "#{relative}: duplicate IDs: #{duplicate_ids.join(', ')}" unless duplicate_ids.empty?

  h1_count = html.scan(/<h1\b/i).count
  errors << "#{relative}: expected one h1, found #{h1_count}" unless h1_count == 1

  html.scan(/<a\b[^>]*target=["']_blank["'][^>]*>/i).each do |anchor|
    errors << "#{relative}: target=_blank link missing rel=noopener" unless anchor.match?(/\brel=["'][^"']*noopener/i)
  end

  html.scan(/\b(?:href|src)=["']([^"']+)["']/i).flatten.each do |href|
    next if href.empty? || href.start_with?("#")

    resolved = resolve_target.call(file, href)
    next unless resolved

    target, fragment = resolved
    unless target.file?
      errors << "#{relative}: missing target #{href}"
      next
    end

    next if fragment.nil? || fragment.empty? || target.extname != ".html"

    target_html = html_by_path[target.expand_path.to_s] || target.read
    escaped_fragment = Regexp.escape(URI.decode_www_form_component(fragment))
    errors << "#{relative}: missing fragment #{href}" unless target_html.match?(/\bid=["']#{escaped_fragment}["']/i)
  end
end

if errors.empty?
  puts "Site validation: PASS (#{html_files.count} HTML files)"
  exit 0
end

warn errors.join("\n")
exit 1
