# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Finops::Runners::CostAttribution do
  let(:host) { Object.new.extend(described_class) }

  describe '#attribute_cost' do
    it 'calculates cost and returns attribution record' do
      record = host.attribute_cost(
        worker_id: 'w1', tenant_id: 't1', provider: :bedrock, model: 'claude',
        input_tokens: 1000, output_tokens: 500
      )
      expect(record[:cost_usd]).to be > 0
      expect(record[:worker_id]).to eq('w1')
      expect(record[:tenant_id]).to eq('t1')
      expect(record[:attributed_at]).not_to be_nil
    end

    it 'includes thinking tokens in cost' do
      base = host.attribute_cost(
        worker_id: 'w1', provider: :bedrock, model: 'claude',
        input_tokens: 1000, output_tokens: 500
      )
      with_thinking = host.attribute_cost(
        worker_id: 'w1', provider: :bedrock, model: 'claude',
        input_tokens: 1000, output_tokens: 500, thinking_tokens: 200
      )
      expect(with_thinking[:cost_usd]).to be > base[:cost_usd]
    end
  end

  describe '#cost_summary' do
    it 'returns summary placeholder' do
      result = host.cost_summary(group_by: :worker_id)
      expect(result[:group_by]).to eq(:worker_id)
    end
  end
end
