# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Finops::Helpers::CostCalculator do
  before do
    Legion::Settings.reset!
  end

  describe '.estimate_cost' do
    it 'calculates cost from token counts' do
      cost = described_class.estimate_cost(
        provider: :bedrock, model: 'claude', input_tokens: 1000, output_tokens: 500
      )
      expect(cost).to be > 0
    end

    it 'includes thinking tokens' do
      base = described_class.estimate_cost(
        provider: :bedrock, model: 'x', input_tokens: 1000, output_tokens: 500
      )
      with_thinking = described_class.estimate_cost(
        provider: :bedrock, model: 'x', input_tokens: 1000, output_tokens: 500, thinking_tokens: 200
      )
      expect(with_thinking).to be > base
    end

    it 'returns zero for zero tokens' do
      cost = described_class.estimate_cost(
        provider: :bedrock, model: 'claude', input_tokens: 0, output_tokens: 0
      )
      expect(cost).to eq(0.0)
    end
  end

  describe '.pricing_for' do
    it 'returns default rates when no custom pricing' do
      rates = described_class.pricing_for(:bedrock, 'claude-sonnet-4-6')
      expect(rates).to eq(described_class::DEFAULT_RATES)
    end

    it 'uses custom provider pricing when configured' do
      Legion::Settings[:finops] = {
        pricing: { bedrock: { default: { input_per_1k: 0.01, output_per_1k: 0.03, thinking_per_1k: 0.01 } } }
      }
      rates = described_class.pricing_for(:bedrock, 'some-model')
      expect(rates[:input_per_1k]).to eq(0.01)
    end
  end
end
