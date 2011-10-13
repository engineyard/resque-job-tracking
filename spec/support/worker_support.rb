module WorkerSupport

  def work(worker_count = 5)
    @workers = []
    worker_count.times do
      @workers << Process.fork do
        begin
          Resque.redis.client.reconnect
          Resque::Worker.new(:test).work(1)
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
      end
    end
  end

  def finished?
    Resque.redis.keys("meta*").each do |key|
      meta = Resque::Plugins::Meta.get_meta(key.split(":").last)
      if meta.finished?
        # puts "finished #{meta['job_class']}"
      else
        return false
        # puts "still running #{meta['job_class']}"
      end
    end
    return true
  end

  def wait_until_finished
    while(!finished?)
      sleep(0.5)
    end
  end

  def work_until_finished
    work
    wait_until_finished
  end

  def cleanup
    if @workers
      @workers.each do |p|
        Process.kill(9, p)
      end
    end
  end

end