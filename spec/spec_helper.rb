require "vimrunner"
require "vimrunner/rspec"

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = :documentation
end

Vimrunner::RSpec.configure do |config|
  plugin_path = File.expand_path("..", File.dirname(__FILE__))

  config.reuse_server = false
  config.start_vim do
    vim = Vimrunner.start
    vim.prepend_runtimepath(plugin_path)
    vim.command "runtime ftdetect/javascript.vim"
    vim.command "set nospell"
    vim
  end
end
