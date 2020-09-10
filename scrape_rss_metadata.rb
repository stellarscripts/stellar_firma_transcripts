require 'rss'
require 'faraday'
require 'fileutils'
require 'yaml'

@url     = "https://rss.acast.com/stellarfirma"
@out_dir = "_frontmatter"

def get_feed_xml(url=@url)
  @xml = Faraday.get(url).body
end
def get_rss_feed(url=@url)
  @xml  ||= get_feed_xml(url)
  @feed   = RSS::Parser.parse(@xml)
  return @feed
end

def gen_all_jekyll_frontmatter(items=nil)
  unless items
    @feed ||= get_rss_feed('https://rss.acast.com/stellarfirma')
    items = @feed.items
  end
  items.map do |feed_item|
    gen_jekyll_frontmatter(feed_item)
  end
end

def gen_jekyll_frontmatter(item, out_dir: @out_dir, overwrite: true)
  title     = "#{item.title}".force_encoding('UTF-8').strip
  acast_url = "#{item.link}"
  slug      = File.basename(acast_url)
  date      = item.pubDate

  if item.itunes_subtitle
    summary = "#{item.itunes_subtitle}".force_encoding('UTF-8')
    {
      /[[:blank:]]/  => " ", 
      "\r"           => "\n", 
      /\n{3,}/       => "\n\n", 
      "\n\n"         => " <br/><br/>", 
      "\n"           => " <br/>", 
      /[[:blank:]]+/ => " ", 
    }.each {|k,v| summary.gsub!(k,v)}
    summary = summary.strip
  end

  if episode_number = /Episode (\d+)/.match(title)
    episode_number = episode_number[1].to_i
    episode_number = "%03d" % episode_number
  end


  if episode_number
    fname         = item.pubDate.strftime("%Y-%m-%d-#{episode_number}.md")
    categories    = 'episode'
    episode_title = title.sub("Episode #{episode_number.to_i} -","").strip
  else
    fname         = item.pubDate.strftime("%Y-%m-%d-#{slug}.md")
    categories    = nil
  end

  frontmatter_hash = {
    layout:           'post', 
    title:            title, 
    date:             date, 
    categories:       categories, 
    episode_number:   episode_number, 
    episode_title:    (episode_title || title), 
    tags:             [], 
    content_warnings: [], 
    voiced:           [], 
    acast_url:        acast_url, 
    summary:          summary, 
    formats:          { 'PDF'=>nil, 'Google Doc'=>nil }, 
    sources:          { 'transcriber 1 name'=>'homepage URL/email/whatever', 'transcriber 2 name'=>'homepage URL/email/whatever' }, 
    official:         false, 
  }.map { |k,v| [k.to_s, v] }.to_h

  frontmatter_yaml = frontmatter_hash.to_yaml(line_width: -1)
  frontmatter_yaml = "#{frontmatter_yaml.strip}\n---\n\n"

  # keys to comment out: 
  ["  PDF", "  Google Doc"].each do |line|
    frontmatter_yaml.gsub!("\n#{line}", "\n# #{line}")
  end

  fname = File.join(out_dir, fname)
  if overwrite || !File.exist?(fname)
    FileUtils.mkdir_p(out_dir)
    File.write(fname, frontmatter_yaml)
  else
    warn "ERROR: Could not overwrite #{fname}"
  end
  return frontmatter_hash
end

# def parse_stellar_firma_item(item)
#   if item.itunes_subtitle
#     summary = "#{item.itunes_subtitle}".force_encoding('UTF-8')
#     {
#       /[[:blank:]]/ => " ", 
#       "\r"          => "\n", 
#       /\n{3,}/      => "\n\n", 
#       "\n\n"        => " <br/><br/>", 
#       "\n"          => " <br/>", 
#       / {2,}/       => " ", 
#     }.each {|k,v| summary.gsub!(k,v)}

#     summary = summary.strip
#   end

#   if episode_number = /Episode (\d+)/.match("#{item.title}")
#     episode_number = episode_number[1].to_i
#     episode_number = "%03d" % episode_number
#   end

#   slug = File.basename("#{item.link}")

#   {
#     title:          "#{item.title}".strip, 
#     episode_number: episode_number, 
#     date:           item.pubDate, 
#     slug:           File.basename("#{item.link}"), 
#     acast_url:      "#{item.link}", 
#     summary:        summary, 
#   }.select { |k,v| v }
# end

# def gen_jekyll_frontmatter(feed_item, out_dir: @out_dir)
#   item = parse_stellar_firma_item(feed_item)

#   if item[:episode_number]
#     fname      = item[:date].strftime("%Y-%m-%d-#{item[:episode_number]}.md")
#     categories = 'episode'
#     episode_title = item[:title].sub("Episode #{item[:episode_number].to_i} -","").strip
#   else
#     fname      = item[:date].strftime("%Y-%m-%d-#{item[:slug]}.md")
#     categories = nil
#   end

#   frontmatter_hash = {
#     layout:           'post', 
#     title:            item[:title], 
#     date:             item[:date], 
#     categories:       categories, 
#     episode_number:   item[:episode_number], 
#     episode_title:    episode_title, 
#     tags:             [], 
#     content_warnings: [], 
#     voiced:           [], 
#     acast_url:        item[:acast_url], 
#     summary:          item[:summary], 
#     formats:          { 'PDF'=>nil, 'Google Doc'=>nil }, 
#     sources:          { 'transcriber 1 name'=>'homepage URL/email/whatever', 'transcriber 2 name'=>'homepage URL/email/whatever' }, 
#     official:         false, 
#   }.map { |k,v| [k.to_s, v] }.to_h

#   frontmatter_yaml = frontmatter_hash.to_yaml(line_width: -1)
#   frontmatter_yaml = "#{frontmatter_yaml}\n---\n\n"

#   # keys to comment out: 
#   ["formats", "  PDF", "  Google Doc"].each do |line|
#     frontmatter_yaml.gsub!("\n#{line}", "\n# #{line}")
#   end

#   FileUtils.mkdir_p(out_dir)
#   File.write(File.join(out_dir, fname), frontmatter_yaml)
#   return frontmatter_hash
# end