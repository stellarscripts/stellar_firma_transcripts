How To Use
----------

1. Download Stellar Firma transcripts from Google Docs in DOCX format. Put them in a folder called `data/docx_input`.

2. Use `convert_docx_to_html.rb` to convert them to (ugly) HTML - the output will be saved to `data/raw_html_output`.

3. Use the `cleanup` function in `convert_html_to_markdown.rb` to convert that ugly HTML to Markdown format.

(I apologize for how messy this is, but I always end up basically writing a new document parsing script for every Google Docs-based transcription/translation project I work on, due to to the way the Google Docs API works + the fact that every collaborative project evolves its own style/formatting standards. I don't really write them with the expectation that anyone else will have to use them.)