require_relative 'episode'

@out_dir = "_posts"
@in_dir  = "_recleaned_episodes"



def replace_all
  @recleaned = recleaned_eps()

  @updated = Hash.new
  ep_fnames.each do |post_fname|
    puts "Checking for update to: #{post_fname}"
    ep     = Episode.from_file(post_fname)
    ep_num = ep.number.to_i
    content_fname = @recleaned[ep_num]
    next unless content_fname
    puts "Updating with content from: #{content_fname}"
    ep.md = File.read(content_fname)
    ep.save
    @updated[post_fname] = content_fname

    # break
  end
  puts "Updated #{@updated.count} posts."
  @updated
end

# def replace_one(new_content_fname, old_post_fname)
#   content = File.read(new_content_fname)
#   ep = Episode.from_file(old_post_fname)
#   ep.md = content
#   ep.save
# end

# Contents of folder should be named like "001.md", where the number is the 
# ep number.
# Files should NOT contain frontmatter.
def recleaned_eps
  @recleaned = gather_fnames(@in_dir, "*.md").map do |fname|
    ep_num = File.basename(fname).sub('.md','').to_i
    [ep_num, fname]
  end.to_h
end

def ep_fnames
  gather_fnames(@out_dir)
end

def gather_fnames(dir, glob="*.md")
  Dir.glob(File.join(dir, glob), File::FNM_CASEFOLD).sort
end