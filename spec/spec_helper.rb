# frozen_string_literal: true

require 'bundler/setup'
require 'legion/logging'
require 'legion/settings'
require 'legion/cache/helper'
require 'legion/crypt/helper'
require 'legion/data/helper'
require 'legion/json/helper'
require 'legion/transport/helper'

# Spec-only stubs and sub-gem helper wiring for Legion namespace
module Legion
  # Test helpers for Legion::Settings (not part of the gem's public API)
  module Settings
    @_test_overrides = {} # rubocop:disable ThreadSafety/MutableClassInstanceVariable

    class << self
      def []=(key, val)
        @_test_overrides[key.to_sym] = val
      end

      alias _legion_settings_orig_get []

      def [](key)
        sym = key.to_sym
        @_test_overrides.key?(sym) ? @_test_overrides[sym] : _legion_settings_orig_get(sym)
      end

      def reset!
        @_test_overrides = {}
      end
    end
  end

  module Extensions
    module Helpers
      module Lex
        include Legion::Logging::Helper
        include Legion::Settings::Helper
        include Legion::Cache::Helper
        include Legion::Crypt::Helper
        include Legion::Data::Helper
        include Legion::JSON::Helper
        include Legion::Transport::Helper
      end
    end

    module Actors
      class Every
        include Helpers::Lex
      end

      class Once
        include Helpers::Lex
      end
    end
  end

  module Events
    def self.emit(_event, _payload = {}); end
  end
end

require 'legion/extensions/finops'
require 'legion/extensions/finops/helpers/cost_calculator'
require 'legion/extensions/finops/helpers/budget_store'
require 'legion/extensions/finops/runners/budget'
require 'legion/extensions/finops/runners/cost_attribution'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
