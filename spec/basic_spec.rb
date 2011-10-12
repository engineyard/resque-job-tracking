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

class BasicJob
  extend Resque::Plugins::JobTracking
  @queue = :test
    
  def self.perform(*args)
    begin
      WhatHappened.record(self, args)
    rescue => e
      puts e.inspect
      puts e.backtrace.join("\n")
    end
  end
end


describe "the basics" do
  before do
    WhatHappened.reset!
    Resque.redis.flushall
  end

  it "works" do
    meta = BasicJob.enqueue('foo', 'bar')
    worker = Resque::Worker.new(:test)
    worker.work(0)
    meta = BasicJob.get_meta(meta.meta_id)
    WhatHappened.what_happened.should == "BasicJob#{meta.meta_id}foobar"
  end
end
