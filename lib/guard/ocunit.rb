require 'guard'
require 'guard/guard'

module Guard
  class OCUnit < Guard
    autoload :Runner,    'guard/ocunit/runner'
    autoload :Inspector, 'guard/ocunit/inspector'

    attr_accessor :last_failed, :failed_paths, :runner, :inspector

    def initialize(watchers = [], options = {})
      super
      @options = {
        :focus_on_failed  => false,
        :all_after_pass   => true,
        :all_on_start     => true,
        :keep_failed      => true,
        :test_paths       => ["Tests"],
        :run_all          => {}
      }.merge(options)
      @last_failed  = false
      @failed_paths = []

      @inspector = Inspector.new(@options)
      @runner    = Runner.new(@options)
    end

    # Call once when guard starts
    def start
      UI.info "Guard::OCUnit is running"
      run_all if @options[:all_on_start]
    end

    def run_all
      options = @options[:run_all].merge(:message => 'Running all tests',
                                         :clean   => true)
      passed = @runner.run(['All'], options)

      unless @last_failed = !passed
        @failed_paths = []
      else
        throw :task_has_failed
      end
    end

    def reload
      @failed_paths = []
    end

    def run_on_changes(paths)
      original_paths = paths.dup

      focused = false
      if last_failed && @options[:focus_on_failed]
        path = './tmp/ocunit_guard_result'
        if File.exist?(path)
          single_test = paths && paths.length == 1 ? paths[0] : nil#&& paths[0].include?("_test")
          failed_tests = File.open(path) { |file| file.read.split("\n") }

          File.delete(path)

          if single_test && @inspector.clean([single_test]).length == 1
            failed_tests = failed_tests.select{|p| p.include? single_test}
          end

          if failed_tests.any?
            # some sane limit, stuff will explode if all tests fail
            #   ... cap at 10

            paths = failed_tests[0..10]
            focused = true
          end

          # switch focus to the single spec
          if single_test and failed_tests.length > 0
            focused = true
          end
        end
      end

      if focused
        add_failed(original_paths)
        add_failed(paths.map{|p| p.split(":")[0]})
      else
        paths += failed_paths if @options[:keep_failed]
        paths  = @inspector.clean(paths).uniq
      end

      if passed = @runner.run(paths)
        unless focused
          remove_failed(paths)
        end

        if last_failed && focused
          run_on_changes(failed_paths)
        # run all the tests if the run before this one failed
        elsif last_failed && @options[:all_after_pass]
          @last_failed = false
          run_all
        end
      else
        @last_failed = true
        unless focused
          add_failed(paths)
        end

        throw :task_has_failed
      end
    end

  private

    def run(paths)
    end

    def remove_failed(paths)
      @failed_paths -= paths if @options[:keep_failed]
    end

    def add_failed(paths)
      if @options[:keep_failed]
        @failed_paths += paths
        @failed_paths.uniq!
      end
    end

  end
end

