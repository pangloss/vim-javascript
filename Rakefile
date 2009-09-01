require 'rake'
require 'rake/clean'

files = ['syntax/javascript.vim', 'indent/javascript.vim']

CLEAN.include 'tmp/*_ctags'

desc "Make zip file"
file 'javascript.zip' => files do |t|
  File.unlink t.name if File.exists?(t.name)
  system('zip','-q',t.name,*t.prerequisites)
end

desc "Make vimball"
file 'javascript.vba' => files do |t|
  File.unlink t.name if File.exists?(t.name)
  File.open(t.name,"w") do |out|
    out.puts '" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.'
    out.puts 'UseVimball'
    out.puts 'finish'
    t.prerequisites.each do |name|
      File.open(name) do |file|
        file.each_line {}
        out.puts name
        out.puts file.lineno
        file.rewind
        file.each_line {|l|out.puts l}
      end
    end
  end
end

desc "Install"
task :install do
  vimfiles = if ENV['VIMFILES']
               ENV['VIMFILES']
             elsif RUBY_PLATFORM =~ /(win|w)32$/
               File.expand_path("~/vimfiles")
             else
               File.expand_path("~/.vim")
             end

  puts "Installing javascript.vim"
  files.each do |file|
    target_file = File.join(vimfiles, file)
    FileUtils.mkdir_p(File.dirname(target_file))
    FileUtils.rm(target_file) rescue nil
    FileUtils.cp(file, target_file)
    puts "  Copied #{file} to #{target_file}"
  end
end

desc "Copy ~/.ctags to tmp/original_ctags"
task :get_original_ctags do
  if File.exists?(File.expand_path("~/.ctags"))
    File.unlink('tmp/original_ctags') if File.exists?('tmp/original_ctags')
    FileUtils.cp(File.expand_path("~/.ctags"), 'tmp/original_ctags')
  elsif not File.exists?("tmp/original_ctags")
    File.open("tmp/original_ctags", "w") { }
  end
end

desc "Combine tmp/original_ctags and extras/ctags"
file 'tmp/combined_ctags' => ['tmp/original_ctags', 'extras/ctags'] do |t|
  begin_string = '# Begin vim-javascript generated section'
  end_string = '# End vim-javascript generated section'
  File.unlink t.name if File.exists?(t.name)
  File.open(t.name,"w") do |out|
    orig = File.read('tmp/original_ctags')
    orig.each_line.inject(true) do |can_print, line|
      can_print = false if line.chomp == begin_string
      out.puts line if can_print
      can_print or line.chomp == end_string
    end
    out.puts begin_string
    out.puts "# generated at #{ Time.now }"
    out.puts File.read('extras/ctags')
    out.puts end_string
  end
end

desc "Add better javascript support to ctags"
task :ctags => [:get_original_ctags, 'tmp/combined_ctags'] do
  FileUtils.cp('tmp/combined_ctags', File.expand_path('~/.ctags'))
end

task 'zip' => 'javascript.zip'
task 'vimball' => 'javascript.vba'
task :default => [:zip, :vimball]
