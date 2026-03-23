# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Finops::Helpers::BudgetStore do
  before { described_class.clear_all }
  after { described_class.clear_all }

  describe '.set_budget and .check_budget' do
    it 'allows spend within budget' do
      described_class.set_budget(entity_type: :tenant, entity_id: 't1', limit_usd: 100.0, period_key: '2026-03')
      result = described_class.check_budget(entity_type: :tenant, entity_id: 't1', period_key: '2026-03')
      expect(result[:allowed]).to be true
    end

    it 'blocks when hard_stop and over budget' do
      described_class.set_budget(
        entity_type: :tenant, entity_id: 't1', limit_usd: 10.0, period_key: '2026-03', hard_stop: true
      )
      described_class.record_spend(entity_type: :tenant, entity_id: 't1', period_key: '2026-03', amount_usd: 10.0)
      result = described_class.check_budget(
        entity_type: :tenant, entity_id: 't1', period_key: '2026-03', estimated_cost: 1.0
      )
      expect(result[:allowed]).to be false
      expect(result[:reason]).to eq(:hard_stop)
    end

    it 'allows when no budget configured' do
      result = described_class.check_budget(entity_type: :tenant, entity_id: 'unknown', period_key: '2026-03')
      expect(result[:allowed]).to be true
    end

    it 'reports remaining budget' do
      described_class.set_budget(entity_type: :worker, entity_id: 'w1', limit_usd: 50.0, period_key: '2026-03')
      described_class.record_spend(entity_type: :worker, entity_id: 'w1', period_key: '2026-03', amount_usd: 20.0)
      result = described_class.check_budget(entity_type: :worker, entity_id: 'w1', period_key: '2026-03')
      expect(result[:remaining_usd]).to eq(30.0)
    end
  end

  describe '.record_spend' do
    it 'triggers alerts at thresholds' do
      described_class.set_budget(entity_type: :worker, entity_id: 'w1', limit_usd: 100.0, period_key: '2026-03')
      result = described_class.record_spend(entity_type: :worker, entity_id: 'w1', period_key: '2026-03',
                                            amount_usd: 51.0)
      expect(result[:alerts].size).to eq(1)
      expect(result[:alerts].first[:threshold]).to eq(50)
    end

    it 'does not duplicate alerts' do
      described_class.set_budget(entity_type: :worker, entity_id: 'w1', limit_usd: 100.0, period_key: '2026-03')
      described_class.record_spend(entity_type: :worker, entity_id: 'w1', period_key: '2026-03', amount_usd: 51.0)
      result = described_class.record_spend(entity_type: :worker, entity_id: 'w1', period_key: '2026-03',
                                            amount_usd: 1.0)
      expect(result[:alerts]).to be_empty
    end

    it 'returns no_budget when untracked' do
      result = described_class.record_spend(entity_type: :worker, entity_id: 'unknown', period_key: '2026-03',
                                            amount_usd: 5.0)
      expect(result[:recorded]).to be false
      expect(result[:reason]).to eq(:no_budget)
    end
  end

  describe '.status' do
    it 'returns budget details' do
      described_class.set_budget(entity_type: :tenant, entity_id: 't1', limit_usd: 100.0, period_key: '2026-03')
      status = described_class.status(entity_type: :tenant, entity_id: 't1', period_key: '2026-03')
      expect(status[:limit_usd]).to eq(100.0)
      expect(status[:spent_usd]).to eq(0.0)
    end

    it 'returns nil for unknown budget' do
      status = described_class.status(entity_type: :tenant, entity_id: 'unknown', period_key: '2026-03')
      expect(status).to be_nil
    end
  end
end
