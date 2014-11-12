require 'gallerize_cli/directory'
require 'gallerize_cli/render'
require 'yaml'
require 'ostruct'
require 'logger'

module GallerizeCli

  VERSION='0.3.2'

  class << self
    def perform
      directory = GallerizeCli::Directory.new(File.expand_path('.'))
      directory.process
      GallerizeCli::Render.new(directory).perform
    end

    def app_source_path
      File.join(root, 'app')
    end

    def root
      @root ||= File.expand_path(File.join(__FILE__, '../../'))

    end

    def logger
      @logger ||= init_logger
    end

    private
    def init_logger
      l = Logger.new(STDOUT)
      l.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime("%Y-%m-%d %H:%M:%S")}: #{msg}\n"
      end
      l
    end

  end

end