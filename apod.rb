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
  response.headers['Cache-Control'] = 'public, max-age=604800'
  t = Time.parse(date) rescue false
  if t then
    @todays_image = get_days_image(date)
    erb :index
  else
    redirect "/"
  end
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <title>APOD - <%= @todays_image[:title_date] %></title>
  <meta name="description" content="" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
  <link href=' http://fonts.googleapis.com/css?family=Droid+Serif' rel='stylesheet' type='text/css'>
  <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
  <script src="./js/jquery.hotkeys.js" type="text/javascript"></script>
  <script src="./js/apod.js" type="text/javascript"></script>
  <style>
    html {
      background:url("http://people.ischool.berkeley.edu/~bcohen/sfemail/background.jpg")
    }
    body {
      padding:0;
      margin:0;
    }
    #content {
    }
    img {
      border: 1px black darkgrey;
      padding: 2px;
      -moz-box-shadow: 0px 0px 10px #666;
      -webkit-box-shadow: 0px 0px 10px #666;
      box-shadow: 0px 0px 10px #666;;
    }
    #apod_image h2{
      text-align:center;
      font-family: 'Droid Serif';
      overflow:auto;
    }
    a {
      text-decoration:none;
    }
    #apod_image {
    }
    .clear {
      clear:both;
    }
    #prev_nav, #next_nav {
      width:10%;
      display:inline-block;
      cursor: pointer;
      padding:0;
      margin-left:0;
      margin-right:0;
      position:fixed;
    }
    #prev_nav 
    {
      left:0;
    }
    #next_nav {
      right:0;
      text-align:right;
    }
    .left, .right {
      margin: 0 1em;
    }
    .right {
      right:0;
      text-align:right;
    }
    .arrow {
      position:fixed;
      font-size:2em;
    }
  </style>
</head>
<body>
  <section id="content">
  <%= yield %>
  </section>
</body>
</html>

@@ index
<a href="/<%= @todays_image[:yesterday]%>" id="prev_nav"><span class="arrow left">←</span></a>
<section id="apod_image">
  <h2>The Astronomy Picture of the Day for <%= @todays_image[:title_date] %></h2>
  <a href="http://apod.nasa.gov/apod/ap<%= @todays_image[:date] %>.html"><img id="apod" src="<%= @todays_image[:small_image_url] %>" /></a>
</section>
<% if @todays_image[:date] != @todays_image[:tomorrow] %>
<a href="/<%= @todays_image[:tomorrow]%>" id="next_nav"><span class="arrow right">→</span></a>
<% end %>
<!-- <a href="<%= @todays_image[:large_image_url]%>" style="text-align:center;">download full size</a> -->