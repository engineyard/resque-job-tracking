require 'resque'
require 'resque/plugins/job_tracking'

require 'spec_helper'

class WhatHappened
  require 'tempfile'  
  def self.reset!
    @what_happened = Tempfile.new("what_happened")
  end
  def self.what_happened
    File.read(@what_happened.path)
  end
  def self.record(*event)
    @what_happened.write(event.to_s)
    @what_happened.flush
  end
end

class BaseJobWithPerform
  extend Resque::Plugins::JobTracking
  def self.queue
    :test
  end

  def self.perform(meta_id, *args)
    self.new.perform(*args)
  end

end


class Thing < BaseJobWithPerform

  def perform(*args)
    WhatHappened.record("running Thing #{args}")
  end

end


describe Thing do
  include WorkerSupport
  before do
    WhatHappened.reset!
    Resque.redis.flushall
  end

  it "should run" do
    Thing.enqueue
    work_until_finished
    p WhatHappened.what_happened
  end
end
