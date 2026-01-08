# frozen_string_literal: true

module CustomCops
  #  This cop checks for the presence of dynamically generated constants
  #
  # @example
  #   #bad
  #   "FOO_BAR".constantize
  #
  #   #good
  #   FOO_BAR
  #
  class Constantize < RuboCop::Cop::Base
    MSG = 'Avoid dynamically creating constants.'

    def_node_matcher :constantizing?, '(send ... :constantize)'

    def on_send(node)
      return unless constantizing?(node)

      add_offense(node.loc.selector)
    end
  end
end
