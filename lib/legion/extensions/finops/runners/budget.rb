# frozen_string_literal: true

module Legion
  module Extensions
    module Finops
      module Runners
        module Budget
          extend self

          def check_budget(worker_id:, tenant_id: nil, estimated_cost: 0, **)
            period_key = Time.now.utc.strftime('%Y-%m')
            results = []
            results << Helpers::BudgetStore.check_budget(
              entity_type: :worker, entity_id: worker_id,
              period_key: period_key, estimated_cost: estimated_cost
            )
            if tenant_id
              results << Helpers::BudgetStore.check_budget(
                entity_type: :tenant, entity_id: tenant_id,
                period_key: period_key, estimated_cost: estimated_cost
              )
            end
            blocked = results.find { |r| !r[:allowed] }
            blocked || { allowed: true }
          end

          def record_spend(worker_id:, cost_usd:, tenant_id: nil, team: nil, **)
            period_key = Time.now.utc.strftime('%Y-%m')
            all_alerts = []
            [[:worker, worker_id], [:tenant, tenant_id], [:team, team]].each do |type, id|
              next unless id

              result = Helpers::BudgetStore.record_spend(
                entity_type: type, entity_id: id,
                period_key: period_key, amount_usd: cost_usd
              )
              all_alerts.concat(result[:alerts]) if result[:alerts]
            end
            emit_budget_alerts(all_alerts) unless all_alerts.empty?
            { recorded: true, alerts_fired: all_alerts.size }
          end

          def set_budget(entity_type:, entity_id:, limit_usd:, hard_stop: false, **)
            period_key = Time.now.utc.strftime('%Y-%m')
            Helpers::BudgetStore.set_budget(
              entity_type: entity_type, entity_id: entity_id,
              limit_usd: limit_usd, period_key: period_key, hard_stop: hard_stop
            )
            { set: true, entity_type: entity_type, entity_id: entity_id, limit_usd: limit_usd }
          end

          def budget_status(entity_type:, entity_id:, **)
            period_key = Time.now.utc.strftime('%Y-%m')
            Helpers::BudgetStore.status(entity_type: entity_type, entity_id: entity_id, period_key: period_key)
          end

          private

          def emit_budget_alerts(alerts)
            return unless defined?(Legion::Events)

            alerts.each do |alert|
              Legion::Events.emit('finops.budget_alert', alert)
            end
          end
        end
      end
    end
  end
end
