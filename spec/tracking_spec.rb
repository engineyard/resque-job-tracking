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
    begin
      around_perform(meta_id, args) do
        self.new.perform(*args)
      end
    rescue => e
      puts e.inspects
      puts e.backtrace.join("\n")
    end
  end

end

require 'cubbyhole/base'
class Account < Cubbyhole::Base

  def pending_jobs
    Resque::Plugins::JobTracking.pending_jobs(job_tracking_identifier)
  end

  def running_jobs
    Resque::Plugins::JobTracking.running_jobs(job_tracking_identifier)
  end

  def failed_jobs
    Resque::Plugins::JobTracking.failed_jobs(job_tracking_identifier)
  end

  def job_tracking_identifier
    "account#{self.id}"
  end

end


class TakesALongTimeAndThenFails < BaseJobWithPerform

  def self.track(account_id)
    Account.get(account_id).job_tracking_identifier
  end

  def perform(account_id)
    sleep(2)
    raise "i fail now"
  end

end


describe TakesALongTimeAndThenFails do
  include WorkerSupport

  before do
    WhatHappened.reset!
    Resque.redis.flushall
  end
  after do
    cleanup
  end

  it "should run and fail and be tracked" do
    account = Account.create
    TakesALongTimeAndThenFails.enqueue(account.id)
    account.pending_jobs.size.should eq 1
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 0
    work(1)
    sleep(1)
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 1
    account.failed_jobs.size.should eq 0
    wait_until_finished
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 1
  end

  it "should store the exception in meta data"

  it "should store the job class and args in meta data"

end
