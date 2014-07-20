require 'yaml'
require 'ostruct'
require 'active_support/all'
require 'parallel'
require 'mini_magick'
require 'pry'
require 'fileutils'
require 'exifr'

ROOT = File.expand_path( File.join(__FILE__, '../../') )

class Gallerize
  
  attr_accessor :image_paths
  
  VERSION='0.1.1'
  
  def self.generate
    new.perform
  end
  
  def perform
    if image_paths.blank?
      puts "no images found in #{source_dir.root} matching #{config.image_types}"
    else
      prepare_output_directory
      generate_images
      ticker = 0
      images_to_html(images.each_slice(config.per_page).to_a.first, 0, output_dir.html_file(:index) )
      images.each_slice(per_page) do |some_images|
        images_to_html(some_images, ticker)
        ticker = ticker + 1
      end
    end
  end 
  
  def prepare_output_directory
    # remove html files
    Dir.glob( output_dir.html_files ){|f| FileUtils.rm(f) }
    # ensure output directory
    FileUtils.mkdir( output_dir.root ) unless File.exists?( output_dir.root )
    # ensure output/images directory
    FileUtils.mkdir( output_dir.images ) unless File.exists?( output_dir.images )
    # copy css and js from gem to output
    output_dir.copy_from_gem_source( 'css', 'js' )
  end
  
  def generate_images
    generated = []
    # generate images and skip any that fail
    Parallel.map( image_paths, in_processes: config.workers.to_i ) do |f|
      begin
        generate_fullsize(f)
        generate_thumbnail(f)
        generated << f
      rescue => e
        # if any error occurs while processing the image, skip it
        puts "failed to process #{f}. error: #{e} #{e.backtrace.first}"
        nil
      end
    end
    generated
  end
  
  def images_to_html(some_images, ticker=0, name=nil)
    some_images ||= []
    navigation = (images.count / per_page.to_f).ceil.times.collect{|r| %Q{<a class="#{'active' if r == ticker}" href="images-#{r}.html">#{r}</a>} }.join("\n")
    navigation = (images.count > some_images.count) ? %Q{<div class="navigation">#{navigation}</div>} : ""
    html = %Q{
      #{body}
      #{navigation}
      <div id="images-container" class="images">
      #{some_images.join("\n")}
      </div>
      #{navigation}
      #{footer}
    }
    name ||= output_dir.html_file("images-#{ticker}")
    puts "generate #{name}"
    File.write(name, html)
  end
  
  def images
    ticker = 0
    image_paths.collect do |f| 
      image_fullsize = generate_fullsize(f)
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
  
  def image_paths
    @image_paths ||= Dir.glob("*.{#{config.image_types}}").reject{|f| 
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
    }
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
    config.per_page
  end
  
  def tracking_js
    return if config.tracking.blank?
    %Q{
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', '#{config.tracking}', 'auto');
        ga('send', 'pageview');

      </script>
    }
  end
  
  def generate_fullsize(source_path)
    image = extract_image_extension(source_path)
    output_path = File.join(output_dir.images, "#{image[:basename]}.#{image[:extension]}")
    # generate the thumbnail
    generate_image(source_path, output_path, config.image_width, config.image_height)
  end
  
  def generate_thumbnail(source_path)
    image = extract_image_extension(source_path)
    output_path = File.join(output_dir.images, "#{image[:basename]}-thumbnail.#{image[:extension]}")
    # generate the thumbnail
    generate_image(source_path, output_path, config.thumb_width, config.thumb_height)
  end
  
  def generate_image(source_path, output_path, width, height)
    # ensure correct types
    width, height = width.to_i, height.to_i
    # skip if image exists
    unless File.exists?(output_path)
      puts "generate_image #{File.basename(source_path)} #{File.basename(output_path)} #{width} #{height}"
      image = MiniMagick::Image.open(source_path)
      image.auto_orient
      # landscape?
      if image['width'] > image['height']
        image.resize "#{width}x#{height}"
      else
        image.resize "#{height}x#{width.to_i * 1.25}"
      end
      image.write output_path
    end
    # strip the output_dir.root from the path so that the returned path is relative
    output_path.gsub( output_dir.root, '' )
  end
  
  def extract_image_extension(image_path)
    basename = image_path.split(".")
    extension = basename.pop.downcase
    basename = basename.join('.')
    return { basename: basename, extension: extension }
  end
  
  def title
    File.basename(File.expand_path('.')).titleize
  end
  
  def output_dir
    @output_dir ||= OutputDir.new( config.output_name )
  end
  
  def config
    @config ||= load_config
  end
  
  def load_config
    config = {}
    # load config from output directory if present
    config = YAML.load( File.read( source_dir.config ) ) if source_dir.config?
    # generate global config from example if missing
    global_config = File.join(ROOT,'config/global.yml')
    FileUtils.cp( "#{global_config}.example", global_config ) unless File.exists?( global_config )
    # load global_config and merge with source config
    OpenStruct.new(YAML.load(File.read(global_config)).merge(config))
  end
  
  def source_dir
    @source_dir ||= SourceDir.new
  end
  
  class SourceDir
    
    def config?
      File.exists?(config)
    end
    
    def config
      File.join( root, '.gallerize')
    end
    
    def root
      @root ||= File.expand_path('.')
    end
    
  end
  
  class OutputDir
    
    attr_accessor :root
    
    def initialize(path)
      self.root = path
    end
    
    def root=(value)
      @root = File.join( File.expand_path('.'), (value || 'gallerize') )
    end
    
    def html_file(name)
      name = name.to_s
      name = "#{name}.html" unless name =~ /\.html/
      File.join(root, name)
    end
    
    def images
      File.join( root, 'images' )
    end
    
    def html_files
      File.join( root, '*.html')
    end
    
    def copy_from_gem_source(*folders)
      folders.each do |folder|
        outdir = File.join( root, folder )
        puts "copy ./#{folder} #{outdir}"
        FileUtils.rm_rf( outdir )
        FileUtils.cp_r( File.join( ROOT, folder ), outdir )
      end
    end
  
    
  end
  
end

Gallerize.generate