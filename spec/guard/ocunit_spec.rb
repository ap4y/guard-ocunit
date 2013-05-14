require 'spec_helper'
require 'fileutils'

describe Guard::OCUnit do
  let(:default_options) do
    {
      :focus_on_failed  => false,
      :all_after_pass   => true,
      :all_on_start     => true,
      :keep_failed      => true,
      :test_paths       => ['Tests'],
      :run_all          => {}
    }
  end
  subject { described_class.new }

  let(:inspector) { mock(described_class::Inspector, :excluded => nil, :test_paths => ['test'], :clean => []) }
  let(:runner)    { mock(described_class::Runner) }

  before do
    described_class::Runner.stub(:new => runner)
    described_class::Inspector.stub(:new => inspector)
  end

  shared_examples_for 'clear failed paths' do
    it 'should test the previously failed paths' do
      inspector.stub(:clean).and_return(['test/foo'], ['test/bar'])

      runner.should_receive(:run).with(['test/foo']) { false }
      expect { subject.run_on_changes(['test/foo']) }.to throw_symbol :task_has_failed

      runner.should_receive(:run) { true }
      expect { subject.run_all }.to_not throw_symbol # this actually clears the failed paths

      runner.should_receive(:run).with(['test/bar']) { true }
      subject.run_on_changes(['test/bar'])
    end
  end

  describe '.initialize' do
    it 'creates an inspector' do
      described_class::Inspector.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end

    it 'creates a runner' do
      described_class::Runner.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end
  end

  describe '#start' do
    it 'calls #run_all' do
      subject.should_receive(:run_all)
      subject.start
    end

    context ':all_on_start option is false' do
      let(:subject) { subject = described_class.new([], :all_on_start => false) }

      it "doesn't call #run_all" do
        subject.should_not_receive(:run_all)
        subject.start
      end
    end
  end

  describe '#run_all' do
    it "should run all tests from the bundle" do
      runner.should_receive(:run).with(['All'], anything) { true }

      subject.run_all
    end

    it 'passes the :run_all options' do
      subject = described_class.new([], {
        :verbose => true, :run_all => { :project => 'sample.xcodeproj' }
      })
      runner.should_receive(:run).with(['All'], hash_including(:project => 'sample.xcodeproj')) { true }

      subject.run_all
    end

    it 'passes the message to the runner' do
      runner.should_receive(:run).with(['All'], hash_including(:message => 'Running all tests')) { true }

      subject.run_all
    end

    it "throws task_has_failed if tests don't passed" do
      runner.should_receive(:run) { false }

      expect { subject.run_all }.to throw_symbol :task_has_failed
    end

    it_should_behave_like 'clear failed paths'
  end

  describe '#reload' do
    it_should_behave_like 'clear failed paths'

    it 'runs all tests with :clean option' do
      runner.should_receive(:run).with(['All'], :message => "Cleaning and running all tests", :clean => true) { true }
      subject.reload
    end
  end

  describe '#run_on_changes' do
    before { inspector.stub(:clean => ['test/foo']) }

    it 'runs octool with paths' do
      runner.should_receive(:run).with(['test/foo']) { true }

      subject.run_on_changes(['test/foo'])
    end

    context 'the changed tests pass after failing' do
      it 'calls #run_all' do
        runner.should_receive(:run).with(['test/foo']) { false }

        expect { subject.run_on_changes(['test/foo']) }.to throw_symbol :task_has_failed

        runner.should_receive(:run).with(['test/foo']) { true }
        subject.should_receive(:run_all)

        expect { subject.run_on_changes(['test/foo']) }.to_not throw_symbol
      end

      context ':all_after_pass option is false' do
        subject { described_class.new([], :all_after_pass => false) }

        it "doesn't call #run_all" do
          runner.should_receive(:run).with(['test/foo']) { false }

          expect { subject.run_on_changes(['test/foo']) }.to throw_symbol :task_has_failed

          runner.should_receive(:run).with(['test/foo']) { true }
          subject.should_not_receive(:run_all)

          expect { subject.run_on_changes(['test/foo']) }.to_not throw_symbol
        end
      end
    end

    context 'the changed tests pass without failing' do
      it "doesn't call #run_all" do
        runner.should_receive(:run).with(['test/foo']) { true }

        subject.should_not_receive(:run_all)

        subject.run_on_changes(['test/foo'])
      end
    end

    it 'keeps failed tests and rerun them later' do
      subject = described_class.new([], :all_after_pass => false)

      inspector.should_receive(:clean).with(['test/bar']).and_return(['test/bar'])
      runner.should_receive(:run).with(['test/bar']) { false }

      expect { subject.run_on_changes(['test/bar']) }.to throw_symbol :task_has_failed

      inspector.should_receive(:clean).with(['test/foo', 'test/bar']).and_return(['test/foo', 'test/bar'])
      runner.should_receive(:run).with(['test/foo', 'test/bar']) { true }

      subject.run_on_changes(['test/foo'])

      inspector.should_receive(:clean).with(['test/foo']).and_return(['test/foo'])
      runner.should_receive(:run).with(['test/foo']) { true }

      subject.run_on_changes(['test/foo'])
    end

    it "throws task_has_failed if tests doesn't pass" do
      runner.should_receive(:run).with(['test/foo']) { false }

      expect { subject.run_on_changes(['test/foo']) }.to throw_symbol :task_has_failed
    end

    describe "#run_on_changes focus_on_failed" do
      before do
        FileUtils.mkdir_p('tmp')
        File.open('./tmp/ocunit_guard_result', 'w') do |f|
          f.puts("./a_test.m:1\n./a_test.m:7")
        end
        @subject = described_class.new([], :focus_on_failed => true, :keep_failed => true)
        @subject.last_failed = true

        inspector.stub(:clean){|ary| ary}
      end

      it "switches focus if a single test changes" do
        runner.should_receive(:run).with(['b_test.m']).and_return(false)
        lambda { @subject.run_on_changes(['b_test.m']) }.should throw_symbol(:task_has_failed)
      end

      it "keeps focus if a single test remains" do
        runner.should_receive(:run).with(['./a_test.m:1', './a_test.m:7']) { false }
        lambda { @subject.run_on_changes(['a_test.m']) }.should throw_symbol(:task_has_failed)
      end

      it "keeps focus if random stuff changes" do
        runner.should_receive(:run).with(['./a_test.m:1', './a_test.m:7']) { false }
        lambda { @subject.run_on_changes(['bob.m','bill.m']) }.should throw_symbol(:task_has_failed)
      end

      it "reruns the tests on the file if keep_failed is true and focused tests pass" do

        # explanation of test:
        #
        # If we detect any change, we first check the last failure, we attempt to focus.
        # As soon as that passes we run all the tests that failed up until now
        #

        runner.should_receive(:run).with(['./a_test.m:1', './a_test.m:7']) { true }
        runner.should_receive(:run).with(['./a_test.m', './b_test']) { true }
        runner.should_receive(:run).with(['All'], :message => "Running all tests", :clean => false) { true }

        @subject.run_on_changes(['./a_test.m','./b_test'])
      end
    end
  end
end

