require 'xcodebuild'
require 'open4'
require 'guard/ocunit/formatter'

module Guard
  class OCUnit
    class Runner

      SUCCESS_BUILD_CODE = 0
      #octool returns 0 if wasn't able to run
      #also 0 if passed and 1 if tests failed
      SUCCESS_EXIT_CODE  = 0
      MISC_ERROR_EXIT_CODE  = 1

      attr_accessor :options

      def initialize(options = {})
        @options = {
          :test_bundle      => nil,
          :derived_data     => '/tmp/tests/',
          :workspace        => nil,
          :scheme           => nil,
          :project          => nil,
          :sdk              => 'iphonesimulator',
          :verbose          => false,
          :notification     => true,
          :clean            => false,
          :build_variables  => nil,
          :ios_sim_opts     => nil
        }.merge(options)
      end

      def run(paths, options = {})
        return false if paths.empty?

        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info(message, :reset => true)

        options = @options.merge(options)
        run_via_shell(paths, options)
      end

      def xcodebuild(options = {})
        options = @options.merge(options)
        path_variables(options)

        formatter     = XcodeBuild::Formatters::ProgressFormatter.new
        reporter      = XcodeBuild::Reporter.new(formatter)
        output_buffer = XcodeBuild::OutputTranslator.new(reporter)

        arguments = []
        arguments << "-workspace #{options[:workspace]}" unless options[:workspace].to_s.empty?
        arguments << "-scheme #{options[:scheme]}" unless options[:scheme].to_s.empty?
        arguments << "-project #{options[:project]}" unless options[:project].to_s.empty?
        arguments << "-sdk #{options[:sdk].downcase}"
        arguments << "-configuration Debug"
        arguments << "-alltargets" if options[:workspace].to_s.empty?
        arguments << "clean" if options[:clean]
        arguments << "build"
        arguments << "CONFIGURATION_BUILD_DIR=#{@built_products_dir}"
        arguments << options[:build_variables] unless options[:build_variables].to_s.empty?

        XcodeBuild.run(arguments.compact.join(' '), output_buffer)
      end

    private

      def path_variables(options)
        project_folder      = options[:project] && File.dirname(options[:project])
        @derived_data       = project_folder || options[:derived_data]
        @built_products_dir = File.join(@derived_data, 'build/')

        scheme_name         = options[:scheme]
        @test_bundle_path   = File.join(@built_products_dir, "#{options[:test_bundle]}.octest")
        @test_host          = File.join(@built_products_dir, "#{scheme_name}.app", "#{scheme_name}")
      end

      def run_via_shell(paths, options)
        build_status = xcodebuild(options)

        status = run_otest(paths, options) if build_status == SUCCESS_BUILD_CODE

        if options[:notification] &&
          ( !( (0..1) === status ) || build_status != SUCCESS_BUILD_CODE )
          Notifier.notify("Failed", :title => "OCUnit results",
                                    :image => :failed,
                                    :priority => 2)
        end

        build_status == SUCCESS_BUILD_CODE && (0..1) === status
      end

      def run_otest(paths, options)
        test_suites = paths.uniq.join(',')

        stderr  = OCUnit::Formatter.new(STDERR, options[:verbose])
        command = otest_command(test_suites)

        status = Open4.spawn(command, :stderr => stderr, :status => true)
        stderr.dump_summary(options[:notification])
        status.exitstatus
      end

      def otest_environment_variables()
        environment_variables = {
          'DYLD_INSERT_LIBRARIES' => "/../../Library/PrivateFrameworks/IDEBundleInjection.framework/IDEBundleInjection",
          'XCInjectBundle'        => @test_bundle_path,
          'XCInjectBundleInto'    => @test_host
        }

        mapped = environment_variables.map do |key, value|
          "--setenv #{key}=\"#{value}\""
        end
        mapped.join(' ')
      end

      def otest_command(test_suites)
        command = []
        command << 'ios-sim launch'
        command << "\"#{File.dirname(@test_host)}\""
        command << "#{otest_environment_variables()}"
        command << options[:ios_sim_opts] unless options[:ios_sim_opts].to_s.empty?
        command << '--args'
        command << "-SenTest #{File.basename(test_suites, '.m')}"
        command << "#@test_bundle_path"
        command.compact.join(' ')
      end
    end
  end
end
