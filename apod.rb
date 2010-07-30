require "rubygems"
require "mechanize"
require "sinatra"
require "nokogiri"
require 'open-uri'
require 'net/http'
require "dm-core"
require "dm-types"

class Apod_Image
  include DataMapper::Resource
  
  property :id,         Serial # primary serial key
  property :large_image_url,      String
  property :small_image_url,      String
  property :url,       String,   :required => true
  property :title,    String,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime
  
end

BASE_URL = "http://antwrp.gsfc.nasa.gov/apod/"
ONE_DAY = 60 * 60 * 24

helpers do
  def get_days_image(date = Time.now.strftime('%y%m%d'))
    @todays_image = {}
    @todays_image[:date] = date
    @todays_image[:tomorrow] = @todays_image[:date]
    @todays_image[:base_url] = (BASE_URL + "ap" + date + ".html")
    doc = Nokogiri::HTML(open(@todays_image[:base_url]))
    doc.css('p > a').each do |link|
      link_url = link.attributes["href"]
      if /image.*\.jpg/ =~ link_url then 
        @todays_image[:large_image_url] = BASE_URL + link_url
      end
    end
    doc.css('a > img').each do |link|
      link_url = link.attributes["src"]
      if /image.*\.jpg/ =~ link_url then 
        @todays_image[:small_image_url] = BASE_URL + link_url
      end
    end
    @todays_image[:yesterday] = Time.parse((Time.parse(date) - ONE_DAY).to_s).strftime('%y%m%d')
    @todays_image[:tomorrow] = Time.parse((Time.parse(date) + ONE_DAY).to_s).strftime('%y%m%d') unless Time.parse(date).strftime('%y%m%d') == Time.now.strftime('%y%m%d')
    @todays_image[:title_date] = Time.parse(date).strftime('%A, %B %e, %Y')
    @todays_image
  end
end

configure do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')
end

not_found do
  "Sorry, that page wasn't found"
end

error do
  "Oops! " + request.env["sinatra.error"].message
end 

get '/' do
  response.headers['Cache-Control'] = 'public, max-age=3600'
  @todays_image = get_days_image
  erb :index
end

get %r{/(\d{6})} do |date|
  response.headers['Cache-Control'] = 'public, max-age=3600'
  t = Time.parse(date) rescue false
  if t then
    @todays_image = get_days_image(date)
    erb :index
  else
    redirect "/"
  end
end