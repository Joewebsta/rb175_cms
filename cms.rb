# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

root = File.expand_path(__dir__)

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }
  erb :index
end
