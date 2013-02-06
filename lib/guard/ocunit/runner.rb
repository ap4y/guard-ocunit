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
          :sdk              => 'iPhoneSimulator6.0',
          :verbose          => false,
          :notification     => true,
          :clean            => false,
          :build_variables  => nil,
          :test_variables   => nil
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
        options       = @options.merge(options)
        path_variables(options)

        # REVIEW: currently not all error messages are going to the output via
        #   formatter, decided to disable it

        # formatter     = XcodeBuild::Formatters::ProgressFormatter.new
        # reporter      = XcodeBuild::Reporter.new(formatter)
        # output_buffer = XcodeBuild::OutputTranslator.new(reporter)

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

        XcodeBuild.run(arguments.compact.join(' '), STDOUT)
      end

      def otest_path
        File.join(@sdk_root, 'Developer/usr/bin/otest')
      end

    private

      def path_variables(options)
        project_folder      = options[:project] && File.dirname(options[:project])
        @source_root        = project_folder || File.expand_path('..', __FILE__)
        @derived_data       = options[:derived_data] || @source_root
        @built_products_dir = File.join(@derived_data, 'build/')
        @dev_root           = '/Applications/Xcode.app/Contents/Developer'
        @sdk_root           = File.join(@dev_root, "Platforms/iPhoneSimulator.platform/Developer/SDKs/#{options[:sdk]}.sdk")
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

        stderr = OCUnit::Formatter.new(STDERR, options[:verbose])
        command = ''
        command << otest_environment_variables(options)
        command << otest_command(test_suites, options[:test_bundle])

        status = Open4.spawn(command, :stderr => stderr, :status => true)
        stderr.dump_summary(options[:notification])
        status.exitstatus
      end

      def otest_environment_variables(options)
        environment_variables = {
          'DYLD_FRAMEWORK_PATH'           => "#{@built_products_dir}:#{File.join(@sdk_root, 'Applications/Xcode.app/Contents/Developer/Library/Frameworks')}",
          'DYLD_LIBRARY_PATH'             =>  @built_products_dir,
          'DYLD_NEW_LOCAL_SHARED_REGIONS' => 'YES',
          'DYLD_NO_FIX_PREBINDING'        => 'YES',
          'DYLD_ROOT_PATH'                => @sdk_root,
          'IPHONE_SIMULATOR_ROOT'         => @sdk_root
          # 'CFFIXED_USER_HOME'             => File.expand_path('~/Library/Application Support/iPhone Simulator/')
        }

        environment = "export "
        joined = environment_variables.map do |key, value|
          "#{key}=#{value}"
        end
        environment << joined.join(' ') + ' '
        environment << options[:test_variables] unless options[:test_variables].to_s.empty?
        environment << ';'
      end

      def otest_command(test_suites, test_bundle)
        command = []
        command << "#{otest_path}"
        command << "-SenTest #{File.basename(test_suites, '.m')}"
        command << "#{File.join(@built_products_dir, "#{test_bundle}.octest")}"
        command.compact.join(' ')
      end
    end
  end
end
