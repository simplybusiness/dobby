# frozen_string_literal: true

module CustomCops
  #  This cop checks for the presence of Mongoid indexes that have not been
  #  flagged with the flag `background: true`.
  #
  # @example
  #   #bad
  #   index(reference: 1)
  #
  #   #good
  #   index({ reference: 1 }, { background: true })
  #
  class NoForegroundIndices < RuboCop::Cop::Base
    MSG = 'Do not create indices that lack the background flag.'

    def_node_matcher :model_index?, <<~PATTERN
      (send nil? :index $...)
    PATTERN

    def_node_matcher :hash?, <<~PATTERN
      (hash $...)
    PATTERN

    def_node_matcher :background_pair?, <<~PATTERN
      (pair
        (sym :background)
        (:true)
      )
    PATTERN

    def on_send(node)
      model_index?(node) do |_fields, options|
        add_offense(node.loc.selector) unless background_enabled?(options)
      end
    end

    private

    def background_enabled?(hash)
      return false if hash.nil? || !hash?(hash)

      hash.pairs.any? { |pair| background_pair?(pair) }
    end
  end
end
