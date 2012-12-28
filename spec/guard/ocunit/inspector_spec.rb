require 'spec_helper'

describe Guard::OCUnit::Inspector do

  describe '.initialize' do
    it 'accepts an :exclude option that sets @excluded' do
      inspector1 = described_class.new(:exclude => 'test/slow/*')

      inspector2 = described_class.new
      inspector2.excluded = 'test/slow/*'

      inspector1.excluded.should eq inspector2.excluded
    end

    it 'accepts a :test_paths option that sets @test_paths' do
      inspector1 = described_class.new(:test_paths => ['test/slow'])

      inspector2 = described_class.new
      inspector2.test_paths = ['test/slow']

      inspector1.test_paths.should eq inspector2.test_paths
    end
  end

  describe '#excluded=' do
    it 'runs a glob on the given pattern' do
      subject.excluded = 'test/slow/*'
      subject.excluded.should eq Dir['test/slow/*']
    end
  end

  describe '#test_paths=' do
    context 'given a string' do
      before { subject.test_paths = 'test' }

      it 'returns an array' do
        subject.test_paths.should eq ['test']
      end
    end

    context 'given an array' do
      before { subject.test_paths = ['test'] }

      it 'returns an array' do
        subject.test_paths.should eq ['test']
      end
    end
  end

  describe '#clean' do
    before do
      subject.excluded = nil
      @project_path = File.join(@fixture_path, 'SampleApp/SampleAppTests')
      subject.test_paths = [@project_path]
    end

    it 'removes non-test files' do
      subject.clean(["#{@project_path}/SampleAppTests.m",
                     "#{@project_path}/MKIssuesTests.h",
                    'MKIssues.m']
      ).should eq ["#{@project_path}/SampleAppTests.m"]
    end

    it 'removes test-looking but non-existing files' do
      subject.clean(["#{@project_path}/SampleAppTests.m", 'BobTests.m']).
      should eq ["#{@project_path}/SampleAppTests.m"]
    end

    it 'keeps test folder path' do
      subject.clean(["#{@project_path}/SampleAppTests.m", "#{@project_path}/Models"]).
      should eq ["#{@project_path}/SampleAppTests.m", "#{@project_path}/Models"]
    end

    it 'removes duplication' do
      subject.clean(["#{@project_path}", "#{@project_path}"]).
      should eq ["#{@project_path}"]
    end

    it 'removes test folders included in other test folders' do
      subject.clean(["#{@project_path}/Models", "#{@project_path}"]).
      should eq ["#{@project_path}"]
    end

    it 'removes test files included in test folders' do
      subject.clean(["#{@project_path}/SampleAppTests.m", "#{@project_path}"]).
      should eq ["#{@project_path}"]
    end

    it 'keeps top-level tests' do
      subject.clean(["#{@project_path}/SampleAppTests.m"]).
      should eq ["#{@project_path}/SampleAppTests.m"]
    end

    describe 'excluded files' do
      context 'with a path to a single test' do
        it 'ignores the one test' do
          subject.excluded = "#{@project_path}/SampleAppTests.m"
          subject.clean(["#{@project_path}/SampleAppTests.m"]).should be_empty
        end
      end

      context 'with a glob' do
        it 'ignores files recursively' do
          subject.excluded = "#{@fixture_path}/**/*"
          subject.clean(["#{@project_path}/SampleAppTests.m"]).should be_empty
        end
      end
    end

    describe 'test paths' do
      context 'with an expanded test path' do
        before { subject.test_paths = [@fixture_path, @project_path] }

        it 'should clean paths not specified' do
          subject.clean([
            'CleanMe/SampleAppTests.m', "#{@project_path}/SampleAppTests.m"
          ]).should eq ["#{@project_path}/SampleAppTests.m"]
        end
      end
    end
  end

end
