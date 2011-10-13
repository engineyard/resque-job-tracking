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

      def expire_normal_meta_in
        expire_meta_in
      end

      def expire_failures_meta_in
        expire_meta_in + (24 * 60 * 60)
      end

      def before_enqueue_job_tracking(meta_id, *jobargs)
        if self.respond_to?(:track)
          identifiers = track(*jobargs)
          identifiers.each do |ident|
            Resque.redis.sadd("#{ident}:pending", meta_id)
          end
          meta = get_meta(meta_id)
          meta["job_args"] = jobargs
          meta.save
        end
      end

      def around_perform_job_tracking(meta_id, *jobargs)
        if self.respond_to?(:track)
          identifiers = track(*jobargs)
          identifiers.each do |ident|
            Resque.redis.srem("#{ident}:pending", meta_id)
            Resque.redis.sadd("#{ident}:running", meta_id)
          end
          begin
            to_return = yield
            meta = get_meta(meta_id)
            meta.expire_in = expire_normal_meta_in
            meta.save
            to_return
          rescue => e
            identifiers.each do |ident|
              Resque.redis.sadd("#{ident}:failed", meta_id)
            end
            meta = get_meta(meta_id)
            meta.expire_in = expire_failures_meta_in
            meta['exception_message'] = e.message
            meta['exception_backtrace'] = e.backtrace
            meta.save
            raise e
          ensure
            identifiers.each do |ident|
              Resque.redis.srem("#{ident}:running", meta_id)
            end
          end
        else
          yield
        end
      end

    end
  end
end
