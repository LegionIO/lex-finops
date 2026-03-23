# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Finops::Runners::Budget do
  let(:host) { Object.new.extend(described_class) }

  before do
    Legion::Extensions::Finops::Helpers::BudgetStore.clear_all
  end

  after do
    Legion::Extensions::Finops::Helpers::BudgetStore.clear_all
  end

  describe '#check_budget' do
    it 'allows when no budgets configured' do
      result = host.check_budget(worker_id: 'w1')
      expect(result[:allowed]).to be true
    end

    it 'blocks when worker over hard-stop budget' do
      Legion::Extensions::Finops::Helpers::BudgetStore.set_budget(
        entity_type: :worker, entity_id: 'w1',
        limit_usd: 10.0, period_key: Time.now.utc.strftime('%Y-%m'), hard_stop: true
      )
      Legion::Extensions::Finops::Helpers::BudgetStore.record_spend(
        entity_type: :worker, entity_id: 'w1',
        period_key: Time.now.utc.strftime('%Y-%m'), amount_usd: 10.0
      )
      result = host.check_budget(worker_id: 'w1', estimated_cost: 1.0)
      expect(result[:allowed]).to be false
    end
  end

  describe '#record_spend' do
    it 'records spend and returns alert count' do
      Legion::Extensions::Finops::Helpers::BudgetStore.set_budget(
        entity_type: :worker, entity_id: 'w1',
        limit_usd: 100.0, period_key: Time.now.utc.strftime('%Y-%m')
      )
      result = host.record_spend(worker_id: 'w1', cost_usd: 51.0)
      expect(result[:recorded]).to be true
      expect(result[:alerts_fired]).to eq(1)
    end
  end

  describe '#set_budget' do
    it 'sets a budget' do
      result = host.set_budget(entity_type: :tenant, entity_id: 't1', limit_usd: 500.0)
      expect(result[:set]).to be true
      expect(result[:limit_usd]).to eq(500.0)
    end
  end

  describe '#budget_status' do
    it 'returns current budget status' do
      host.set_budget(entity_type: :worker, entity_id: 'w1', limit_usd: 100.0)
      status = host.budget_status(entity_type: :worker, entity_id: 'w1')
      expect(status[:limit_usd]).to eq(100.0)
    end
  end
end
