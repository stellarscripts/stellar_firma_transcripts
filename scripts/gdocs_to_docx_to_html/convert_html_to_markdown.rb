require 'nokogiri'
require_relative 'lib/html_cleaner'
require_relative 'docx_to_html_converter'

@in_dir   = 'data/raw_html_output'
@html_dir = 'data/cleaned_html_output'
@md_dir   = 'data/markdown_output'


def cleanup
  clean_all_html
  convert_all_to_md
end

cleanup

def cleanup_one(in_fname=raw_html_fnames().first, out_fname=nil)
  out_fname ||= File.join(@md_dir, File.basename(in_fname).sub('.html','.md'))

  html = clean_html_file(in_fname)
  md   = html_str_to_markdown(html)

  if out_fname
    FileUtils.mkdir_p(File.dirname(out_fname))
    File.write(out_fname, md)
  end
  return md
end


def clean_all_html(fnames=raw_html_fnames(), out_dir: @html_dir)
  fnames.each_with_index do |in_fname, i|
    print "\r#{i+1} of #{fnames.count} => #{File.basename(in_fname)}"
    if out_dir
      out_fname = File.join(out_dir, File.basename(in_fname))
      out_fname.sub!('.docx.html', '.html')
    end
    clean_html_file(in_fname, out_fname)
  end
end
def convert_all_to_md(fnames=gather_fnames(@html_dir), out_dir: @md_dir)
  fnames.each_with_index do |in_fname, i|
    print "\r#{i+1} of #{fnames.count} => #{File.basename(in_fname)}"
    md = html_file_to_markdown(in_fname)
    out_fname = File.join(@md_dir, File.basename(in_fname).sub('.docx.html','.md').sub('.html','.md'))
    FileUtils.mkdir_p(File.dirname(out_fname))
    File.write(out_fname, md)
  end
end


# HTML CLEANUP / STYLE CONVERSION

def clean_html_file(in_fname=raw_html_fnames().first, out_fname=nil)
  out_fname ||= File.join(@html_dir, File.basename(in_fname))

  html = File.read(in_fname)
  html = clean_html_str(html)
  
  if out_fname
    FileUtils.mkdir_p(File.dirname(out_fname))
    File.write(out_fname, html)
  end
  return html
end
def clean_html_str(html)
  doc  = Nokogiri::HTML(html)
  doc  = edit_styling(doc)
  html = doc.at_css('body').inner_html.strip

  html = html.split("\n").select do |line|
    !line.include?('Master Episode List') && !line.include?('STELLAR FIRMA')
  end.join("\n")

  html = basic_text_cleanup(html)
  {
    "font-size:14pt;"    => "", 
    /\s+style="\s*"/     => "", 
    "<p"                 => "\n\n<p", 
    "<h"                 => "\n\n<h", 
    " </strong>"         => "</strong> ", 
    " </em>"             => "</em> ", 

    /<p>\s+/             => "<p>", 
    /\s+<\/p>/           => "</p>", 
    /<h4>\s+/             => "<h4>", 
    /\s+<\/h4>/           => "</h4>", 
    /<h5>\s+/             => "<h5>", 
    /\s+<\/h5>/           => "</h5>", 

    /<p>\s*<\/p>/        => "", 
    /\n{3,}/             => "\n\n", 
  }.each { |k,v| html.gsub!(k,v) }

  return html.strip
end

def edit_styling(doc)
  cleaner = HtmlCleaner.new

  doc = cleaner.excise_unclassed_spans(doc)
  doc = cleaner.purge_empty_elements(doc)
  doc = format_speakers(doc)
  doc = format_headings(doc)
  doc = format_captions(doc)

  return doc
end

def format_headings(doc)
  doc.css('p[style]').each do |node|
    if    node['style']=='font-size:24pt;text-align:center;'
      node.add_previous_sibling("<h1>#{node.inner_html.strip}</h1>")
      node.remove
    elsif node['style']=='font-size:18pt;text-align:center;'
      node.add_previous_sibling("<h2>#{node.inner_html.strip}</h2>")
      node.remove
    elsif node['style']=='text-align:center;'
      node.add_previous_sibling("<h3>#{node.inner_html.strip}</h3>")
      node.remove
    else # nuke anything else
      node.delete('style')
    end
  end
  return doc
end

def format_captions(doc)
  html = doc.to_html

  rx = /<p><strong>(\[[^\n]+\])<\/strong><\/p>/
  while m=rx.match(html)
    html.gsub!(m[0], "<h5>#{m[1]}</h5>")
  end

  return Nokogiri::HTML(html)
end

# NOTE: Sometimes speaker labels for interjections are stuck in the middle of other people's lines...
def format_speakers(doc)
  rx = /<strong>([A-Z0-9\s-]+):/
  doc.css('p').each do |node|
    inner_html = node.inner_html.strip
    next unless inner_html.start_with?(rx)
    if node.inner_html.start_with?(rx)
      speaker = node.at_css('strong')
      speaker_name = speaker.inner_html.sub(':','').strip
      node.add_previous_sibling("<h4>#{speaker_name}</h4>")
      speaker.remove
    end
  end
  return doc
end



# MARKDOWN CONVERSION

def html_file_to_markdown(in_fname, out_fname=nil)
  txt = File.read(in_fname)
  txt = html_str_to_markdown(txt)
  if out_fname
    FileUtils.mkdir_p(File.dirname(out_fname))
    File.write(out_fname, txt)
  end
  return txt
end

def html_str_to_markdown(txt)
  {
    /<\/?p(\s+style="[^"]*")?>/  => "", 
    /<\/?(strong|b)>/            => "__", 
    '____'                       => '', 
    '__ __'                      => ' ', 
    /<\/?(em|i)>/                => "*", 
    '<h5>'                       => '##### ', 
    '<h4>'                       => '#### ', 
    '<h3>'                       => '### ', 
    '<h2>'                       => '## ', 
    '<h1>'                       => '# ', 
    /<\/?h\d>/                   => "",

    '__[crosstalk]__'            => '_(crosstalk)_', 
    '__crosstalk]__'             => '_(crosstalk)_', 
    
    '&nbsp;'                     => ' ', 
    /[[:blank:]]+/               => ' ', 
  }.each { |k,v| txt.gsub!(k,v) }
  return txt
end

def basic_text_cleanup(txt)
  {
    # '　'        => ' ', 
    "\u3000"    => ' ',  # Ideographic space
    "&zwnj;"    => "",   "\u200C" => "", 
    "&nbsp;"    => " ",  "\u00A0" => " ", 
    "&lsquo;"   => "'",
    "&rsquo;"   => "'", 
    "&rsquor;"  => "'", 
    "&apos;"    => "'",  
    "&#39;"     => "'", 
    "‘"         => "'", 
    "’"         => "'", 
    '“'         => '"', 
    '”'         => '"', 
    "&ldquo;"   => '"', 
    "&rdquo;"   => '"', 
    "&rdquor;"  => '"', 
    "&quot;"    => '"', 
    "&hellip;"  => '...', 
    "&mldr;"    => '...', 
    '…'         => '...', 
    "&nldr;"    => '..', 
    '‥'        => '..', 
    "&amp;"     => "&", 
    "&hyphen;"  => '-', 
    "&dash;"    => '-', 
    "&ndash;"   => '-', 
    "&mdash;"   => '--', 
    '—'         => '--', 
    '–'         => '--', 
    '━'         => '--', 
    '－'        => '--', 

    "\t"              => '  ', 
    /\n[[:blank:]]+/  => "\n", 
    /\n\s+\n/         => "\n\n", 
    /\n{3,}/          => "\n\n", 

    /[[:blank:]]{2,}/ => " ", 
  }.each { |k,v| txt.gsub!(k,v) }
  return txt
end

def try_parse_episode_num(md)
  if m = /EPISODE\s+(\d+)/.match(md)
    return m[1].to_i
  else
    return nil
  end
end


def raw_html_fnames
  gather_fnames(@in_dir, '*.html')
end

def gather_fnames(dir=@in_dir, glob="*.html")
  Dir.glob(File.join(dir, glob)).sort
end

def append_frontmatter(md)
  yaml = {
    'episode_number' => try_parse_episode_num(md), 
  }.select { |k,v| v }

  return "#{yaml.to_yaml}\n---\n\n#{md}"
end


