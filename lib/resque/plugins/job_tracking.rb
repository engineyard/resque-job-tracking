require 'resque/plugins/meta'
require 'resque/plugins/job_tracking/meta_ext'

module Resque
  module Plugins
    module JobTracking
      def self.extended(mod)
        mod.extend(Resque::Plugins::Meta)
      end

      def self.pending_jobs(identifier)
        Resque.redis.smembers("#{identifier}:pending") || []
      end

      def self.running_jobs(identifier)
        Resque.redis.smembers("#{identifier}:running") || []
      end

      def self.failed_jobs(identifier)
        Resque.redis.smembers("#{identifier}:failed") || []
      end

      def before_enqueue_job_tracking(meta_id, *jobargs)
        if self.respond_to?(:track)
          identifier = track(*jobargs)
          Resque.redis.sadd("#{identifier}:pending", meta_id)
        end
      end

      def around_perform_job_tracking(meta_id, *jobargs)
        if self.respond_to?(:track)
          identifier = track(*jobargs)
          Resque.redis.srem("#{identifier}:pending", meta_id)
          Resque.redis.sadd("#{identifier}:running", meta_id)
          begin
            to_return = yield
            puts "passed, expiring now?"
            meta = get_meta(meta_id)
            meta.expire_in = 0
            meta.save
            to_return
          rescue => e
            Resque.redis.sadd("#{identifier}:failed", meta_id)
            puts "raised, expiring later? #{e.inspect}"
            meta = get_meta(meta_id)
            meta.expire_in = 1
            # self.expire_meta_in
            meta.save
            raise e
          ensure
            Resque.redis.srem("#{identifier}:running", meta_id)
          end
        else
          yield
        end
      end

    end
  end
end
