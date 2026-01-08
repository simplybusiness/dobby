module Security
  class RejectAllRequestsLocal < RuboCop::Cop::Base
    RAILS_ENV = ['integration', 'staging', 'production']

    MSG = "RAILS CONFIG: Restrict usage of option 'consider_all_requests_local' on #{RAILS_ENV.join(', ')} envs"
    def_node_matcher "consider_all_requests_local", '(send (send nil :config) :consider_all_requests_local= (true))'

    def on_send(node)
      source = node.source
      file_name = node.loc.operator.to_s

      add_offense(node.loc.selector) if found_match(source) && block_listed?(file_name)
    end

    def block_listed?(string)
      RAILS_ENV.any? { |env| string.include?(env) }
    end

    def found_match(string)
      # Don't match commented lines
      return false if /^\s*#/.match?(string)

      /config.consider_all_requests\S?.*=\s?.*true/.match?(string)
    end
  end
end
