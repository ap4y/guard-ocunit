module Guard
  class OCUnit
    class Inspector

      def initialize(options = {})
        self.excluded   = options[:exclude]
        self.test_paths = options[:test_paths]
      end

      def excluded
        @excluded || []
      end

      def excluded=(pattern)
        @excluded = Dir[pattern.to_s]
      end

      def test_paths
        @test_paths || []
      end

      def test_paths=(paths)
        @test_paths = Array(paths)
      end

      def clean(paths)
        paths.uniq!
        paths.compact!
        clear_test_files_list_after do
          paths = paths.select { |path| should_run_test_file?(path) }
        end
        paths.reject { |p| included_in_other_path?(p, paths) }
      end

    private

      def should_run_test_file?(path)
        (test_file?(path) || test_folder?(path)) && !excluded.include?(path)
      end

      def test_file?(path)
        test_files.include?(path)
      end

      def test_folder?(path)
        path.match(%r{^(#{test_paths.join("|")})[^\.]*$})
      end

      def test_files
        @test_files ||= test_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*.m")] }.flatten
      end

      def clear_test_files_list_after
        yield
        @test_files = nil
      end

      def included_in_other_path?(path, paths)
        (paths - [path]).any? { |p| path.include?(p) && path.sub(p, '').include?('/') }
      end

    end
  end
end
