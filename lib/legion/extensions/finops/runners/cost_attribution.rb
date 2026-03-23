# frozen_string_literal: true

module Legion
  module Extensions
    module Finops
      module Runners
        module CostAttribution
          def attribute_cost(worker_id:, provider:, model:, input_tokens:,
                             output_tokens:, tenant_id: nil, team: nil,
                             task_id: nil, extension: nil, thinking_tokens: 0, **)
            cost = Helpers::CostCalculator.estimate_cost(
              provider: provider, model: model,
              input_tokens: input_tokens, output_tokens: output_tokens,
              thinking_tokens: thinking_tokens
            )

            record = {
              worker_id: worker_id, tenant_id: tenant_id, team: team,
              task_id: task_id, extension: extension,
              provider: provider, model: model,
              input_tokens: input_tokens, output_tokens: output_tokens,
              thinking_tokens: thinking_tokens,
              cost_usd: cost, attributed_at: Time.now.utc.iso8601
            }

            emit_attribution(record) if defined?(Legion::Events)
            record
          end

          def cost_summary(group_by: :tenant_id, **)
            { group_by: group_by, note: 'requires legion-data metering tables for full aggregation' }
          end

          private

          def emit_attribution(record)
            Legion::Events.emit('finops.cost_attributed', record)
          end
        end
      end
    end
  end
end
