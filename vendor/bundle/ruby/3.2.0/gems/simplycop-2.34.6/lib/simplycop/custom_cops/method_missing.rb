# frozen_string_literal: true

module CustomCops
  #  This cop checks for the presence of `method_missing`
  #
  # @example
  #   #bad
  #   def method_missing
  #   end
  #
  #   #good
  #
  #   not using method missing
  #
  class MethodMissing < RuboCop::Cop::Base
    MSG = 'Avoid method missing.'

    def on_def(node)
      return unless node.method?(:method_missing)

      add_offense(node)
    end
    alias on_defs on_def
  end
end
