require 'fileutils'
# require 'sass/engine'
require 'gallerize_cli/image'
require 'sass'
require 'sass/engine'

module GallerizeCli
  class Directory
    include FileUtils::Verbose

    attr_reader :root_path

    def initialize(path)
      @root_path = File.expand_path(path)
    end

    def process
      install
      images.each(&:process)
    end

    def images
      @images ||= load_images
    end

    def config
      @config ||= OpenStruct.new(YAML.load(File.read(File.join(app_install_path, 'config/gallerize_cli.yml'))))
    end

    def assets_path
      @assets_path ||= File.join(output_path, 'assets')
    end

    def images_path
      @images_path ||= File.join(output_path, 'images')
    end

    def output_path
      @output_path ||= File.expand_path(config.output_path)
    end

    def app_install_path
      File.join(root_path, '.gallerize_cli')
    end

    def javascripts_min_path
      @javascripts_min_path ||= compile_javascripts
    end

    def stylesheets_min_path
      @stylesheets_min_path ||= compile_stylesheets.gsub(output_path, config.site_url)
    end

    private

    def compile_javascripts
      File.join(app_install_path, 'source/javascripts')
    end

    def compile_stylesheets
      # configure load_paths
      load_path = File.join(app_install_path, 'assets/stylesheets')
      # this is undefined for some unknown reason
      Sass.define_singleton_method(:load_paths) { [load_path] }
      # compile styles.scss
      scss_file = File.join(load_path, 'styles.scss')
      source = File.read(scss_file)
      output = Sass::Engine.new(source, style: :compressed, syntax: :scss).render
      # write new file
      output_file = File.join(assets_path, File.basename(scss_file, '.scss')) + "-#{Digest::MD5.hexdigest(output)}.css"
      GallerizeCli.logger.debug("generate #{output_file}")
      File.write(output_file, output)
      output_file
    end

    def load_images
      output = []
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
      mkdir_p(output_path) unless Dir.exists?(output_path)
      mkdir_p(images_path) unless Dir.exists?(images_path)
      mkdir_p(assets_path) unless Dir.exists?(assets_path)
    end

  end
end