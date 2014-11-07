require 'gallerize_cli/directory'

module GallerizeCli

  class << self
    def perform
      dir = GallerizeCli::Directory.new(File.expand_path('.'))
      dir.install
    end

    def app_path
      File.join(root, 'app')
    end

    def root
      @root ||= File.expand_path(File.join(__FILE__, '../../'))
    end

  end

end