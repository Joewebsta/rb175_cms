# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'fileutils'
require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_document
    create_document 'about.txt', 'Ruby 0.95 released'

    get '/about.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'Ruby 0.95 released'
  end

  def test_document_not_found
    get '/joe.txt'
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'joe.txt does not exist.'
  end

  def test_markdown_document
    create_document 'about.md', '# Ruby is...'

    get '/about.md'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response.content_type
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_document_edit
    create_document 'about.txt'

    get '/about.txt/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_updating_document
    post '/about.txt', content: 'new content'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_includes last_response.body, 'about.txt has been updated'

    get '/about.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end

  def test_viewing_new_document
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Add a new document:'
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_creating_document
    post '/new', filename: 'joe.txt'
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, 'joe.txt was created.'

    get '/'
    assert_includes last_response.body, 'joe.txt'
  end

  def test_creating_document_without_filename
    post '/new', filename: ''
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required.'
  end
end
