require 'rubygems'
require 'sinatra'
require 'sinatra/config_file'
require 'FileUtils'
require 'URI'

config_file 'settings.yml'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == settings.username and password == settings.password
end

def tweak_content content
  if content.match(/^\S+:\/\//)
    return "<a href=\"#{content}\">#{content}</a>"
  else
    return content
  end

end

get "/" do
  erb :index, :locals => {:clipboard_string => tweak_content(get_clipboard), :refresh_rate => settings.refresh_rate_in_seconds.to_i * 1000}
end

post "/" do
  contents = params[:clipboard]
  decoded_contents = URI.unescape(contents)
  write_clipboard decoded_contents
  "OK"
end




def filename
  "/tmp/clipboard_cache.txt"
end

def get_clipboard
  if File.exist?(filename)
    file = File.open(filename, 'r')
    contents = file.read
    file.close
    return contents
  else
    return ""
  end
end

def write_clipboard contents
  File.open(filename,'w') do |file| file.write contents end
end
