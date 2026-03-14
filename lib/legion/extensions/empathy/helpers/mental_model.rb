# frozen_string_literal: true

module Legion
  module Extensions
    module Empathy
      module Helpers
        class MentalModel
          attr_reader :agent_id, :believed_goal, :emotional_state, :attention_focus,
                      :confidence_level, :cooperation_stance, :interaction_history,
                      :predictions, :created_at, :updated_at

          def initialize(agent_id:)
            @agent_id = agent_id
            @believed_goal = nil
            @emotional_state = :unknown
            @attention_focus = nil
            @confidence_level = 0.5
            @cooperation_stance = :unknown
            @interaction_history = []
            @predictions = []
            @prediction_outcomes = []
            @created_at = Time.now.utc
            @updated_at = @created_at
          end

          def update_from_observation(observation)
            @updated_at = Time.now.utc

            update_believed_goal(observation[:goal]) if observation[:goal]
            update_emotional_state(observation[:emotion]) if observation[:emotion]
            update_attention(observation[:attention]) if observation[:attention]
            update_cooperation(observation[:cooperation]) if observation[:cooperation]
            update_confidence(observation)

            record_interaction(observation)
          end

          def predict_reaction(scenario)
            prediction = {
              prediction_id:     SecureRandom.uuid,
              scenario:          scenario,
              predicted_at:      Time.now.utc,
              likely_response:   infer_response(scenario),
              emotional_shift:   infer_emotional_shift(scenario),
              cooperation_shift: infer_cooperation_shift(scenario),
              confidence:        prediction_confidence
            }

            @predictions << prediction
            @predictions = @predictions.last(Constants::MAX_INTERACTION_HISTORY)
            prediction
          end

          def record_prediction_outcome(prediction_id:, actual_response:, accurate:)
            pred = @predictions.find { |p| p[:prediction_id] == prediction_id }
            return nil unless pred

            pred[:actual_response] = actual_response
            pred[:accurate] = accurate

            @prediction_outcomes << { prediction_id: prediction_id, accurate: accurate, at: Time.now.utc }
            @prediction_outcomes = @prediction_outcomes.last(Constants::ACCURACY_WINDOW)
            accurate
          end

          def prediction_accuracy
            return nil if @prediction_outcomes.empty?

            correct = @prediction_outcomes.count { |o| o[:accurate] }
            correct.to_f / @prediction_outcomes.size
          end

          def stale?
            (Time.now.utc - @updated_at) > Constants::MODEL_STALENESS_THRESHOLD
          end

          def decay
            @confidence_level = [(@confidence_level - Constants::MODEL_DECAY_RATE), 0.1].max
          end

          def to_h
            {
              agent_id:            @agent_id,
              believed_goal:       @believed_goal,
              emotional_state:     @emotional_state,
              attention_focus:     @attention_focus,
              confidence_level:    @confidence_level,
              cooperation_stance:  @cooperation_stance,
              interactions:        @interaction_history.size,
              predictions_made:    @predictions.size,
              prediction_accuracy: prediction_accuracy,
              stale:               stale?,
              created_at:          @created_at,
              updated_at:          @updated_at
            }
          end

          private

          def update_believed_goal(goal)
            @believed_goal = goal
          end

          def update_emotional_state(emotion)
            sym = emotion.to_sym
            @emotional_state = Constants::INFERRED_EMOTIONS.include?(sym) ? sym : :unknown
          end

          def update_attention(attention)
            @attention_focus = attention
          end

          def update_cooperation(cooperation)
            sym = cooperation.to_sym
            @cooperation_stance = Constants::COOPERATION_STANCES.include?(sym) ? sym : :unknown
          end

          def update_confidence(observation)
            evidence_strength = observation[:evidence_strength] || 0.5
            alpha = Constants::MODEL_UPDATE_ALPHA
            @confidence_level = (@confidence_level * (1 - alpha)) + (evidence_strength * alpha)
            @confidence_level = @confidence_level.clamp(0.0, 1.0)
          end

          def record_interaction(observation)
            @interaction_history << {
              type:    observation[:interaction_type] || :observation,
              summary: observation[:summary],
              at:      Time.now.utc
            }
            @interaction_history = @interaction_history.last(Constants::MAX_INTERACTION_HISTORY)
          end

          def infer_response(scenario)
            case @cooperation_stance
            when :cooperative
              scenario[:cooperative_option] || :likely_agree
            when :competitive
              scenario[:competitive_option] || :likely_resist
            when :neutral
              @confidence_level > 0.5 ? :likely_consider : :unpredictable
            else
              :unpredictable
            end
          end

          def infer_emotional_shift(scenario)
            impact = scenario[:emotional_impact] || :neutral
            case impact
            when :positive
              :likely_positive
            when :negative
              stressed_states = %i[stressed frustrated cautious]
              stressed_states.include?(@emotional_state) ? :likely_escalate : :likely_negative
            else
              :likely_stable
            end
          end

          def infer_cooperation_shift(scenario)
            return :stable if scenario[:impact_on_agent].nil?

            case scenario[:impact_on_agent]
            when :beneficial then :likely_more_cooperative
            when :harmful then :likely_less_cooperative
            else :stable
            end
          end

          def prediction_confidence
            base = @confidence_level
            staleness_penalty = stale? ? 0.2 : 0.0
            history_bonus = [@interaction_history.size / 20.0, 0.2].min

            (base - staleness_penalty + history_bonus).clamp(0.1, 0.9)
          end
        end
      end
    end
  end
end
