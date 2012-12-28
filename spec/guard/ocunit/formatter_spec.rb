require "#{File.dirname(__FILE__)}/../../../lib/guard/ocunit/formatter"

describe Guard::OCUnit::Formatter do
  subject { Guard::OCUnit::Formatter.new(STDERR, false) }

  describe '#<<' do
    it 'counters success tests' do
      subject << "Test Case '-[testsPublicationCategories test2_shouldRequestPublicationsInAlphabetOrder]' passed (0.002 seconds)."
      subject.passed.should == 1
    end

    it 'counters failed tests' do
      subject << "Test Case '-[testsPublication test0_shouldFetchPublications]' failed (0.155 seconds)."
      subject.failed.should == 1
    end
  end

  describe '#dump_summary' do
    it 'notifies with current state' do
      subject.should_receive(:notify).with(
        /0 examples, 0 failures\nin 0.000\d seconds/,
        :success
      )
      subject.dump_summary
    end

    it 'notifies with current state' do
      subject.should_receive(:notify).with(
        /0 examples, 0 failures\nin 0.000\d seconds/,
        :success
      )
      subject.dump_summary
    end
  end

  describe '#guard_message' do
    context 'with a pending example' do
      it 'returns the notification message' do
        subject.guard_message(10, 2, 0, 5.1234567).should eq "10 examples, 2 failures\nin 5.1235 seconds"
      end
    end

    context 'without a pending example' do
      it 'returns the notification message' do
        subject.guard_message(10, 2, 1, 3.9876543).should eq "10 examples, 2 failures (1 pending)\nin 3.9877 seconds"
      end
    end
  end

  describe '#guard_image' do
    context 'with at least a failed example' do
      it 'always returns :failed' do
        subject.guard_image(1, 0).should eq :failed
      end
    end

    context 'with at least a pending example' do
      it 'returns :failed when there is at least one failed example' do
        subject.guard_image(1, 1).should eq :failed
      end

      it 'returns :pending when there is no failed example' do
        subject.guard_image(0, 1).should eq :pending
      end
    end

    it 'returns :success when no example failed or is pending' do
      subject.guard_image(0, 0).should eq :success
    end
  end

  describe '#priority' do
    it 'returns the failed priority' do
      subject.priority(:failed).should be 2
    end

    it 'returns the pending priority' do
      subject.priority(:pending).should be -1
    end

    it 'returns the success priority' do
      subject.priority(:success).should be -2
    end
  end

  describe '#notify' do
    it 'calls the guard notifier' do
      Guard::Notifier.should_receive(:notify).with(
          'This is the guard ocunit message',
          :title => 'OCUnit results',
          :image => :success,
          :priority => -2
      )
      subject.notify('This is the guard ocunit message', :success)
    end
  end

end
