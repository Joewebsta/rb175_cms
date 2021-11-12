# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

root = File.expand_path(__dir__)

configure do
  enable :sessions
  set :session_secret, 'super super secret'
end

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }.sort
  headers['Content-Type'] = 'text/html;charset=utf-8'
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.file?(file_path)
    format_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

def format_content(file_path)
  content = File.read(file_path)
  extension = file_path.split('.')[1]

  if extension == 'md'
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(content)
  else
    headers['Content-Type'] = 'text/plain'
    content
  end
end
