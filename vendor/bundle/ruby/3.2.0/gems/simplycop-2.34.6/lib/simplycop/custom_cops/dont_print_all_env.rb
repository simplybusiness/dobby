# frozen_string_literal: true

module CustomCops
  class DontPrintAllEnv < RuboCop::Cop::Base
    #  This cop checks if someone accidentally print all environment variables
    #  because some of them may contain secrets.
    #
    # @example
    #   # bad
    #   puts ENV.to_h
    #   puts `env`
    #   puts ENVIRON.to_h
    #
    #   # good
    #   puts ENV['SOME_KEY']
    #   puts ENVIRON['SOME_KEY']
    MSG = 'Printing all Environment Variables is extremely risky ' \
          'If this code has been run, then it is likely that secrets have been ' \
          'exposed in plaintext. Please alert `#infosec` about this so it can be ' \
          'investigated immediately.'

    def_node_matcher :convert_env_to_hash_or_array?, <<~PATTERN
      (send (const nil? {:ENVIRON :ENV}) {:to_h :to_a :to_hash})
    PATTERN

    def_node_matcher :print_all_env_shell?, <<~PATTERN
      (send nil? {:puts :p :print} (xstr(str "env")))
    PATTERN

    def on_send(node)
      return unless convert_env_to_hash_or_array?(node) || print_all_env_shell?(node)

      add_offense(node.loc.selector)
    end
  end
end
