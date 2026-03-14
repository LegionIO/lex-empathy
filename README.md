# lex-empathy

Theory of Mind engine for the LegionIO brain-modeled agentic architecture.

Models other agents' mental states — their beliefs, emotions, intentions, and cooperation stance. Enables prediction of how other agents will react to proposed actions, perspective-taking, and social climate assessment across the mesh.

## Key Concepts

- **Mental Models**: Per-agent representations tracking believed goal, emotional state, attention focus, confidence, and cooperation stance
- **Observation Learning**: Models update from observed behavior via EMA-weighted evidence
- **Reaction Prediction**: Given a scenario, predict how an agent will respond based on their mental model
- **Perspective Taking**: Generate narrative descriptions of what another agent is likely experiencing
- **Social Landscape**: Aggregate view of cooperation stances and emotional climate across all tracked agents
- **Prediction Accuracy**: Track and report how well predictions match actual outcomes

## Usage

```ruby
client = Legion::Extensions::Empathy::Client.new

# Observe another agent's behavior
client.observe_agent(agent_id: 'agent-b', observation: {
  goal: 'code_review', emotion: :focused, cooperation: :cooperative,
  evidence_strength: 0.8
})

# Predict how they'll react to a proposal
prediction = client.predict_reaction(agent_id: 'agent-b', scenario: {
  emotional_impact: :positive, impact_on_agent: :beneficial
})
# => { likely_response: :likely_agree, confidence: 0.65, ... }

# Get a narrative perspective
client.perspective_take(agent_id: 'agent-b')
# => { narrative: "Agent agent-b appears to be pursuing code_review and seems focused..." }

# Survey the social landscape
client.social_landscape
# => { tracked_agents: 5, cooperative_count: 3, overall_climate: :harmonious, ... }
```

## License

MIT
