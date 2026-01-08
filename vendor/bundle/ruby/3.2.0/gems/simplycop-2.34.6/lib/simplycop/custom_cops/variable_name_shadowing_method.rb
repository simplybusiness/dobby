# frozen_string_literal: true

module CustomCops
  class VariableNameShadowingMethod < RuboCop::Cop::Base
    # For each source file, Rubocop calls on_new_investigation, then walks the abstract syntax
    # tree calling on_foo methods for each "foo" AST node - e.g on_begin, on_def, on_args,
    # on_int, etc.

    # We need to do two passes over the source so that we can find all the method names before
    # we start looking at the nodes that assign local variables (some methods may be defined
    # _after_ code that assigns shadowing local variables. We do the first one in
    # on_new_investigation

    def_node_search :method_names, <<~PATTERN
      (:def $_ ...)
    PATTERN

    def on_new_investigation
      ast = processed_source.ast
      @declared_method_names = ast ? method_names(processed_source.ast).to_a : []
    end

    def on_lvasgn(node)
      if @declared_method_names.include?(node.name)
        add_offense(
          node,
          message: "Shadowing method name - `#{node.name}`."
        )
      end
    end
  end
end
