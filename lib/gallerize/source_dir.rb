class Gallerize
  class SourceDir
  
    def config?
      File.exists?(config)
    end
  
    def config
      File.join( root, '.gallerize')
    end
  
    def root
      @root ||= File.expand_path('.')
    end
  
  end
end