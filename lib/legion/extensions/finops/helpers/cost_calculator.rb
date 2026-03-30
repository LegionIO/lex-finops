# frozen_string_literal: true

module Legion
  module Extensions
    module Finops
      module Helpers
        module CostCalculator
          DEFAULT_RATES = { input_per_1k: 0.005, output_per_1k: 0.015, thinking_per_1k: 0.005 }.freeze

          module_function

          def estimate_cost(provider:, model:, input_tokens:, output_tokens:, thinking_tokens: 0)
            rates = pricing_for(provider, model)
            (input_tokens * rates[:input_per_1k] / 1000.0) +
              (output_tokens * rates[:output_per_1k] / 1000.0) +
              (thinking_tokens * rates[:thinking_per_1k] / 1000.0)
          end

          def pricing_for(provider, model)
            finops = finops_settings
            pricing = finops[:pricing]
            return DEFAULT_RATES unless pricing.is_a?(Hash)

            provider_pricing = pricing[provider.to_sym]
            return DEFAULT_RATES unless provider_pricing.is_a?(Hash)

            model_pricing = provider_pricing[model.to_s] || provider_pricing[:default]
            return model_pricing.transform_keys(&:to_sym) if model_pricing.is_a?(Hash)

            DEFAULT_RATES
          end

          def finops_settings
            settings = Legion::Settings[:finops]
            settings.is_a?(Hash) ? settings : {}
          rescue StandardError => _e
            {}
          end
        end
      end
    end
  end
end
