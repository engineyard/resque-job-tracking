require 'resque/plugins/meta'

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

      def around_perform(meta_id, jobargs)
        identifier = nil
        if self.respond_to?(:track)
          identifier = track(*jobargs)
          Resque.redis.srem("#{identifier}:pending", meta_id)
          Resque.redis.sadd("#{identifier}:running", meta_id)
        end
        begin
          yield
        rescue => e
          if identifier
            Resque.redis.sadd("#{identifier}:failed", meta_id)
          end
          raise e
        ensure
          if identifier
            Resque.redis.srem("#{identifier}:running", meta_id)
          end
        end
      end

      def before_enqueue_job_tracking(meta_id, *jobargs)
        if self.respond_to?(:track)
          identifier = track(*jobargs)
          Resque.redis.sadd("#{identifier}:pending", meta_id)
        end
      end

    end
  end
end
