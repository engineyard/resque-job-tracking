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


class TypicalProblemJob < BaseJobWithPerform

  def self.track(account_id, something)
    Account.get(account_id).job_tracking_identifier
  end

  def perform(account_id, something)
    sleep(2)
    puts "something #{something}"
    if something == 'fail_please'
      raise "i fail now"
    end
  end

end


describe TypicalProblemJob do
  include WorkerSupport

  before do
    WhatHappened.reset!
    Resque.redis.flushall
  end
  after do
    cleanup
  end

  it "should keep meta data for failed jobs" do
    account = Account.create
    TypicalProblemJob.enqueue(account.id, 'fail_please')
    account.pending_jobs.size.should eq 1
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 0
    meta_id = account.pending_jobs.first
    TypicalProblemJob.get_meta(meta_id).should_not be_nil
    work(1)
    sleep(1)
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 1
    account.failed_jobs.size.should eq 0
    account.running_jobs.first.should eq meta_id
    TypicalProblemJob.get_meta(meta_id).should_not be_nil
    wait_until_finished
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 1
    account.failed_jobs.first.should eq meta_id
    meta = TypicalProblemJob.get_meta(meta_id)
    meta.should_not be_nil
    #TODO: assert that job args are in the meta data
  end

  it "should lose meta data for non-failing jobs" do
    account = Account.create
    TypicalProblemJob.enqueue(account.id, 'pass_please')
    account.pending_jobs.size.should eq 1
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 0
    meta_id = account.pending_jobs.first
    TypicalProblemJob.get_meta(meta_id).should_not be_nil
    work(1)
    sleep(1)
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 1
    account.failed_jobs.size.should eq 0
    account.running_jobs.first.should eq meta_id
    TypicalProblemJob.get_meta(meta_id).should_not be_nil
    wait_until_finished
    account.pending_jobs.size.should eq 0
    account.running_jobs.size.should eq 0
    account.failed_jobs.size.should eq 0
    sleep(1)
    TypicalProblemJob.get_meta(meta_id).should be_nil
  end

  it "should store the exception in meta data"

  it "should store the job class and args in meta data"

end
