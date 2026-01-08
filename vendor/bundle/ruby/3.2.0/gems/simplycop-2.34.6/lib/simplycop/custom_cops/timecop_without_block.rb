# frozen_string_literal: true

module CustomCops
  class TimecopWithoutBlock < RuboCop::Cop::Base
    MSG = 'Avoid using `Timecop.%<method>s` without providing a block.'

    def_node_matcher :timecop_method, '(send (const nil? :Timecop) ${:travel :freeze} ...)'

    def on_send(node)
      timecop_method(node) do |method_name|
        return if !method_name || first_child_of_block?(node) || last_child_is_a_block?(node)

        add_offense(node.loc.selector, message: format(MSG, method: method_name))
      end
    end

    private

    # Checks if the given node's parent is a block, and the given node is its first child,
    # which would mean that the block is supplied to the given node (i.e `node { block }`)
    def first_child_of_block?(node)
      return false unless (parent = node.parent)

      return false unless parent.type == :block

      parent.children.first == node
    end

    # Checks whether the last child of the given node is a block.
    # this denotes the following structure:
    # `Timecop.method(arg1, arg2, &block)`, which is also a valid way of passing in a block
    def last_child_is_a_block?(node)
      return false unless node.children.last.respond_to?(:type)

      node.children.last.type == :block_pass
    end
  end
end
