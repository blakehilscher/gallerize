require 'mini_magick'
require 'exifr'

module GallerizeCli
  class Image
    class Version
      include FileUtils::Verbose

      attr_accessor :image, :name, :options

      def initialize(image, name, options)
        @image = image
        @name = name
        @options = OpenStruct.new(options)
        @valid = true
      end

      def process
        generate
      end

      def url
        file_path.to_s.gsub(image.directory.output_path, config.site_url)
      end

      def file_path
        @file_path ||= load_file_path
      end

      def width
        options.width.to_i
      end

      def height
        options.height.to_i
      end

      def valid?
        !!@valid
      end

      def config
        image.config
      end

      private

      def generate
        # do we have width and height?
        if width <= 0 || height <= 0
          GallerizeCli.logger.debug "version: #{name} is missing width: #{width} or height: #{height}"

        elsif !File.exists?(file_path)
          GallerizeCli.logger.debug "generating #{options.approach} #{file_path}"
          # open it up
          mini_image = MiniMagick::Image.open(image.file_path)
          mini_image.auto_orient
          if options.approach == 'crop'
            crop(mini_image, width, height)
          else
            resize(mini_image, width, height)
          end
          # landscape?
          mini_image.write file_path
        end
      rescue => err
        @valid = false
        GallerizeCli.logger.debug "#{err} image.file_name: #{image.file_name} name: #{name} options: #{options}"
      end

      def resize(mini_image, width, height)
        GallerizeCli.logger.debug "resize #{width}x#{height}"
        if mini_image[:width] > mini_image[:height]
          mini_image.resize "#{width}x#{height}>"
        else
          # portrait
          mini_image.resize "#{height}x#{width.to_i * 1.25}"
        end
      end

      def crop(mini_image, width, height)
        max = width > height ? width : height
        if mini_image[:width] > mini_image[:height]
          resize(mini_image, max * 2, height)
        else
          resize(mini_image, width, max * 2)
        end

        mini_image.crop "#{width}x#{height}+0+0"
      end

      def load_file_path
        path = File.join(image.directory.images_path, name)
        mkdir_p(path) unless Dir.exists?(path)
        File.join(path, image.file_name)
      end

    end
  end
end