require "rubygems"
require "mechanize"
require "sinatra"
require "nokogiri"
require 'open-uri'

BASE_URL = "http://antwrp.gsfc.nasa.gov/apod/"

helpers do
  def get_todays_image
    doc = Nokogiri::HTML(open(BASE_URL))
    doc.css('p > a').each do |link|
      link_url = link.attributes["href"]
      if /image.*\.jpg/ =~ link_url then @todays_image = BASE_URL + link_url end
    end
    @todays_image
  end
end

get '/' do
  response.headers['Cache-Control'] = 'public, max-age=3600'
  t = Time.now
  @title = "APOD - #{t.strftime('%A, %B %e')}"
  @todays_image = get_todays_image
  @rendered_at = t.to_s
  erb :index
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <title><%= @title %></title>
  <meta name="description" content="" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
  <link rel="stylesheet" href="style.css" />
  <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
  <style>
    html {
      background:url("http://people.ischool.berkeley.edu/~bcohen/sfemail/background.jpg")
    }
    #content {
      max-width:90%;
      margin:auto;
      margin-top: 2em;
    }
    img {
      border: 1px black darkgrey;
      padding: 2px;
      max-height:600px;
      -moz-box-shadow: 3px 3px 3px #666;
      -webkit-box-shadow: 0px 0px 10px #666;
      box-shadow: 3px 3px 3px #666;
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
<img src="<%= @todays_image %>" />