require 'nokogiri'
require_relative 'css_cleaner'

class HtmlCleaner
  attr_accessor :default_css, :expect_gdocs_output

  def initialize(expect_gdocs_output: false)
    @expect_gdocs_output = expect_gdocs_output
    @default_css = "\n  .italic { font-style: italic; }\n  .bold   { font-weight: bold; }\n  .underline { text-decoration: underline; }\n  .whiteout { color: #ffffff; }\n"
  end


  # FILE

  def clean_dir(in_dir, out_dir:, full: true)
    fnames = gather_fnames(in_dir)

    count = fnames.count.to_f
    i=0
    gather_fnames(in_dir).map do |in_fname|
      i+=1
      puts "#{(100.0*(i)/count).round(2)}% (#{i}/#{count}) - #{File.basename(in_fname)}"
      out_fname = File.join(out_dir, File.basename(in_fname))
      clean_file(in_fname, out_fname, full: full)
      out_fname
    end
  end

  def clean_file(in_fname, 
                 out_fname=           nil, 
                 full:                true, 
                 expect_gdocs_output: @expect_gdocs_output)
    out_fname ||= in_fname.sub('.html', ' - EDIT.html')
    html = File.read(in_fname)

    if full
      html = full_cleanup(html, expect_gdocs_output: expect_gdocs_output)
    else
      html = simple_str_cleanup(html)
    end
    
    File.write(out_fname, html)
    return html
  end



  # CLEANING

  def full_cleanup(html, expect_gdocs_output: @expect_gdocs_output)
    html = simple_str_cleanup(html)
    doc  = Nokogiri::HTML(html)
    doc  = purge_empty_elements('span','p','div','em','i','strong',doc: doc)
    doc  = CssCleaner::smart_clean_classes(doc)    if expect_gdocs_output
    doc  = excise_unclassed_spans(doc)
    doc  = CssCleaner::replace_classed_spans(doc)   if expect_gdocs_output

    if @default_css && doc.css('style[type="text/css"]').any?
      doc.css('style[type="text/css"]').first.content = @default_css
    end

    html = doc.to_html
    html = separate_paragraphs(html).strip         if expect_gdocs_output

    return html
  end

  def simple_str_cleanup(txt)
    _txt = "#{txt}"
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

      "\t"        => '  ', 
      /\n +/      => "\n", 
      /\n\s+\n/   => "\n\n", 
      /\n{3,}/    => "\n\n", 
    }.each {|k,v| _txt.gsub!(k,v)}

    return _txt.strip
  end

  def separate_paragraphs(txt)
    _txt = "#{txt}"
    {
      /<\/p>\s*<p>\s*<\/p>\s*<p>/ => "{{BREAK}}", 
      /<\/p>\s*<p>/               => "",
      "{{BREAK}}"                 => "</p>\n\n<p>", 
      /\s+<\/p>/                  => "</p>", 
    }.each {|k,v| _txt.gsub!(k,v)}
    return _txt.strip
  end



  # HELPERS - NOKOGIRI EDITING

  def excise_element(tagname, doc)
    doc.css(tagname).each do |span|
      span.add_previous_sibling(span.inner_html)
      span.remove
    end
    return doc
  end
  def excise_elements(*tagnames, doc)
    doc.css(*tagnames.flatten.uniq).each do |node|
      node.add_previous_sibling(node.inner_html)
      node.remove
    end
    return doc
  end

  def excise_unclassed_spans(doc)
    doc.css('span:not([class])', 'span[class=""]').each do |span|
      span.add_previous_sibling(span.inner_html)
      span.remove
    end
    return doc
  end
  def excise_unclassed_elements(*tagnames, doc)
    selectors=tagnames.flatten.uniq.map do |t|
      ["#{t}:not([class])", "#{t}[class='']"]
    end.flatten
    doc.css(*selectors).each do |node|
      node.add_previous_sibling(node.inner_html)
      node.remove
    end
    return doc
  end

  def replace_styled_spans(doc)
    rx = /(font-style:\s*italic|text-decoration:\s*(underline|line-through)|font-weight:\s*(bold|bolder))/

    5.times do |i|
      puts "replace_styled_spans() round #{i+1}"
      doc.css("span[style]").each do |node|
        replace_one_styled_node(node)
      end
      break if (leftovers=doc.to_html.scan(rx)).empty?
      puts "#{leftovers.count} styled spans remaining; running replace_styled_spans again."
    end

    return doc
  end
  def replace_one_styled_node(node)
    new_node = node.inner_html.strip

    styles=node['style'].downcase.split(';').map{|s| s.strip}.select{|s| s!=''}
    styles.uniq.reverse.each do |style|
      case style
      when "font-style: italic"
        new_node = "<i>#{new_node}</i>"
      when "text-decoration: underline"
        new_node = "<u>#{new_node}</u>"
      when "font-weight: bold", "font-weight: bolder"
        new_node = "<b>#{new_node}</b>"
      when "text-decoration: line-through"
        new_node = "<del>#{new_node}</del>"
      end
    end

    node.add_previous_sibling(new_node)
    node.remove
    return new_node
  end

  def purge_empty_elements(doc, tagnames=['span','p','strong','b','i','em'])
    while true
      blanks = doc.css(*tagnames).select { |node| node.inner_html.strip=="" }
      break if blanks.empty?
      blanks.each { |node| node.remove }
    end
    return doc
  end

  def purge_empty_spans(doc)
    return purge_empty_elements(doc, ['span'])
  end


  # HELPERS

  def noko_parse(html)
    { 
      "&zwnj;"    => "",   "\u200C" => "", 
      "&nbsp;"    => " ",  "\u00A0" => " ", 
    }.each {|k,v| html.gsub!(k,v)}
    Nokogiri::HTML(html)
  end

  def gather_fnames(dir=@in_dir)
    Dir.glob(File.join(dir, '*.html')).sort
  end

end