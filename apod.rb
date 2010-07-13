require "rubygems"
require "mechanize"
require "sinatra"
require "nokogiri"
require 'open-uri'
require 'net/http'

class Apod_Image
  
end

BASE_URL = "http://antwrp.gsfc.nasa.gov/apod/"

helpers do
  def get_todays_image
    @todays_image = {}
    doc = Nokogiri::HTML(open(BASE_URL))
    doc.css('p > a').each do |link|
      link_url = link.attributes["href"]
      if /image.*\.jpg/ =~ link_url then 
        @todays_image["url"] = BASE_URL + link_url
      end
    end
    t = Time.now
    @todays_image["time"] = t
    @todays_image
  end
end

get '/' do
  response.headers['Cache-Control'] = 'public, max-age=3600'
  @todays_image = get_todays_image
  erb :index
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <title>APOD - <%= @todays_image["time"].strftime('%A, %B %e') %></title>
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

  $('#apod_image').css({
	  position:'absolute',
	  left: ($(window).width() - $('#apod').outerWidth())/2 > 0 ? ($(window).width() - $('#apod').outerWidth())/2 : 0,
	  top: ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) > 0 ? ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) : 0
  });

});

// To initially run the function:
$(window).load(function (){
  $(this).resize();
});
</script>
</html>

@@ index
<section id="apod_image">
  <h2>The Astronomy Picture of the Day for <%= @todays_image["time"].strftime('%A, %B %e, %Y') %></h2>
  <a href="http://apod.nasa.gov/apod/ap<%= @todays_image["time"].strftime('%y%m%d') %>.html"><img id="apod" src="<%= @todays_image["url"] %>" /></a>
</section>