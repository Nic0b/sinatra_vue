require 'rubygems'
require 'sinatra'
require 'json'
require 'sinatra/cross_origin'
require 'mongoid'

# DB Setup
Mongoid.load! "mongoid.config"

# Models
class Book
  include Mongoid::Document

  field :title, type: String
  field :author, type: String
  field :read, type: Boolean

  validates :title, presence: true
  validates :author, presence: true


  index({ title: 'text' })

end

class BookSerializer
  def initialize(book)
    @book = book
  end

  def as_json(*)
    data = {
      id:@book.id.to_s,
      title:@book.title,
      author:@book.author,
      read:@book.read
    }
    data[:errors] = @book.errors if@book.errors.any?
    data
  end
end


configure do
  enable :cross_origin
end


before do
 content_type 'application/json'
 response.headers['Access-Control-Allow-Origin'] = '*'
  end

  # routes...
options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

helpers do
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
  end

  def json_params
    begin
      JSON.parse(request.body.read)
    rescue
      halt 400, { message:'Invalid JSON' }.to_json
    end
  end

  # Using a method to access the book can save us
  # from a lot of repetitions and can be used
  # anywhere in the endpoints during the same
  # request
  def book
    @book ||= Book.where(id: params[:id]).first
  end

  # Since we used this code in both show and update
  # extracting it to a method make it easier and
  # less redundant
  def halt_if_not_found!
    halt(404, { message:'Book Not Found'}.to_json) unless book
  end

  def serialize(book)
    BookSerializer.new(book).to_json
  end
end

################################################

post '/books' do
  book = Book.new(json_params)
  p book
  halt 422, serialize(book) unless book.save

  response.headers['message'] = "Book added!"
  status 201
end
###########################################


delete '/books/:id' do |id|
  response['Access-Control-Allow-Origin'] = '*'
  p Book.where(id: params[:id]).first
  book.destroy if book
  response.headers['message'] = "Book removed!"  
  # status 200
  response.headers['status'] = 'success'
end


get '/ping' do
'pong'.to_json
end


get '/books' do

@a = []
Book.all.each do |b|
  
 @a << { 'id': b.id.to_s, 'title': b.title, 'author': b.author, 'read': b.read }
 end
 
books = [
    {
        'title': 'On the Road',
        'author': 'Jack Kerouac',
        'read': 'true'
    },
    {
        'title': 'Harry Potter and the Philosopher\'s Stone',
        'author': 'J. K. Rowling',
        'read': 'False'
    },
    {
        'title': 'Green Eggs and Ham',
        'author': 'Dr. Seuss',
        'read': 'false'
    }
]

h = {
     'status': 'success',
     'books': @a
 }.to_json
h
 end

 get '/books/:id' do |id|
  halt_if_not_found!
  serialize(book)
end
