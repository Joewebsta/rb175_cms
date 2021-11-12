# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super super secret'
end

root = File.expand_path(__dir__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)

  case File.extname(file_path)
  when '.md'
    render_markdown(content)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  end
end

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }.sort
  headers['Content-Type'] = 'text/html;charset=utf-8'
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  # Add validation
  # Reduce duplication with /:filename

  file_path = root + '/data/' + params[:filename]
  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/:filename/edit' do
  session[:message] = "#{params[:filename]} has been updated."

  file_path = root + '/data/' + params[:filename]
  content = params[:content]
  File.write(file_path, content)

  redirect '/'
end
