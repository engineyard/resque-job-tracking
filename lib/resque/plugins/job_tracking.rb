require 'resque/plugins/meta'

module Resque
  module Plugins
    module JobTracking
      def self.extended(mod)
        mod.extend(Resque::Plugins::Meta)
      end
    end
  end
end
