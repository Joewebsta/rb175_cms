# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

root = File.expand_path(__dir__)

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]
  headers['Content-Type'] = 'text/plain'
  File.read(file_path)
end
