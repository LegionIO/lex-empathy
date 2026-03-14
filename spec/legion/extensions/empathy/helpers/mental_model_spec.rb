# frozen_string_literal: true

RSpec.describe Legion::Extensions::Empathy::Helpers::MentalModel do
  subject(:model) { described_class.new(agent_id: 'agent-42') }

  describe '#initialize' do
    it 'sets agent_id' do
      expect(model.agent_id).to eq('agent-42')
    end

    it 'starts with unknown emotional state' do
      expect(model.emotional_state).to eq(:unknown)
    end

    it 'starts with unknown cooperation stance' do
      expect(model.cooperation_stance).to eq(:unknown)
    end

    it 'starts with 0.5 confidence' do
      expect(model.confidence_level).to eq(0.5)
    end
  end

  describe '#update_from_observation' do
    it 'updates believed goal' do
      model.update_from_observation(goal: 'code_review')
      expect(model.believed_goal).to eq('code_review')
    end

    it 'updates emotional state' do
      model.update_from_observation(emotion: :focused)
      expect(model.emotional_state).to eq(:focused)
    end

    it 'updates cooperation stance' do
      model.update_from_observation(cooperation: :cooperative)
      expect(model.cooperation_stance).to eq(:cooperative)
    end

    it 'records interaction history' do
      model.update_from_observation(summary: 'sent a message')
      expect(model.interaction_history.size).to eq(1)
    end

    it 'rejects unknown emotions as :unknown' do
      model.update_from_observation(emotion: :nonexistent)
      expect(model.emotional_state).to eq(:unknown)
    end

    it 'updates confidence via EMA' do
      model.update_from_observation(evidence_strength: 0.9)
      expect(model.confidence_level).to be > 0.5
    end
  end

  describe '#predict_reaction' do
    before do
      model.update_from_observation(cooperation: :cooperative, emotion: :calm)
    end

    it 'returns a prediction hash' do
      prediction = model.predict_reaction(emotional_impact: :positive)
      expect(prediction).to have_key(:prediction_id)
      expect(prediction).to have_key(:likely_response)
      expect(prediction).to have_key(:confidence)
    end

    it 'predicts cooperative agents will likely agree' do
      prediction = model.predict_reaction(cooperative_option: :accept)
      expect(prediction[:likely_response]).to eq(:accept)
    end

    it 'stores predictions' do
      model.predict_reaction({})
      expect(model.predictions.size).to eq(1)
    end
  end

  describe '#record_prediction_outcome' do
    it 'records accurate prediction' do
      prediction = model.predict_reaction({})
      result = model.record_prediction_outcome(
        prediction_id:   prediction[:prediction_id],
        actual_response: :agreed,
        accurate:        true
      )
      expect(result).to be true
    end

    it 'returns nil for unknown prediction' do
      result = model.record_prediction_outcome(
        prediction_id:   'nonexistent',
        actual_response: :agreed,
        accurate:        true
      )
      expect(result).to be_nil
    end
  end

  describe '#prediction_accuracy' do
    it 'returns nil with no outcomes' do
      expect(model.prediction_accuracy).to be_nil
    end

    it 'computes accuracy from outcomes' do
      3.times do
        pred = model.predict_reaction({})
        model.record_prediction_outcome(prediction_id: pred[:prediction_id],
                                        actual_response: :ok, accurate: true)
      end
      pred = model.predict_reaction({})
      model.record_prediction_outcome(prediction_id: pred[:prediction_id],
                                      actual_response: :nope, accurate: false)

      expect(model.prediction_accuracy).to eq(0.75)
    end
  end

  describe '#stale?' do
    it 'returns false when fresh' do
      expect(model.stale?).to be false
    end

    it 'returns true when old' do
      model.instance_variable_set(:@updated_at, Time.now.utc - 400)
      expect(model.stale?).to be true
    end
  end

  describe '#decay' do
    it 'reduces confidence' do
      original = model.confidence_level
      model.decay
      expect(model.confidence_level).to be < original
    end

    it 'floors confidence at 0.1' do
      50.times { model.decay }
      expect(model.confidence_level).to be >= 0.1
    end
  end

  describe '#to_h' do
    it 'returns a complete state hash' do
      h = model.to_h
      expect(h).to include(:agent_id, :believed_goal, :emotional_state,
                           :cooperation_stance, :confidence_level, :stale)
    end
  end
end
