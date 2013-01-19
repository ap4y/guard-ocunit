require 'spec_helper'

describe Guard::OCUnit::Runner do
  subject { described_class.new }

  describe '#run' do
    context 'when passed an empty paths list' do
      it 'returns false' do
        subject.run([]).should be_false
      end
    end

    context 'in project folder' do
      before do
        @build_path = @lib_path.join("guard/ocunit/build/")

        @mock_status = Object.new
        @mock_status.stub(:exitstatus).and_return(1)
      end

      it 'compiles with XcodeBuild' do
        XcodeBuild.should_receive(:run).with(
          "-sdk iphonesimulator6.0 " +
          "-configuration Debug -alltargets build " +
          "CONFIGURATION_BUILD_DIR=#{@build_path}",
          anything()
        ).and_return(-1)

        subject.xcodebuild()
      end

      it 'runs with Open4' do
        XcodeBuild.should_receive(:run).and_return(0)
        Open4.should_receive(:spawn).with(
          /otest -SenTest test #{@build_path}SampleAppTests.octest/,
          anything()
        ).and_return(@mock_status)

        subject.run(['test'], :test_bundle => 'SampleAppTests').should == true
      end

      describe 'result' do

        it 'returns false when build failed' do
          XcodeBuild.should_receive(:run).and_return(-1)

          subject.run(['test']).should == false
        end

        it 'returns false when octool failed' do
          XcodeBuild.should_receive(:run).and_return(0)
          failed_mock_status = Object.new
          failed_mock_status.stub(:exitstatus).and_return(2)
          Open4.should_receive(:spawn).and_return(failed_mock_status)

          subject.run(['test']).should == false
        end

        it 'returns true when build and tests passed' do
          XcodeBuild.should_receive(:run).and_return(0)
          Open4.should_receive(:spawn).and_return(@mock_status)

          subject.run(['test']).should == true
        end
      end

      describe 'notification' do
        it 'notifies when OCUnit fails to build' do
          XcodeBuild.should_receive(:run).and_return(-1)
          Guard::Notifier.should_receive(:notify).with(
            'Failed',
            :title => 'OCUnit results',
            :image => :failed,
            :priority => 2
          )

          subject.run(['test'])
        end

        it 'notifies when OCUnit fails to run' do
          XcodeBuild.should_receive(:run).and_return(0)
          subject.should_receive(:run_otest).and_return(-1)
          Guard::Notifier.should_receive(:notify).with(
            'Failed',
            :title => 'OCUnit results',
            :image => :failed,
            :priority => 2
          )

          subject.run(['test'])
        end

        it 'does not notify that OCUnit failed when the test pass' do
          XcodeBuild.should_receive(:run).and_return(0)
          subject.should_receive(:run_otest).and_return(1)
          Guard::Notifier.should_not_receive(:notify)

          subject.run(['test'])
        end
      end

      describe 'options' do

        describe ':test_bundle' do
          context ":test_bundle => 'SampleAppTests'" do
            subject { described_class.new(:test_bundle => 'SampleAppTests') }

            it "runs provided test bundle" do
              XcodeBuild.should_receive(:run).and_return(0)
              Open4.should_receive(:spawn).with(
                /otest -SenTest test #{@build_path}SampleAppTests.octest/,
                anything()
              ).and_return(@mock_status)

              subject.run(['test'])
            end
          end
        end

        describe ':derived_data' do
          context ":derived_data => '/tmp/sample/'" do
            subject { described_class.new(:derived_data => '/tmp/sample/') }

            it "builds to the provided folder" do
              XcodeBuild.should_receive(:run).with(
                "-sdk iphonesimulator6.0 " +
                "-configuration Debug -alltargets build " +
                "CONFIGURATION_BUILD_DIR=/tmp/sample/build/",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end

            it "runs test bundle from the provided folder" do
              XcodeBuild.should_receive(:run).and_return(0)
              Open4.should_receive(:spawn).with(
                %r{otest -SenTest test /tmp/sample/build/SampleAppTests.octest},
                anything()
              ).and_return(@mock_status)

              subject.run(['test'], :test_bundle => 'SampleAppTests')
            end
          end
        end

        describe ':workspace with :scheme' do
          context ":workspace => 'testWorkspace', :scheme => 'testScheme'" do
            subject { described_class.new(:workspace => 'testWorkspace', :scheme => 'testScheme') }

            it "builds scheme in workspace and do not include -alltargets" do
              XcodeBuild.should_receive(:run).with(
                "-workspace testWorkspace -scheme testScheme " +
                "-sdk iphonesimulator6.0 " +
                "-configuration Debug build " +
                "CONFIGURATION_BUILD_DIR=#{@build_path}",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end
          end
        end

        describe ':project' do
          context ":project => '~/Documents/SampleApp.xcodeproj'" do
            subject { described_class.new(:project => '~/Documents/SampleApp.xcodeproj') }

            it "builds project into it's own folder" do
              XcodeBuild.should_receive(:run).with(
                "-project ~/Documents/SampleApp.xcodeproj " +
                "-sdk iphonesimulator6.0 " +
                "-configuration Debug -alltargets build " +
                "CONFIGURATION_BUILD_DIR=~/Documents/build/",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end

            it "runs test from the project folder" do
              XcodeBuild.should_receive(:run).and_return(0)
              Open4.should_receive(:spawn).with(
                %r{otest -SenTest test ~/Documents/build/SampleAppTests.octest},
                anything()
              ).and_return(@mock_status)

              subject.run(['test'], :test_bundle => 'SampleAppTests')
            end
          end
        end

        describe ':sdk' do
          context ":sdk => 'iPhoneSimulator5.0'" do
            subject { described_class.new(:sdk => 'iPhoneSimulator5.0') }

            it "builds with provided sdk" do
              XcodeBuild.should_receive(:run).with(
                "-sdk iphonesimulator5.0 " +
                "-configuration Debug -alltargets build " +
                "CONFIGURATION_BUILD_DIR=#{@build_path}",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end

            it 'links against provided sdk' do
              XcodeBuild.should_receive(:run).and_return(0)
              Open4.should_receive(:spawn).with(
                /otest -SenTest test #{@build_path}SampleAppTests.octest/,
                anything()
              ).and_return(@mock_status)

              subject.run(['test'], :test_bundle => 'SampleAppTests')
            end
          end
        end

        describe ':notification' do
          context ':notification => false' do
            subject { described_class.new(:notification => false) }

            it "doesn't notify when test fails" do
              XcodeBuild.should_receive(:run).and_return(0)
              subject.should_receive(:run_otest).and_return(-1)
              Guard::Notifier.should_not_receive(:notify)

              subject.run(['test'])
            end
          end
        end

        describe ':clean' do
          context ':clean => true' do
            subject { described_class.new(:clean => true) }

            it "makes clean build of the project" do
              XcodeBuild.should_receive(:run).with(
                "-sdk iphonesimulator6.0 " +
                "-configuration Debug -alltargets clean build " +
                "CONFIGURATION_BUILD_DIR=#{@build_path}",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end
          end
        end

        describe ':build_variables' do
          context ":build_variables => 'TEST_HOST=build'" do
            subject { described_class.new(:build_variables => 'TEST_HOST=build') }

            it "makes clean build of the project" do
              XcodeBuild.should_receive(:run).with(
                "-sdk iphonesimulator6.0 " +
                "-configuration Debug -alltargets build " +
                "CONFIGURATION_BUILD_DIR=#{@build_path} " +
                "TEST_HOST=build",
                anything()
              ).and_return(-1)

              subject.run(['test'])
            end
          end
        end
      end
    end
  end
end
