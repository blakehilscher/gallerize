require 'gallerize_cli/directory'
require 'gallerize_cli/render'
require 'yaml'
require 'ostruct'
require 'pry'
require 'logger'

module GallerizeCli

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
      @logger ||= Logger.new(STDOUT)
    end

  end

end