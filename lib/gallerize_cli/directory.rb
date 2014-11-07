require 'fileutils'

module GallerizeCli
  class Directory

    attr_reader :root_path

    def initialize(path)
      @root_path = path
    end

    def install
      install_app
    end

    private

    def install_app
      FileUtils.cp_r(GallerizeCli.app_path, app_path)
    end

    def app_path
      File.join(root_path, '.gallerize')
    end

  end
end