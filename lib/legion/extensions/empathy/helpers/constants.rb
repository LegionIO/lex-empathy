# frozen_string_literal: true

module Legion
  module Extensions
    module Empathy
      module Helpers
        module Constants
          # Mental state dimensions tracked per agent
          MENTAL_STATE_DIMENSIONS = %i[
            believed_goal
            emotional_state
            attention_focus
            confidence_level
            cooperation_stance
          ].freeze

          # How quickly mental models update (EMA alpha)
          MODEL_UPDATE_ALPHA = 0.2

          # How long before a mental model is considered stale (seconds)
          MODEL_STALENESS_THRESHOLD = 300

          # Maximum number of tracked agents
          MAX_TRACKED_AGENTS = 100

          # Maximum interaction history per agent
          MAX_INTERACTION_HISTORY = 50

          # Prediction confidence thresholds
          PREDICTION_CONFIDENT   = 0.7
          PREDICTION_UNCERTAIN   = 0.4

          # Cooperation stance values
          COOPERATION_STANCES = %i[cooperative neutral competitive unknown].freeze

          # Emotional state labels for other agents
          INFERRED_EMOTIONS = %i[
            calm focused stressed frustrated curious cautious enthusiastic unknown
          ].freeze

          # Perspective-taking accuracy tracking window
          ACCURACY_WINDOW = 20

          # Mental model decay rate (per decay cycle)
          MODEL_DECAY_RATE = 0.01
        end
      end
    end
  end
end
