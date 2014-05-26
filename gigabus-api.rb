#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'json'

require 'faraday'

DEPARTURE_JS_START = "    var departureCities = new Array(); \n"
DEPARTURE_JS_END = "      \n"

js = Faraday.get('http://m.saucontds.com/fc/megabususa.htm').body.lines.drop_while do |line|
  line != DEPARTURE_JS_START
end.take_while do |line|
  line != DEPARTURE_JS_END
end.join

departure_cities = js.scan(/departureCities\['.*'\] = {"name": "(.+)"};/)[1..-1].map(&:first).sort!
departure_routes = Hash[departure_cities.map { |name| [name, js.scan(/departureCities\['#{name}'\].destination\[\d+\] = {"companyId": \d+, "name": "(.+)"};/).map(&:first)] }]

arrival_cities = departure_routes.values.flatten!(1).uniq!.sort!
arrival_routes = Hash[arrival_cities.map { |name| [name, departure_routes.select{|_,v|v.include?(name)}.keys] }]

File.open('departure_routes.json', 'w') do |file|
  file.write JSON.pretty_generate(departure_routes)
end

File.open('arrival_routes.json', 'w') do |file|
  file.write JSON.pretty_generate(arrival_routes)
end
