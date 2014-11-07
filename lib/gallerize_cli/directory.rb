require 'fileutils'
require 'gallerize_cli/image'

module GallerizeCli
  class Directory
    include FileUtils::Verbose

    attr_reader :root_path

    def initialize(path)
      @root_path = File.expand_path(path)
      puts "install root #{path}"
    end

    def perform
      install
      images.each { |i| puts i.thumb_url }
      images.each(&:process)
    end

    def images
      @images ||= load_images
    end

    def config
      @config ||= OpenStruct.new(YAML.load(File.read(File.join(app_install_path, 'config/gallerize_cli.yml'))))
    end

    def images_path
      @images_path ||= File.join(output_path, 'images')
    end

    def output_path
      @output_path ||= File.expand_path(config.output_path)
    end

    private

    def load_images
      output = []
      puts config
      Dir.chdir(root_path) do
        config.file_patterns.each do |file_pattern|
          Dir.glob(file_pattern) do |file_path|
            output << GallerizeCli::Image.new(self, file_path)
          end
        end
      end
      output
    end

    def install
      cp_r(GallerizeCli.app_source_path, app_install_path)
      mkdir_p(output_path)
      mkdir_p(images_path)
    end

    def app_install_path
      File.join(root_path, '.gallerize_cli')
    end

  end
end