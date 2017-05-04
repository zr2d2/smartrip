#!/usr/bin/ruby
require 'rubygems'
require 'mechanize'

url = 'https://en.wikipedia.org/wiki/Takoma_Langley_Crossroads_Transit_Center'

agent = Mechanize.new

page = agent.get url

page.links.each do |link|
  puts link.text
end
