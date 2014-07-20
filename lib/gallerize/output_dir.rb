class Gallerize
  class OutputDir
  
    attr_accessor :root
  
    def initialize(path)
      self.root = path
    end
  
    def root=(value)
      @root = File.join( File.expand_path('.'), (value || 'gallerize') )
    end
  
    def relative_root
      @relative_root ||= root.gsub(File.expand_path('.').to_s + "/", './')
    end
  
    def html_file(name)
      name = name.to_s
      name = "#{name}.html" unless name =~ /\.html/
      File.join(root, name)
    end
  
    def images
      File.join( root, 'images' )
    end
  
    def html_files
      File.join( root, '*.html')
    end
  
    def copy_from_gem_source(*folders)
      folders.each do |folder|
        outdir = File.join( root, folder )
        unless Dir.exists?(outdir)
          puts "copy ./#{folder} #{outdir}"
          FileUtils.mkdir_p( File.expand_path(File.join(outdir, '..')) )
          FileUtils.cp_r( File.join( ROOT, folder ), outdir )
        end
      end
    end

  end
end