require 'haml'

module GallerizeCli
  class Render

    attr_accessor :directory

    def initialize(directory)
      @directory = directory
    end

    def perform
      GallerizeCli.logger.debug("generate #{output_file}")
      File.write(output_file, Haml::Engine.new(template).render(directory))
    end

    def output_file
      File.join(directory.output_path, 'index.html')
    end

    def template
      @template ||= File.read(File.join(templates_path, 'layout.html.haml'))
    end

    def templates_path
      @templates_path ||= File.join(directory.app_install_path, 'templates')
    end

  end
end
