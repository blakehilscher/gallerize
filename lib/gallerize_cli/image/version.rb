require 'mini_magick'
require 'exifr'

module GallerizeCli
  class Image
    class Version
      include FileUtils::Verbose

      attr_accessor :image, :name, :options

      GRAVITY_TYPES = [:north_west, :north, :north_east, :east, :south_east, :south, :south_west, :west, :center]

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

      def method
        options.method
      end

      def valid?
        !!@valid
      end

      def config
        image.config
      end

      private

      def generate


        if width <= 0 || height <= 0
          GallerizeCli.logger.debug "version: #{name} is missing width: #{width} or height: #{height}"

        elsif !File.exists?(file_path)
          GallerizeCli.logger.debug "generating #{options.approach} #{file_path}"
          # open it up
          # do we have width and height?
          new_image = resize_with_crop(MiniMagick::Image.open(image.file_path), width, height)
          # landscape?
          new_image.write file_path
        end
      rescue => err
        @valid = false
        GallerizeCli.logger.debug "#{err} image.file_name: #{image.file_name} name: #{name} options: #{options}"
      end

      def resize_with_crop(img, w, h, opts = {})
        gravity = opts[:gravity] || :center

        w_original, h_original = [img[:width].to_f, img[:height].to_f]

        op_resize = ''

        # check proportions
        if w_original * h < h_original * w
          op_resize = "#{w.to_i}x"
          w_result = w
          h_result = (h_original * w / w_original)
        else
          op_resize = "x#{h.to_i}"
          w_result = (w_original * h / h_original)
          h_result = h
        end

        w_offset, h_offset = crop_offsets_by_gravity(gravity, [w_result, h_result], [w, h])

        img.combine_options do |i|
          i.resize(op_resize)
          i.gravity(gravity)
          i.crop "#{w.to_i}x#{h.to_i}+#{w_offset}+#{h_offset}!" if options.crop
        end

        img
      end

      def crop_offsets_by_gravity(gravity, original_dimensions, cropped_dimensions)
        raise(ArgumentError, "Gravity must be one of #{GRAVITY_TYPES.inspect}") unless GRAVITY_TYPES.include?(gravity.to_sym)
        raise(ArgumentError, "Original dimensions must be supplied as a [ width, height ] array") unless original_dimensions.kind_of?(Enumerable) && original_dimensions.size == 2
        raise(ArgumentError, "Cropped dimensions must be supplied as a [ width, height ] array") unless cropped_dimensions.kind_of?(Enumerable) && cropped_dimensions.size == 2

        original_width, original_height = original_dimensions
        cropped_width, cropped_height = cropped_dimensions

        vertical_offset = case gravity
                            when :north_west, :north, :north_east then
                              0
                            when :center, :east, :west then
                              [((original_height - cropped_height) / 2.0).to_i, 0].max
                            when :south_west, :south, :south_east then
                              (original_height - cropped_height).to_i
                          end

        horizontal_offset = case gravity
                              when :north_west, :west, :south_west then
                                0
                              when :center, :north, :south then
                                [((original_width - cropped_width) / 2.0).to_i, 0].max
                              when :north_east, :east, :south_east then
                                (original_width - cropped_width).to_i
                            end

        [horizontal_offset, vertical_offset]
      end

      def load_file_path
        path = File.join(image.directory.images_path, name)
        mkdir_p(path) unless Dir.exists?(path)
        File.join(path, image.file_name)
      end

    end
  end
end