# frozen_string_literal: true

module Legion
  module Extensions
    module Empathy
      module Helpers
        class ModelStore
          attr_reader :models

          def initialize
            @models = {}
          end

          def get(agent_id)
            @models[agent_id.to_s]
          end

          def get_or_create(agent_id)
            key = agent_id.to_s
            @models[key] ||= MentalModel.new(agent_id: key)
          end

          def update(agent_id, observation)
            model = get_or_create(agent_id)
            model.update_from_observation(observation)
            evict_if_needed
            model
          end

          def predict(agent_id, scenario)
            model = get(agent_id)
            return nil unless model

            model.predict_reaction(scenario)
          end

          def decay_all
            count = 0
            @models.each_value do |model|
              model.decay
              count += 1
            end
            count
          end

          def remove_stale
            stale_keys = @models.select { |_, m| m.stale? && m.interaction_history.empty? }.keys
            stale_keys.each { |k| @models.delete(k) }
            stale_keys.size
          end

          def all_models
            @models.values
          end

          def by_cooperation(stance)
            @models.values.select { |m| m.cooperation_stance == stance }
          end

          def by_emotion(emotion)
            @models.values.select { |m| m.emotional_state == emotion }
          end

          def size
            @models.size
          end

          def clear
            @models.clear
          end

          private

          def evict_if_needed
            return unless @models.size > Constants::MAX_TRACKED_AGENTS

            oldest = @models.min_by { |_, m| m.updated_at }
            @models.delete(oldest[0]) if oldest
          end
        end
      end
    end
  end
end
