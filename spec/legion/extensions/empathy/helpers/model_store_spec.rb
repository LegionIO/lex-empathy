# frozen_string_literal: true

RSpec.describe Legion::Extensions::Empathy::Helpers::ModelStore do
  subject(:store) { described_class.new }

  describe '#get_or_create' do
    it 'creates a new model for unknown agent' do
      model = store.get_or_create('agent-1')
      expect(model.agent_id).to eq('agent-1')
    end

    it 'returns existing model' do
      m1 = store.get_or_create('agent-1')
      m2 = store.get_or_create('agent-1')
      expect(m1).to equal(m2)
    end
  end

  describe '#update' do
    it 'updates model with observation' do
      model = store.update('agent-1', emotion: :focused, cooperation: :cooperative)
      expect(model.emotional_state).to eq(:focused)
    end

    it 'increments store size' do
      store.update('agent-1', {})
      store.update('agent-2', {})
      expect(store.size).to eq(2)
    end
  end

  describe '#predict' do
    it 'returns nil for unknown agent' do
      expect(store.predict('nobody', {})).to be_nil
    end

    it 'returns prediction for known agent' do
      store.update('agent-1', cooperation: :cooperative)
      prediction = store.predict('agent-1', {})
      expect(prediction).to have_key(:likely_response)
    end
  end

  describe '#decay_all' do
    it 'decays all models' do
      store.update('agent-1', {})
      store.update('agent-2', {})
      count = store.decay_all
      expect(count).to eq(2)
    end
  end

  describe '#remove_stale' do
    it 'removes stale models with no interactions' do
      store.get_or_create('agent-old')
      store.models['agent-old'].instance_variable_set(:@updated_at, Time.now.utc - 400)
      removed = store.remove_stale
      expect(removed).to eq(1)
      expect(store.size).to eq(0)
    end

    it 'keeps stale models that have interactions' do
      store.update('agent-old', summary: 'did something')
      store.models['agent-old'].instance_variable_set(:@updated_at, Time.now.utc - 400)
      removed = store.remove_stale
      expect(removed).to eq(0)
    end
  end

  describe '#by_cooperation' do
    it 'filters by cooperation stance' do
      store.update('a', cooperation: :cooperative)
      store.update('b', cooperation: :competitive)
      store.update('c', cooperation: :cooperative)
      expect(store.by_cooperation(:cooperative).size).to eq(2)
    end
  end

  describe '#by_emotion' do
    it 'filters by emotional state' do
      store.update('a', emotion: :stressed)
      store.update('b', emotion: :calm)
      expect(store.by_emotion(:stressed).size).to eq(1)
    end
  end

  describe '#clear' do
    it 'removes all models' do
      store.update('a', {})
      store.clear
      expect(store.size).to eq(0)
    end
  end
end
