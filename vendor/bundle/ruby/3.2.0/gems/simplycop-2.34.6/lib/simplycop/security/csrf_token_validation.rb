module Security
  class CSRFTokenValidation < RuboCop::Cop::Base
    MSG = 'Do not disable authenticity token validation'
    def_node_matcher :skip_before_action, '(send _ :skip_before_action ...)'

    def on_send(node)
      return unless skip_before_action(node)

      _, _, first_arg = *node
      method_name = first_arg.children.first if first_arg.type == :sym
      add_offense(node.loc.selector) if found_match(method_name)
    end

    def found_match(method)
      [:verify_authenticity_token, 'verify_authenticity_token'].include?(method)
    end
  end
end
