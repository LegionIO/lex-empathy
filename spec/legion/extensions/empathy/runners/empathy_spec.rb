# frozen_string_literal: true

RSpec.describe Legion::Extensions::Empathy::Runners::Empathy do
  let(:client) { Legion::Extensions::Empathy::Client.new }

  describe '#observe_agent' do
    it 'creates a mental model from observation' do
      result = client.observe_agent(agent_id: 'agent-b', observation: {
                                      goal: 'testing', emotion: :focused, cooperation: :cooperative, evidence_strength: 0.8
                                    })
      expect(result[:emotional_state]).to eq(:focused)
      expect(result[:cooperation_stance]).to eq(:cooperative)
      expect(result[:believed_goal]).to eq('testing')
    end

    it 'updates existing models' do
      client.observe_agent(agent_id: 'agent-b', observation: { emotion: :calm })
      result = client.observe_agent(agent_id: 'agent-b', observation: { emotion: :stressed })
      expect(result[:emotional_state]).to eq(:stressed)
    end
  end

  describe '#predict_reaction' do
    before do
      client.observe_agent(agent_id: 'agent-b', observation: {
                             cooperation: :cooperative, emotion: :calm
                           })
    end

    it 'returns prediction for known agent' do
      result = client.predict_reaction(agent_id: 'agent-b', scenario: {
                                         emotional_impact: :positive, impact_on_agent: :beneficial
                                       })
      expect(result).to have_key(:likely_response)
      expect(result).to have_key(:confidence)
    end

    it 'returns error for unknown agent' do
      result = client.predict_reaction(agent_id: 'nobody', scenario: {})
      expect(result[:error]).to eq(:no_model)
    end
  end

  describe '#record_outcome' do
    it 'records prediction outcome' do
      client.observe_agent(agent_id: 'agent-b', observation: { cooperation: :cooperative })
      prediction = client.predict_reaction(agent_id: 'agent-b', scenario: {})
      result = client.record_outcome(
        agent_id:        'agent-b',
        prediction_id:   prediction[:prediction_id],
        actual_response: :agreed,
        accurate:        true
      )
      expect(result[:accurate]).to be true
      expect(result[:current_accuracy]).to eq(1.0)
    end

    it 'returns error for unknown agent' do
      result = client.record_outcome(agent_id: 'nobody', prediction_id: 'x',
                                     actual_response: :ok, accurate: true)
      expect(result[:error]).to eq(:no_model)
    end

    it 'returns error for unknown prediction' do
      client.observe_agent(agent_id: 'agent-b', observation: {})
      result = client.record_outcome(agent_id: 'agent-b', prediction_id: 'nonexistent',
                                     actual_response: :ok, accurate: true)
      expect(result[:error]).to eq(:prediction_not_found)
    end
  end

  describe '#perspective_take' do
    it 'generates narrative for known agent' do
      client.observe_agent(agent_id: 'agent-b', observation: {
                             goal: 'code_review', emotion: :focused, cooperation: :cooperative
                           })
      result = client.perspective_take(agent_id: 'agent-b')
      expect(result[:narrative]).to include('agent-b')
      expect(result[:narrative]).to include('code_review')
    end

    it 'returns error for unknown agent' do
      result = client.perspective_take(agent_id: 'nobody')
      expect(result[:error]).to eq(:no_model)
    end
  end

  describe '#social_landscape' do
    before do
      client.observe_agent(agent_id: 'a', observation: { cooperation: :cooperative, emotion: :calm })
      client.observe_agent(agent_id: 'b', observation: { cooperation: :cooperative, emotion: :focused })
      client.observe_agent(agent_id: 'c', observation: { cooperation: :competitive, emotion: :stressed })
    end

    it 'returns social climate assessment' do
      result = client.social_landscape
      expect(result[:tracked_agents]).to eq(3)
      expect(result[:cooperative_count]).to eq(2)
      expect(result[:competitive_count]).to eq(1)
      expect(result).to have_key(:overall_climate)
    end

    it 'assesses harmonious climate when mostly cooperative' do
      client.observe_agent(agent_id: 'd', observation: { cooperation: :cooperative })
      result = client.social_landscape
      expect(result[:overall_climate]).to eq(:harmonious)
    end
  end

  describe '#decay_models' do
    it 'decays all models' do
      client.observe_agent(agent_id: 'a', observation: {})
      result = client.decay_models
      expect(result[:decayed]).to eq(1)
    end
  end

  describe '#empathy_stats' do
    it 'returns summary statistics' do
      client.observe_agent(agent_id: 'a', observation: { cooperation: :cooperative })
      client.predict_reaction(agent_id: 'a', scenario: {})
      result = client.empathy_stats
      expect(result[:tracked_agents]).to eq(1)
      expect(result[:total_predictions]).to eq(1)
    end
  end
end
