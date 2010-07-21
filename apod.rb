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
  property :image_url,      String, :required => true
  property :url,       String,   :required => true
  property :title,    String,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime
  
end

BASE_URL = "http://antwrp.gsfc.nasa.gov/apod/"

helpers do
  def get_days_image(date = Time.now.strftime('%y%m%d'))
    @todays_image = {}
    @todays_image[:date] = date
    @todays_image[:base_url] = (BASE_URL + "ap" + date + ".html")
    doc = Nokogiri::HTML(open(@todays_image[:base_url]))
    doc.css('p > a').each do |link|
      link_url = link.attributes["href"]
      if /image.*\.jpg/ =~ link_url then 
        @todays_image["url"] = BASE_URL + link_url
      end
    end
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

});

// To initially run the function. We could use trigger("resize"); on the previous method, but the image is slow to load.
$(window).load(function (){
  $(this).resize();
});
</script>
</html>

@@ index
<section id="apod_image">
  <div id="back_nav" style=""><a href="">Go Back</a></div>
  <h2>The Astronomy Picture of the Day for <%= @todays_image[:title_date] %></h2>
  <a href="http://apod.nasa.gov/apod/ap<%= @todays_image[:date] %>.html"><img id="apod" src="<%= @todays_image["url"] %>" /></a>
</section>