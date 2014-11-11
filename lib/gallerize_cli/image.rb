require 'gallerize_cli/image/version'

module GallerizeCli
  class Image
    include FileUtils::Verbose

    attr_reader :directory, :file_path, :versions

    class << self

      def generate_version_method(name)
        unless public_method_defined?("#{name}_url")
          define_method("#{name}_url") { self.versions[name].url }
        end
      end

    end

    def attributes
      @attributes ||= fetch_attributes
    end

    def original_url
      destination = File.join(directory.images_path, file_name)
      cp(file_path, destination) unless File.exists?(destination)
      destination.gsub(directory.output_path, config.site_url)
    end

    def initialize(directory, file_path)
      @success = true
      @directory = directory
      @file_path = file_path
      generate_version_methods
    end

    def process
      versions.each { |name, version| version.process }
    end

    def name
      return @name if defined?(@name)
      parts = file_name.split('.')
      parts.pop
      @name = parts.join('.')
    end

    def file_name
      @file_name ||= File.basename(file_path)
    end

    def config
      directory.config
    end

    def versions
      @versions ||= config.versions.inject({}) do |hash, (version_name, options)|
        hash[version_name] = GallerizeCli::Image::Version.new(self, version_name, options)
        hash
      end
    end

    def valid?
      versions.collect(&:valid?).include?(false)
    end

    private

    def fetch_attributes
      hash = {}
      if config.image_attributes.is_a?(Hash)
        hash = config.image_attributes[file_name] || {}
      end
      OpenStruct.new(hash)
    end

    def generate_version_methods
      versions.each do |name, version|
        self.class.generate_version_method(name)
      end
    end

    def success?
      @success
    end

  end
end