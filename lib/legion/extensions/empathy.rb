# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/empathy/version'
require 'legion/extensions/empathy/helpers/constants'
require 'legion/extensions/empathy/helpers/mental_model'
require 'legion/extensions/empathy/helpers/model_store'
require 'legion/extensions/empathy/runners/empathy'
require 'legion/extensions/empathy/client'

module Legion
  module Extensions
    module Empathy
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
