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
    @todays_image[:tomorrow] = Time.parse((Time.parse(date) + ONE_DAY).to_s).strftime('%y%m%d') unless Time.parse(date) == Time.now
    @todays_image[:title_date] = Time.parse(date).strftime('%A, %B %e, %Y')
    @todays_image
  end
end

configure do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')
end

get '/' do
  response.headers['Cache-Control'] = 'public, max-age=3600'
  @todays_image = get_days_image
  erb :index
end

get "/:date" do
  if params[:date] =~ /\d{6}/ then
    @todays_image = get_days_image(params[:date])
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
  <link rel="stylesheet" href="style.css" />
  <link href=' http://fonts.googleapis.com/css?family=Droid+Serif' rel='stylesheet' type='text/css'>
  <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
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
<script type="text/javascript">
$(window).resize(function(){

  $('#apod_image #apod').css({
    width: $(this).width() > 0.8 * $(window).width() ? 0.8 * $(window).width() : $(this).width()
  });
  
  $('#apod_image').css({
	  position:'absolute',
	  left: ($(window).width() - $('#apod').outerWidth())/2 > 0 ? ($(window).width() - $('#apod').outerWidth())/2 : 0,
	  top: ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) > 0 ? ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) : 0
  });
  
  $('#prev_nav').css({
    height: $(window).height(),
    'line-height': $(window).height() * 0.96 + 'px'
  });
  $('#next_nav').css({
    height:$('#prev_nav').height(),
    'line-height': $('#prev_nav').css('line-height')
  })

});

// To initially run the function. We could use trigger("resize"); on the previous method, but the image is slow to load.
$(window).load(function (){
  $(this).resize();
});
</script>
</html>

@@ index
<a href="/<%= @todays_image[:yesterday]%>" id="prev_nav"><span class="arrow left">←</span></a>
<section id="apod_image">
  <h2>The Astronomy Picture of the Day for <%= @todays_image[:title_date] %></h2>
  <a href="http://apod.nasa.gov/apod/ap<%= @todays_image[:date] %>.html"><img id="apod" src="<%= @todays_image[:small_image_url] %>" /></a>
</section>
<a href="/<%= @todays_image[:tomorrow]%>" id="next_nav"><span class="arrow right">→</span></a>
<!-- <a href="<%= @todays_image[:large_image_url]%>" style="text-align:center;">download full size</a> -->