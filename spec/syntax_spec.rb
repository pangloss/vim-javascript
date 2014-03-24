require 'rspec'
require 'nokogiri'
require_relative 'spec_helper'

fixtures = [
  'jquery-2.1.0',
]

describe 'javascript syntax' do

  let(:filename) {'syntax.html'}

  fixtures.each do |fixture|
    source = File.expand_path("./fixtures/#{fixture}.js", File.dirname(__FILE__))
    master = source + '.html'
    it "should support syntax for #{fixture.gsub('_', ' ')}" do
      vim.edit source
      vim.command "TOhtml | w #{filename}"
      if not File.exists?(master) or ENV['GENERATE_GOLDEN_MASTER']
        vim.command "w #{master}"
      end
      master_syntax = Nokogiri::HTML(IO.read(master))
      source_syntax = Nokogiri::HTML(IO.read(filename))
      expect(master_syntax.css('#vimCodeElement').first.to_s).to eq(source_syntax.css('#vimCodeElement').first.to_s)
    end
  end
end
