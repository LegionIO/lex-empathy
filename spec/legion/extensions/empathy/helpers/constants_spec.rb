# frozen_string_literal: true

RSpec.describe Legion::Extensions::Empathy::Helpers::Constants do
  it 'defines 5 mental state dimensions' do
    expect(described_class::MENTAL_STATE_DIMENSIONS.size).to eq(5)
  end

  it 'defines cooperation stances' do
    expect(described_class::COOPERATION_STANCES).to include(:cooperative, :competitive, :neutral, :unknown)
  end

  it 'defines inferred emotions' do
    expect(described_class::INFERRED_EMOTIONS).to include(:calm, :stressed, :curious, :unknown)
  end

  it 'defines prediction thresholds in order' do
    expect(described_class::PREDICTION_UNCERTAIN).to be < described_class::PREDICTION_CONFIDENT
  end

  it 'sets MAX_TRACKED_AGENTS to 100' do
    expect(described_class::MAX_TRACKED_AGENTS).to eq(100)
  end
end
