require 'haml'
require 'forwardable'

module GallerizeCli
  class Render

    attr_accessor :directory

    def initialize(directory)
      @directory = directory
    end

    def perform
      index = 1
      directory.images.each_slice(directory.config.images_per_page) do |images|
        file = File.join(directory.output_path, 'index.html')
        file = File.join(directory.output_path, "page-#{index}.html") if index != 1
        View.new(directory, file, {images: images, page_index: index}).render
        index += 1
      end
    end

    def output_file
      File.join(directory.output_path, 'index.html')
    end

    class View
      extend Forwardable

      attr_reader :directory, :file_path, :locals

      def_delegators :@directory, :javascripts_min_path, :stylesheets_min_path, :config, :total_images_count

      def initialize(directory, file_path, locals={})
        @directory = directory
        @file_path = file_path
        @locals = locals
      end

      def render
        GallerizeCli.logger.debug("generate #{file_path}")
        File.write(file_path, Haml::Engine.new(template).render(self, locals))
      end

      def site_url(path=nil)
        File.join(config.site_url, path)
      end

      def current_page
        (locals[:page_index] + 1 / directory.config.images_per_page)
      end

      def total_pages
        directory.total_images_count / directory.config.images_per_page
      end

      private

      def template
        @template ||= File.read(File.join(templates_path, 'layout.html.haml'))
      end

      def templates_path
        @templates_path ||= File.join(directory.app_install_path, 'templates')
      end

    end

  end
end
