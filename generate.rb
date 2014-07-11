require 'mini_magick'

class Gallery
  
  TITLE = 'Photo Gallery'
  PER_PAGE = 40
  TRACKING=''
  
  def self.generate
    new.perform
  end
  
  def perform
    ticker = 0
    images_to_html(images.each_slice(per_page).to_a.first, 1, 'index.html')
    images.each_slice(per_page) do |some_images|
      images_to_html(some_images, ticker)
      ticker = ticker + 1
    end
    all_to_html
  end 
  
  def all_to_html
    images_to_html(images, ticker=-1, 'all.html')
  end
  
  def images_to_html(some_images, ticker=0, name=nil)
    some_images ||= []
    navigation = (images.count / per_page.to_f).ceil.times.collect{|r| %Q{<a class="#{'active' if r == ticker}" href="images-#{r}.html">Page #{r}</a>} }.join("\n")
    html = %Q{
      #{body}
      <div class="navigation">
        #{navigation}
        <a href="all.html">View All</a>
      </div>
      <div class="images">
      #{some_images.join("\n")}
      </div>
      <div class="navigation">
        #{navigation}
        <a href="all.html">View All</a>
      </div>
      #{footer}
    }
    name ||= "images-#{ticker}.html"
    puts "generated #{name}"
    File.write(name, html)
  end
  
  def images
    ticker = 0
    @images ||= Dir.glob('images/*.{jpg,JPG,png,PNG}').reject{|f| f =~ /thumbnail/ }.collect do |f| 
      image_thumbnail = generate_thumbnail(f)
      
      even = (ticker % 2 == 0) ? 'image-even' : 'image-odd'
      fourth = (ticker % 4 == 0) ? 'image-fourth' : ''
      src = %Q{
        <div class="image #{even} #{fourth} image-#{ticker}">
          <div class="inner-image">
            <a href="#{f}" class="fancybox" rel="group" target="_blank"><img src="#{image_thumbnail}" alt="" /></a>
          </div>
        </div>
      }
      ticker = ticker + 1
      src
    end
  end
  
  def body
    %Q{
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
        <head>
        <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
        <meta name="robots" content="noindex">
        <meta name="googlebot" content="noindex">
        
        <script type="text/javascript" src="js/jquery-1.10.1.min.js"></script>
        <script type="text/javascript" src="js/jquery.fancybox.js?v=2.1.5"></script>
        <link rel="stylesheet" type="text/css" href="css/jquery.fancybox.css?v=2.1.5" media="screen" />

        <script type="text/javascript">
          $(document).ready(function() {
             $('.fancybox').fancybox();
          });
        </script>
        
        #{tracking_js}
        
        <title>#{TITLE}</title>
        <link rel="stylesheet" href="css/styles.css" />
        </head>
        <body>
        <h1>#{TITLE}</h1>
      }
  end
  
  def footer
    %Q{
      </body>
      </html>
    }
  end
  
  def per_page
    PER_PAGE
  end
  
  def tracking_js
    return unless TRACKING.present?
    %Q{
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', '#{TRACKING}', 'auto');
        ga('send', 'pageview');

      </script>
    }
  end
  
  def generate_thumbnail(f)
    
    image_basename = f.split(".")
    image_ext = image_basename.pop
    image_basename = image_basename.join('.')
    image_thumbnail = "#{image_basename}-thumbnail.#{image_ext}"
    
    unless File.exists?(image_thumbnail)
      image = MiniMagick::Image.open(f)
      puts "generating #{image_thumbnail} from #{f}"
      image.resize "400x260"
      image.write image_thumbnail
    end
    image_thumbnail
  end
  
end

Gallery.generate