module WorkerSupport
  def work_until_finished
    workers = []
    5.times do
      workers << Process.fork do
        begin
          Resque.redis.client.reconnect
          Resque::Worker.new(:test).work(1)
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
      end
    end
    any_running = true
    while(any_running)
      any_running = false
      Resque.redis.keys("meta*").each do |key|
        meta = Resque::Plugins::Meta.get_meta(key.split(":").last)
        if meta.finished?
          # puts "finished #{meta['job_class']}"
        else
          any_running = true
          # puts "still running #{meta['job_class']}"
        end
      end
      sleep(0.5)
    end
  end
end