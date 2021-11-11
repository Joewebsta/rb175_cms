# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

get '/' do
  @docs = Dir.glob('*.txt', base: 'data').sort
  erb :index
end
