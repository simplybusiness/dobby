# frozen_string_literal: true

module CustomCops
  #  This cop checks for usages of `instance_eval`
  #
  # @example
  #   #bad
  #   class Person
  #   end
  #
  #   Person.instance_eval do
  #     def human?
  #       true
  #     end
  #   end
  #
  #   #good
  #   class Person
  #     def self.human?
  #       true
  #     end
  #   end
  #
  class InstanceEval < RuboCop::Cop::Base
    MSG = 'Avoid instance_eval.'

    def_node_matcher :instance_evaling?, '(send _ :instance_eval ...)'

    def on_send(node)
      return unless instance_evaling?(node)

      add_offense(node.loc.selector)
    end
  end
end
