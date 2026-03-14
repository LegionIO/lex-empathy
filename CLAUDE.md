# lex-empathy

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Theory of Mind (ToM) engine for the LegionIO cognitive architecture. Models other agents' mental states — their beliefs, emotions, intentions, and cooperation stance. Enables prediction of how other agents will react to proposed actions, perspective-taking via narrative generation, and social climate assessment across the mesh. Updates mental models from observed behavior via EMA-weighted evidence.

## Gem Info

- **Gem name**: `lex-empathy`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Empathy`
- **Location**: `extensions-agentic/lex-empathy/`

## File Structure

```
lib/legion/extensions/empathy/
  empathy.rb                    # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # COOPERATION_STANCES, EMOTIONAL_STATES, REACTION_TYPES, EMA_ALPHA, labels
    mental_model.rb             # MentalModel value object per tracked agent
    empathy_engine.rb           # Engine: model registry, observation, prediction, climate
  runners/
    empathy.rb                  # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `EMA_ALPHA` | 0.3 | Smoothing factor for model updates from observations |
| `COOPERATION_STANCES` | `[:cooperative, :neutral, :competitive, :hostile]` | Valid stance values |
| `EMOTIONAL_STATES` | `[:calm, :focused, :stressed, :excited, :frustrated, :satisfied]` | Valid emotional states |
| `REACTION_TYPES` | `[:likely_agree, :likely_resist, :uncertain, :likely_ignore]` | Prediction output types |
| `PREDICTION_CONFIDENCE_BASE` | 0.5 | Starting confidence before model adjustments |
| `MAX_MENTAL_MODELS` | 50 | Agent model registry cap |
| `MAX_OBSERVATIONS` | 500 | Rolling observation log cap |
| `COOPERATION_WEIGHT` | 0.4 | Weight of cooperation stance in reaction prediction |
| `EMOTION_WEIGHT` | 0.3 | Weight of emotional state in reaction prediction |
| `CLIMATE_LABELS` | hash | `harmonious / cooperative / mixed / tense / hostile` based on cooperative ratio |

## Runners

All methods in `Legion::Extensions::Empathy::Runners::Empathy`.

| Method | Key Args | Returns |
|---|---|---|
| `observe_agent` | `agent_id:, observation: {}` | `{ success:, agent_id:, model_updated:, cooperation:, emotion: }` |
| `predict_reaction` | `agent_id:, scenario: {}` | `{ success:, agent_id:, likely_response:, confidence:, reasoning: }` |
| `perspective_take` | `agent_id:` | `{ success:, agent_id:, narrative:, model_confidence: }` |
| `social_landscape` | — | `{ success:, tracked_agents:, cooperative_count:, overall_climate:, climate_label: }` |
| `mental_model_for` | `agent_id:` | `{ success:, agent_id:, goal:, emotion:, cooperation:, attention:, confidence: }` |
| `update_prediction_accuracy` | `agent_id:, predicted:, actual:` | `{ success:, accurate:, agent_id:, accuracy_rate: }` |
| `most_cooperative_agents` | `limit: 5` | `{ success:, agents:, count: }` |
| `update_empathy` | — | `{ success:, models_decayed:, observations_pruned: }` |
| `empathy_stats` | — | Full stats hash including prediction accuracy, climate breakdown |

## Helpers

### `MentalModel`
Per-agent state object. Attributes: `id` (agent_id), `goal`, `emotion`, `cooperation`, `attention`, `confidence` (EMA-updated), `prediction_count`, `accurate_prediction_count`, `created_at`, `last_updated_at`. Key methods: `update_from_observation(observation:)` (EMA update on all dimensions), `prediction_accuracy` (accurate / prediction_count), `to_h`.

### `EmpathyEngine`
Central store: `@models` (hash by agent_id), `@observations` (array, rolling). Key methods:
- `observe(agent_id:, observation:)`: finds or creates MentalModel, calls `model.update_from_observation`, logs observation
- `predict(agent_id:, scenario:)`: retrieves model, computes cooperation score + emotional alignment score, sums with weights, maps to `REACTION_TYPES` bucket, sets confidence
- `take_perspective(agent_id:)`: generates narrative string from model attributes
- `landscape`: iterates all models, computes cooperative ratio, maps to `CLIMATE_LABELS`
- `decay_models`: reduces confidence on models with no recent observations
- `cooperative_agents(limit:)`: sorts models by cooperation stance, returns top N

## Integration Points

- `observe_agent` called from lex-mesh message receipt — extract sender's behavior cues
- `predict_reaction` informs lex-swarm role assignment (route tasks to cooperative agents)
- `social_landscape[:overall_climate]` feeds lex-emotion as social valence signal
- `perspective_take` outputs feed lex-dream's social replay phase
- `update_empathy` maps to lex-tick's periodic maintenance cycle

## Development Notes

- Observation evidence_strength scales the EMA update: low-strength observations have smaller effect
- Reaction prediction is score-based: total score > 0.5 = agree, < -0.5 = resist, negative impact scenario shifts toward resist
- Narrative generation is template-based from model attributes, not LLM-generated
- Model confidence decays when no recent observations exist (passive forgetting)
- `update_prediction_accuracy` must be called by callers after observing actual outcomes — engine does not auto-track
