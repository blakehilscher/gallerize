require 'yaml'
require 'ostruct'
require 'active_support/all'
require 'parallel'
require 'mini_magick'
require 'pry'
require 'fileutils'
require 'exifr'
require 'erb'

require 'gallerize/output_dir'
require 'gallerize/source_dir'

ROOT = File.expand_path( File.join(__FILE__, '../../') )

class Gallerize
  
  attr_accessor :image_paths
  
  VERSION='0.2.0'
  
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
    output_dir.copy_from_gem_source( 'assets/css', 'assets/js' )
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
    
    template = ERB.new(File.read(File.join(ROOT, 'templates/layout.html.erb')))
    html = template.result(binding)
    
    name ||= output_dir.html_file("images-#{ticker}")
    puts "generate #{name.gsub(output_dir.root, output_dir.relative_root)}"
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
  
  def per_page
    config.per_page
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
  
end

Gallerize.generate