# frozen_string_literal: true

require 'bcrypt'
require 'redcarpet'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, 'super super secret'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('test/data', __dir__)
  else
    File.expand_path('data', __dir__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)

  case File.extname(file_path)
  when '.md'
    erb render_markdown(content)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  end
end

def load_user_credentials
  credentials_path = if ENV['RACK_ENV'] == 'test'
                       File.expand_path('test/users.yml', __dir__)
                     else
                       File.expand_path('users.yml', __dir__)
                     end
  YAML.load_file(credentials_path)
end

def user_signed_in?
  session.key?(:username)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end.sort

  headers['Content-Type'] = 'text/html;charset=utf-8'
  erb :index
end

get '/new' do
  require_signed_in_user
  erb :new
end

post '/new' do
  require_signed_in_user

  filename = params[:filename]

  if filename.empty?
    session[:message] = 'A name is required.'
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)
    File.write(file_path, '')

    session[:message] = "#{filename} was created."
    redirect '/'
  end
end

get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/:filename' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

post '/:filename/destroy' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  File.delete(file_path)

  session[:message] = "#{params[:filename]} was deleted."
  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  @username = params[:username]

  # if credentials.key?(@username) && credentials[@username] == params[:password]
  if valid_credentials?(@username, params[:password])
    session[:username] = @username
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:message] = 'Invalid Credentials'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out.'
  redirect '/'
end
