# frozen_string_literal: true

module CustomCops
  #  This cop checks for dynamically defining methods
  #
  # @example
  #   #bad
  #   Foo.define_method(:bar) { p 'bar }
  #
  #   #good
  #   #create the method on the object
  #   class Foo
  #      def self.bar
  #        puts 'bar'
  #      end
  #   end
  #
  class DefineMethod < RuboCop::Cop::Base
    MSG = 'Avoid define_method.'

    def_node_matcher :defining_method?, '(send _ :define_method ...)'

    def on_send(node)
      return unless defining_method?(node)

      add_offense(node.loc.selector)
    end
  end
end
