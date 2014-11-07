require 'gallerize_cli/directory'
require 'yaml'
require 'ostruct'
require 'pry'

module GallerizeCli

  class << self
    def perform
      puts "source root: #{root}"
      GallerizeCli::Directory.new(File.expand_path('.')).perform
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