# frozen_string_literal: true

module Legion
  module Extensions
    module Empathy
      module Runners
        module Empathy
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def observe_agent(agent_id:, observation: {}, **)
            model = model_store.update(agent_id, observation)
            Legion::Logging.debug "[empathy] observed: agent=#{agent_id} emotion=#{model.emotional_state} " \
                                  "cooperation=#{model.cooperation_stance}"

            {
              agent_id:           agent_id,
              emotional_state:    model.emotional_state,
              cooperation_stance: model.cooperation_stance,
              believed_goal:      model.believed_goal,
              confidence:         model.confidence_level
            }
          end

          def predict_reaction(agent_id:, scenario: {}, **)
            prediction = model_store.predict(agent_id, scenario)

            if prediction
              Legion::Logging.debug "[empathy] prediction: agent=#{agent_id} response=#{prediction[:likely_response]} " \
                                    "confidence=#{prediction[:confidence].round(2)}"
              prediction
            else
              Legion::Logging.debug "[empathy] no model for agent=#{agent_id}"
              { error: :no_model, agent_id: agent_id }
            end
          end

          def record_outcome(agent_id:, prediction_id:, actual_response:, accurate:, **)
            model = model_store.get(agent_id)
            return { error: :no_model } unless model

            result = model.record_prediction_outcome(
              prediction_id:   prediction_id,
              actual_response: actual_response,
              accurate:        accurate
            )

            if result.nil?
              { error: :prediction_not_found }
            else
              Legion::Logging.info "[empathy] outcome recorded: agent=#{agent_id} accurate=#{accurate} " \
                                   "accuracy=#{model.prediction_accuracy&.round(2)}"
              { agent_id: agent_id, accurate: accurate, current_accuracy: model.prediction_accuracy }
            end
          end

          def perspective_take(agent_id:, **)
            model = model_store.get(agent_id)
            return { error: :no_model, agent_id: agent_id } unless model

            narrative = build_perspective_narrative(model)
            Legion::Logging.debug "[empathy] perspective: agent=#{agent_id}"

            {
              agent_id:  agent_id,
              narrative: narrative,
              model:     model.to_h
            }
          end

          def social_landscape(**)
            models = model_store.all_models
            cooperative = model_store.by_cooperation(:cooperative).size
            competitive = model_store.by_cooperation(:competitive).size
            stressed = model_store.by_emotion(:stressed).size + model_store.by_emotion(:frustrated).size

            Legion::Logging.debug "[empathy] landscape: agents=#{models.size} cooperative=#{cooperative} " \
                                  "competitive=#{competitive} stressed=#{stressed}"

            {
              tracked_agents:    models.size,
              cooperative_count: cooperative,
              competitive_count: competitive,
              stressed_count:    stressed,
              stances:           stance_distribution(models),
              emotions:          emotion_distribution(models),
              overall_climate:   assess_climate(cooperative, competitive, stressed, models.size)
            }
          end

          def decay_models(**)
            decayed = model_store.decay_all
            removed = model_store.remove_stale
            Legion::Logging.debug "[empathy] decay: updated=#{decayed} stale_removed=#{removed}"
            { decayed: decayed, stale_removed: removed }
          end

          def empathy_stats(**)
            models = model_store.all_models
            accuracies = models.filter_map(&:prediction_accuracy)

            {
              tracked_agents:      model_store.size,
              total_predictions:   models.sum { |m| m.predictions.size },
              avg_accuracy:        accuracies.empty? ? nil : (accuracies.sum / accuracies.size).round(3),
              stale_models:        models.count(&:stale?),
              cooperation_stances: stance_distribution(models)
            }
          end

          private

          def model_store
            @model_store ||= Helpers::ModelStore.new
          end

          def build_perspective_narrative(model)
            parts = []
            parts << "Agent #{model.agent_id}"

            parts << if model.believed_goal
                       "appears to be pursuing #{model.believed_goal}"
                     else
                       'has no clearly observed goal'
                     end

            parts << "and seems #{model.emotional_state}" unless model.emotional_state == :unknown
            parts << "with a #{model.cooperation_stance} stance" unless model.cooperation_stance == :unknown

            parts << "(model is stale — last updated #{((Time.now.utc - model.updated_at) / 60).round(1)} minutes ago)" if model.stale?

            parts << "— prediction accuracy: #{(model.prediction_accuracy * 100).round(1)}%" if model.prediction_accuracy

            parts.join(' ')
          end

          def stance_distribution(models)
            dist = Hash.new(0)
            models.each { |m| dist[m.cooperation_stance] += 1 }
            dist
          end

          def emotion_distribution(models)
            dist = Hash.new(0)
            models.each { |m| dist[m.emotional_state] += 1 }
            dist
          end

          def assess_climate(cooperative, competitive, stressed, total)
            return :empty if total.zero?

            coop_ratio = cooperative.to_f / total
            stress_ratio = stressed.to_f / total

            if coop_ratio > 0.6
              :harmonious
            elsif stress_ratio > 0.4
              :tense
            elsif competitive > cooperative
              :adversarial
            else
              :neutral
            end
          end
        end
      end
    end
  end
end
