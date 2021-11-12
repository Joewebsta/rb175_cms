# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

root = File.expand_path(__dir__)

configure do
  enable :sessions
  set :session_secret, 'super super secret'
end

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }
  headers['Content-Type'] = 'text/html;charset=utf-8'
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.file?(file_path)
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end
