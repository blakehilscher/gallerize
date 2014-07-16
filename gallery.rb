require 'yaml'
require 'active_support/all'
require 'parallel'
require 'mini_magick'
require 'pry'
require 'fileutils'
require 'exifr'

ROOT = File.expand_path( File.join(__FILE__, '..') )

class Gallery
  
  if File.exists?(File.join(File.expand_path('.'), '.gallerize.yml'))
    config = YAML.load(File.read(File.join(File.expand_path('.'), '.gallerize.yml')))
  else
    config = {}
  end
  
  CONFIG = YAML.load(File.read(File.join(ROOT,'config/global.yml'))).merge(config)
  
  PER_PAGE = CONFIG['per_page']
  TRACKING = CONFIG['tracking']
  IMAGE_TYPES = CONFIG['image_types']
  WORKERS = CONFIG['workers'].to_i
  
  def self.generate
    new.perform
  end
  
  def perform
    if Dir.glob("*.{#{IMAGE_TYPES}}").reject{|f| f =~ /thumbnail/ }.blank?
      puts "no images found in #{ROOT} matching #{IMAGE_TYPES}"
    else
      reset
      generate_images
      ticker = 0
      images_to_html(images.each_slice(per_page).to_a.first, 0, File.join(output_dir, 'index.html'))
      images.each_slice(per_page) do |some_images|
        images_to_html(some_images, ticker)
        ticker = ticker + 1
      end
      
    end
  end 
  
  def generate_images
    Parallel.map( Dir.glob("*.{#{IMAGE_TYPES}}").reject{|f| f =~ /thumbnail/ }, in_processes: WORKERS ) do |f| 
      generate_image(f)
      generate_thumbnail(f)
    end
  end
  
  def images_to_html(some_images, ticker=0, name=nil)
    some_images ||= []
    navigation = (images.count / per_page.to_f).ceil.times.collect{|r| %Q{<a class="#{'active' if r == ticker}" href="images-#{r}.html">#{r}</a>} }.join("\n")
    html = %Q{
      #{body}
      <div class="navigation">
        #{navigation}
      </div>
      <div id="images-container" class="images">
      #{some_images.join("\n")}
      </div>
      <div class="navigation">
        #{navigation}
      </div>
      #{footer}
    }
    name ||= File.join( output_dir, "images-#{ticker}.html" )
    puts "generate #{name}"
    File.write(name, html)
  end
  
  def images
    ticker = 0
    @images ||= Dir.glob("*.{#{IMAGE_TYPES}}").reject{|f| 
      # reject thumbnails
      f =~ /thumbnail/
    }.reject{|f| 
      begin
        EXIFR::JPEG.new(f).date_time
        false
      rescue
        true
      end
    }.sort_by{|f|
      # sort by exif date
      EXIFR::JPEG.new(f).date_time || Time.parse('3000-01-01')
    }.collect do |f| 
      image_fullsize = generate_image(f)
      image_thumbnail = generate_thumbnail(f)
      
      even = (ticker % 2 == 0) ? 'image-even' : 'image-odd'
      third = (ticker % 3 == 0) ? 'image-third' : ''
      fourth = (ticker % 4 == 0) ? 'image-fourth' : ''
      src = %Q{
        <div class="image #{even} #{fourth} #{third} image-#{ticker}">
          <div class="inner-image">
            <a href="./#{image_fullsize}" class="fancybox" rel="group" target="_blank"><img src="./#{image_thumbnail}" alt="" /></a>
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
        <script type="text/javascript" src="js/jquery.fancybox.js"></script>
        <script type="text/javascript" src="js/imagesloaded.js"></script>
        <script type="text/javascript" src="js/jquery.masonry.js"></script>
        
        <link rel="stylesheet" type="text/css" href="css/styles.css" media="screen" />
        <link rel="stylesheet" type="text/css" href="css/jquery.fancybox.css" media="screen" />
        <meta name="viewport" content="width=device-width, user-scalable=no">
        
        <script type="text/javascript">
          $(document).ready(function(){
            $('#images-container').imagesLoaded( function() {
              $('.images').show();
            
              var container = document.querySelector('#images-container');
              var msnry = new Masonry( container, {

                itemSelector: '.image'
              });

              $('.fancybox').fancybox();
            });
          });
        </script>
        
        #{tracking_js}
        
        <title>#{title}</title>
        <link rel="stylesheet" href="css/styles.css" />
        </head>
        <body>
        <h1 class="page-title">#{title}</h1>
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
    return if TRACKING == ''
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
  
  def generate_image(image_path)
    
    image_output = File.join(output_dir, 'images', image_path.downcase)
    
    unless File.exists?(image_output)
      puts "generate_image 1200x800 #{image_output}"
      image = MiniMagick::Image.open(image_path)
      image.auto_orient
      width,height = image['width'],image['height']
      if width > height
        image.resize "#{CONFIG['image_width']}x#{CONFIG['image_height']}"
      else
        image.resize "#{CONFIG['image_height']}x#{CONFIG['image_width']}"
      end
      image.write image_output
    end
    image_output.gsub(output_dir, '')
  end
  
  def generate_thumbnail(f)
    image_basename = f.downcase.split(".")
    image_ext = image_basename.pop
    image_basename = image_basename.join('.')
    image_thumbnail = File.join(output_dir, 'images', "#{image_basename}-thumbnail.#{image_ext}")
    
    unless File.exists?(image_thumbnail)
      puts "generate_thumbnail 400x260 #{image_thumbnail}"
      image = MiniMagick::Image.open(f)
      image.auto_orient
      width,height = image['width'],image['height']
      if width > height
        image.resize "#{CONFIG['thumb_width']}x#{CONFIG['thumb_height']}"
      else
        image.resize "#{CONFIG['thumb_height']}x#{CONFIG['thumb_width'].to_i * 1.25}"
      end
      image.write image_thumbnail
    end
    image_thumbnail.gsub(output_dir, '')
  end
  
  def title
    File.basename(File.expand_path('.')).titleize
  end
  
  def output_dir
    dir = File.basename(File.expand_path('.'))
    dir = "#{Date.today.strftime('%Y-%m')}-#{dir}" unless dir =~ /^[0-9]{4}/
    dir = dir.downcase.underscore.gsub('_','-')
    dir
  end
  
  def reset
    Dir.glob(File.join(output_dir, '*.html')){|f| FileUtils.rm(f) }
    FileUtils.mkdir(output_dir) unless File.exists?(output_dir)
    FileUtils.mkdir(File.join(output_dir,'images')) unless File.exists?(File.join(output_dir,'images'))
    copy('css', 'js')
  end
  
  def copy(*folders)
    folders.each do |folder|
      outdir = File.join( output_dir, folder )
      puts "copy #{File.join( ROOT, folder )} #{outdir}"
      FileUtils.rm_rf( outdir )
      FileUtils.cp_r( File.join( ROOT, folder ), outdir )
    end
  end
  
end

Gallery.generate