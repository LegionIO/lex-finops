# frozen_string_literal: true

module Legion
  module Extensions
    module Finops
      module Runners
        module CostAttribution
          extend self

          def attribute_cost(worker_id:, provider:, model:, input_tokens:, # rubocop:disable Metrics/ParameterLists
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

          SUMMARY_COLUMNS = %i[worker_id provider model_id].freeze

          def cost_summary(group_by: :worker_id, since: nil, limit: 20, **)
            return { error: 'data_unavailable' } unless metering_available?

            col = SUMMARY_COLUMNS.include?(group_by.to_sym) ? group_by.to_sym : :worker_id
            rows = aggregate_metering(col, since: since, limit: limit)
            { group_by: col, rows: rows, count: rows.size }
          end

          private

          def aggregate_metering(col, since:, limit:)
            ds = Legion::Data.connection[:metering_records]
            ds = ds.where { recorded_at >= since } if since
            ds.group_and_count(col)
              .select_append { sum(input_tokens).as(total_input) }
              .select_append { sum(output_tokens).as(total_output) }
              .select_append { sum(total_tokens).as(total_tokens) }
              .order(Sequel.desc(:count))
              .limit(limit)
              .all
          end

          def metering_available?
            defined?(Legion::Data) && Legion::Data.respond_to?(:connection) &&
              Legion::Data.connection&.table_exists?(:metering_records)
          rescue StandardError => _e
            false
          end

          def emit_attribution(record)
            Legion::Events.emit('finops.cost_attributed', record)
          end
        end
      end
    end
  end
end
