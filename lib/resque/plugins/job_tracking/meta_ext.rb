#TODO: send a PULL request with this change!!!
Resque::Plugins::Meta::Metadata.class_eval do

  def initialize(data_hash)
    data_hash['enqueued_at'] ||= to_time_format_str(Time.now)
    @data = data_hash
    @meta_id = data_hash['meta_id'].dup
    @enqueued_at = from_time_format_str('enqueued_at')
    @job_class = data_hash['job_class']
    if @job_class.is_a?(String)
      @job_class = Resque.constantize(data_hash['job_class'])
    else
      data_hash['job_class'] = @job_class.to_s
    end
    @expire_in = data_hash["expire_in"] || @job_class.expire_meta_in || 0
  end

  def expire_in=(val)
    @expire_in = val
    data["expire_in"] = val
  end

end