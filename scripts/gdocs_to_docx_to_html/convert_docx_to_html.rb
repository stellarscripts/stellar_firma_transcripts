require_relative 'docx_to_html_converter'

@input_dir  = 'data/docx_input'
@output_dir = 'data/raw_html_output'

def convert_all_to_html
  converter = DocxToHtmlConverter.new(@input_dir, @output_dir)
  converter.convert_dir
end

convert_all_to_html