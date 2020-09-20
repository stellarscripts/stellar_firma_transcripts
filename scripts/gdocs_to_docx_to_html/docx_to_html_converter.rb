require 'fileutils'
require 'docx'

class DocxToHtmlConverter
  attr_accessor :in_dir, :out_dir

  def initialize(in_dir ='data/docx_input', 
                 out_dir='data/raw_html_output')
    @in_dir,@out_dir=in_dir,out_dir
  end

  def convert_dir(in_dir=@in_dir, out_dir: @out_dir)
    FileUtils.mkdir_p(out_dir)
    fnames = gather_fnames(in_dir, '*.docx')
    fnames.each_with_index do |fname, i|
      print "\r#{i+1} of #{fnames.count} => #{File.basename(fname)}"
      out_fname = File.join(out_dir, File.basename(fname).sub('.docx','.html'))
      convert_file(fname, out_fname)
    end
  end

  def convert_file(fname, out_fname=nil)
    docx = load_docx(fname)
    html = docx.to_html

    # glitch in `docx` gem inserts linebreaks wrong when converting to HTML
    html = html.gsub!('\n', "\n").strip

    if out_fname
      FileUtils.mkdir_p(File.dirname(out_fname))
      File.write(out_fname, html)
    end
    return html
  end




  def docx_fnames
    gather_fnames(@in_dir, "*.docx")
  end
  def html_fnames
    gather_fnames(@out_dir, "*.html")
  end

  def gather_fnames(dir, glob="*")
    Dir.glob(File.join(dir, glob), File::FNM_CASEFOLD).sort
  end

  def load_docx(fname)
    doc = Docx::Document.open(fname)
  end

end