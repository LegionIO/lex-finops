# frozen_string_literal: true

module Legion
  module Extensions
    module Finops
      module Helpers
        module BudgetStore
          BudgetEntry = Struct.new(:entity_type, :entity_id, :period_key, :limit_usd,
                                   :spent_usd, :hard_stop, :alerts_sent)

          ALERT_THRESHOLDS = [50, 75, 90, 100].freeze

          @mutex = Mutex.new
          @budgets = {}

          module_function

          def set_budget(entity_type:, entity_id:, limit_usd:, period_key:, hard_stop: false)
            key = budget_key(entity_type, entity_id, period_key)
            @mutex.synchronize do
              @budgets[key] = BudgetEntry.new(
                entity_type: entity_type, entity_id: entity_id, period_key: period_key,
                limit_usd: limit_usd, spent_usd: 0.0, hard_stop: hard_stop, alerts_sent: Set.new
              )
            end
          end

          def record_spend(entity_type:, entity_id:, period_key:, amount_usd:)
            key = budget_key(entity_type, entity_id, period_key)
            alerts = []
            @mutex.synchronize do
              entry = @budgets[key]
              return { recorded: false, reason: :no_budget } unless entry

              entry.spent_usd += amount_usd
              alerts = check_thresholds(entry)
            end
            { recorded: true, alerts: alerts }
          end

          def check_budget(entity_type:, entity_id:, period_key:, estimated_cost: 0)
            key = budget_key(entity_type, entity_id, period_key)
            @mutex.synchronize do
              entry = @budgets[key]
              return { allowed: true, reason: :no_budget } unless entry

              remaining = [entry.limit_usd - entry.spent_usd, 0].max
              pct = ((entry.spent_usd + estimated_cost) / entry.limit_usd * 100).round(1)
              if pct >= 100 && entry.hard_stop
                { allowed: false, reason: :hard_stop, percent_used: pct, remaining_usd: remaining }
              else
                { allowed: true, percent_used: pct, remaining_usd: remaining }
              end
            end
          end

          def status(entity_type:, entity_id:, period_key:)
            key = budget_key(entity_type, entity_id, period_key)
            @mutex.synchronize { @budgets[key]&.to_h }
          end

          def clear_all
            @mutex.synchronize { @budgets.clear }
          end

          def check_thresholds(entry)
            pct = (entry.spent_usd / entry.limit_usd * 100).round(1)
            alerts = []
            ALERT_THRESHOLDS.each do |t|
              threshold_sym = :"t#{t}"
              next unless pct >= t && !entry.alerts_sent.include?(threshold_sym)

              entry.alerts_sent.add(threshold_sym)
              alerts << { threshold: t, percent_used: pct,
                          entity_type: entry.entity_type, entity_id: entry.entity_id }
            end
            alerts
          end
          private_class_method :check_thresholds

          def budget_key(entity_type, entity_id, period_key)
            "#{entity_type}:#{entity_id}:#{period_key}"
          end
          private_class_method :budget_key
        end
      end
    end
  end
end
