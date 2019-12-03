module CodeshipApi
  class Pipeline < Base
    class Metrics < Base
      api_attrs :ami_id, :queries, :cpi_user, :duration, :cpu_system, :instance_id,
        :instance_type, :cpu_per_second, :disk_free_bytes, :disk_used_bytes,
        :network_rx_bytes, :network_tx_bytes, :max_used_connections,
        :memory_max_usage_in_bytes
      parsed_time_attrs :max_used_connections # weird that this is a time value
      integer_attrs :cpu_per_second, :cpu_system, :disk_free_bytes, :disk_used_bytes, :duration, :memory_max_usage_in_bytes, :network_rx_bytes, :network_tx_bytes, :queries
    end

    api_attrs :uuid, :build_uuid, :type, :status, :metrics,
      :created_at, :updated_at, :finished_at
    parsed_time_attrs :finished_at

    TYPES = %w[build deploy].each do |type|
      define_method("#{type}?") do
        self.type == type
      end
    end

    STATES = %w[success initiated].each do |state|
      define_method("#{state}?") do
        self.status == state
      end
    end

    def self.find_all_by_build(build)
      CodeshipApi.client.get(build.uri + "/pipelines")["pipelines"].map do |attrs|
        new(attrs)
      end
    end

    def metrics=(attrs)
      @metrics = Metrics.new(attrs) if attrs
    end

    def duration
      duration_in_seconds / 60
    end

    def duration_in_seconds
      (finished_at || Time.now) - created_at
    end
  end
end
