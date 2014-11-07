module GallerizeCli
  class Image
    include FileUtils::Verbose

    attr_reader :directory, :image_path

    def initialize(directory, image_path)
      @directory = directory
      @image_path = image_path
    end

    def process
      generate_versions
    end

    private

    def generate_versions
      config.versions.each do |version_name, options|
        puts "#{version_name} #{options}"
      end
    end

    def config
      directory.config
    end

  end
end