require "rubygems"
require "mechanize"
require "sinatra"
require "nokogiri"
require 'open-uri'
require 'net/http'

class JpegDimensions
  attr_reader :width, :height

  def initialize(image_path)
    @uri_split = URI.split(image_path)
    find_jpeg_size
  end

  def find_jpeg_size
    begin
      http = Net::HTTP.new(@uri_split[2], @uri_split[3])
      state = 0
      http.get(@uri_split[5]) do |str|  # this yields strings as each packet arrives
        str.each_byte do |b|
          state = case state
          when 0
            b == 0xFF ? 1 : 0
          when 1
            b >= 0xC0 && b <= 0xC3 ? 2 : 0
          when 2
            3
          when 3
            4
          when 4
            5
          when 5
            @height = b * 256
            6
          when 6
            @height += b
            7
          when 7
            @width = b * 256
            8
          when 8
            @width += b
            break
          end
        end
        break if state == 8  # don't need to fetch any more of the image
      end
    rescue Exception=>e
      # I do nothing here, but you can do something more useful with the exception if required
    end
  end
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
        jpg_info = JpegDimensions.new(@todays_image["url"])
        @todays_image["width"] = jpg_info.width
      end
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
      margin-top: 2em;
    }
    img {
      border: 1px black darkgrey;
      padding: 2px;
      -moz-box-shadow: 0px 0px 10px #666;
      -webkit-box-shadow: 0px 0px 10px #666;
      box-shadow: 0px 0px 10px #666;;
    }
    #apod_image {
      margin-left:auto;
      margin-right:auto;
      display:block;
      width: <%= @todays_image["width"] %>;
      text-align:center;
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
<section id="apod_image">
  <img src="<%= @todays_image["url"] %>" />
</section>