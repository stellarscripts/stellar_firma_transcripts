require 'oga'
require 'nokogiri'

class CssCleaner

  # ANALYZING

  def self.extract_css(doc)
    if doc.is_a?(String)
      doc = Oga.parse_html(doc.force_encoding('UTF-8'))
    end

    style_str = doc.at_css('style[type="text/css"]').inner_text

    import_rx = /(@import url\('[^']*'\);)/
    while m=import_rx.match(style_str)
      style_str.sub!(m[0],'')
    end

    style_str.split('}').map do |line|
      line.split('{').map { |v| v.strip }
    end.select { |arr| arr.count==2 }.to_h
  end

  def self.map_classes(doc, filter: '.c')
    doc = noko_parse(doc) if doc.is_a?(String)

    styles = extract_css(doc)

    if filter
      styles = styles.select {|k,v| k.start_with?(filter)}
    end

    stylemap = Hash.new
    styles.each do |name, rules|
      stylemap[name] = Array.new
      {
        'italic'           => :italic, 
        'underline'        => :underline, 
        'font-weight:700'  => :bold, 
        'font-weight:800'  => :bold, 
        'font-weight:900'  => :bold, 
        'font-weight:bold' => :bold, 
        'line-through'     => :del, 
        ';color:#fff'      => :whiteout, 
        '{color:#fff'      => :whiteout, 
      }.each{ |k,v| stylemap[name].push(v) if rules.include?(k) }
    end
    return stylemap.to_a.sort_by { |a| a[0] }.to_h
  end



  # SMART-EDITING

  def self.replace_classed_spans(doc, skip_empty: true)
    doc = noko_parse(doc) if doc.is_a?(String)
    class_tags = {
      'bold'      => 'b', 
      'italic'    => 'i', 
      'underline' => 'u', 
      'del'       => 'del', 
    }
    class_tags.each do |class_name, tag_name|
      doc.css("span[class~='#{class_name}']").each do |span|
        next if skip_empty && span.inner_html.strip==""

        classes = span['class'].strip.split(' ').sort.uniq

        span.delete('class')
        span.name=tag_name

        classes.delete(class_name)
        next unless classes.any?

        classes.each do |cname|
          next unless tag=class_tags[cname]
          span.wrap("<#{tag}/>")
        end
      end
    end
    return doc
  end

  def self.smart_clean_classes(doc)
    doc = noko_parse(doc) if doc.is_a?(String)
    stylemap = self.map_classes(doc)

    stylemap.each do |old_name, new_name_arr|
      _old_name = old_name.delete('.')
      if new_name_arr.empty?
        doc = replace_class(doc, _old_name, nil)
        next
      else
        new_name = new_name_arr.map { |k| k.to_s }.sort.join(" ")
        doc = replace_class(doc, _old_name, new_name)
      end
    end

    return doc
  end

  def self.rename_functional_classes(doc)
    doc = noko_parse(doc) if doc.is_a?(String)

    to_rename = self.map_classes(doc).select do |k,v|
      !v.empty?
    end.map {|k,v| [k.delete('.'), v]}.to_h

    puts "Renaming: #{to_rename}"

    to_rename.each do |old_name, new_name_arr|
      new_name = new_name_arr.map { |k| k.to_s }.sort.join(" ")
      doc = replace_class(doc, old_name, new_name)
    end

    return doc
  end

  def self.purge_unnecessary_classes(doc)
    doc = noko_parse(doc) if doc.is_a?(String)

    class_names = self.map_classes(doc).select do |k,v|
      v.empty?
    end.keys.map {|k| k.delete('.')}.sort

    puts "Purging: #{class_names}"

    return self.purge_classes(doc, *class_names)
  end




  # EDITING

  def self.purge_classes(doc, *class_names)
    doc = noko_parse(doc) if doc.is_a?(String)
    class_names.flatten.uniq.each do |class_name|
      doc = replace_class(doc, class_name, nil)
    end
    return doc.to_html
  end

  def self.purge_class(doc, class_name)
    doc = noko_parse(doc) if doc.is_a?(String)
    doc = replace_class(doc, class_name, nil)
    return doc.to_html
  end


  def self.de_class_empty_elements(doc, tag_names=['span','p','div'])
    doc = noko_parse(doc) if doc.is_a?(String)
    tag_names.each do |tag|
      doc.css('tag[class]').each do |node|
        next if node['class'].nil? || node['class'].strip==""
        if node.inner_text.strip==""
          node.delete('class')
        end
      end
    end
    return doc.to_html.gsub(/\s+class="\s*"/,"")
  end


  def self.replace_class(doc, old_class, new_class)
    doc = noko_parse(doc) if doc.is_a?(String)
    doc.css("[class='#{old_class}']").each do |node|
      if new_class
        node['class']=new_class
      else
        node.delete('class')
      end
    end
    doc.css("[class~='#{old_class}']").each do |node|
      arr = node['class'].split(" ")
      arr[arr.index(old_class)] = new_class
      node['class'] = arr.uniq.join(" ").strip
      node.delete('class') if node['class']==''
    end
    return doc
  end

  def self.noko_parse(html)
    { 
      "&zwnj;" => "",  "\u200C" => "", 
      "&nbsp;" => " ", "\u00A0" => " ", 
    }.each {|k,v| html.gsub!(k,v)}
    Nokogiri::HTML(html)
  end

end