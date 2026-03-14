# lex-empathy

Theory of Mind engine for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models other agents' mental states — their beliefs, emotions, intentions, and cooperation stance. Enables prediction of how other agents will react to proposed actions, perspective-taking via narrative generation, and social climate assessment across the mesh. Updates mental models from observed behavior using exponential moving averages, so the model continuously improves as more observations arrive.

## Usage

```ruby
client = Legion::Extensions::Empathy::Client.new

# Observe another agent's behavior to build a mental model
client.observe_agent(
  agent_id: 'agent-b',
  observation: {
    goal: 'code_review',
    emotion: :focused,
    cooperation: :cooperative,
    evidence_strength: 0.8
  }
)

# Predict how they'll react to a proposed action
client.predict_reaction(
  agent_id: 'agent-b',
  scenario: { emotional_impact: :positive, impact_on_agent: :beneficial }
)
# => { likely_response: :likely_agree, confidence: 0.65, reasoning: '...' }

# Generate a perspective-taking narrative
client.perspective_take(agent_id: 'agent-b')
# => { narrative: "Agent agent-b appears to be pursuing code_review and seems focused...",
#      model_confidence: 0.72 }

# Survey cooperation across all tracked agents
client.social_landscape
# => { tracked_agents: 5, cooperative_count: 3, overall_climate: :harmonious, climate_label: :harmonious }

# Track prediction accuracy over time
client.update_prediction_accuracy(
  agent_id: 'agent-b',
  predicted: :likely_agree,
  actual: :likely_agree
)

# Periodic maintenance: decay stale models
client.update_empathy
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
