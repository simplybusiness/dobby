# frozen_string_literal: true

module CustomCops
  # Detects incorrect semantic version comparisons.
  # Triggers on variables/methods containing 'version'.
  #
  # @example Bad - version.to_f >= 2.0, version >= "2"
  # @example Good - Gem::Version.new(version) >= Gem::Version.new('2.0')
  #
  # If this cop flags a false positive, disable it with an inline rubocop comment.
  class VersionComparison < RuboCop::Cop::Base
    extend RuboCop::Cop::AutoCorrector

    DISABLE_HINT = 'Disable if not a semantic version string.'
    MSG_TO_F = "Avoid `.to_f` on version strings; use `Gem::Version.new()`. #{DISABLE_HINT}"
    MSG_TO_I = "Avoid `.to_i` on version strings; use `Gem::Version.new()`. #{DISABLE_HINT}"
    MSG_STRING = "Avoid ordering operators on version strings; use `Gem::Version.new()`. #{DISABLE_HINT}"
    ORDERING_OPERATORS = [:>=, :>, :<=, :<].freeze
    REVERSED_OPERATORS = { :>= => :<=, :> => :<, :<= => :>=, :< => :> }.freeze

    def_node_matcher :to_f_call?, '(send $_ :to_f)'
    def_node_matcher :to_i_call?, '(send $_ :to_i)'
    def_node_matcher :ordering_comparison?, <<~PATTERN
      (send $_ {#{ORDERING_OPERATORS.map(&:inspect).join(' ')}} (str $_))
    PATTERN
    def_node_matcher :reversed_ordering_comparison?, <<~PATTERN
      (send (str $_) {#{ORDERING_OPERATORS.map(&:inspect).join(' ')}} $_)
    PATTERN

    def on_send(node)
      check_numeric_conversion(node, :to_f_call?, MSG_TO_F)
      check_numeric_conversion(node, :to_i_call?, MSG_TO_I)
      check_ordering_comparison(node)
      check_reversed_ordering_comparison(node)
    end

    private

    def check_numeric_conversion(node, matcher, message)
      send(matcher, node) do |receiver|
        return unless version_related?(receiver)

        add_offense(node, message: message) { |c| autocorrect_numeric(c, node, receiver) }
      end
    end

    def check_ordering_comparison(node)
      ordering_comparison?(node) do |receiver, str_val|
        return unless version_related?(receiver)

        add_offense(node, message: MSG_STRING) do |c|
          c.replace(node, build_comparison(receiver.source, node.method_name, "'#{str_val}'"))
        end
      end
    end

    def check_reversed_ordering_comparison(node)
      reversed_ordering_comparison?(node) do |str_val, receiver|
        return unless version_related?(receiver)

        add_offense(node, message: MSG_STRING) do |c|
          c.replace(node, build_comparison(receiver.source, REVERSED_OPERATORS[node.method_name], "'#{str_val}'"))
        end
      end
    end

    def autocorrect_numeric(corrector, node, receiver)
      parent = node.parent
      if parent&.send_type? && ORDERING_OPERATORS.include?(parent.method_name)
        corrector.replace(parent, build_comparison(receiver.source, parent.method_name, parent.arguments.first.source))
      else
        corrector.replace(node, "Gem::Version.new(#{receiver.source})")
      end
    end

    def build_comparison(lhs, operator, rhs)
      "Gem::Version.new(#{lhs}) #{operator} Gem::Version.new(#{rhs})"
    end

    def version_related?(node)
      return false unless node

      case node.type
      when :lvar, :ivar, :cvar, :gvar then node.children.first.to_s.downcase.include?('version')
      when :send then method_or_key_contains_version?(node)
      else false
      end
    end

    def method_or_key_contains_version?(node)
      return true if node.method_name.to_s.downcase.include?('version')

      key = node.arguments.first
      return true if node.method_name == :[] && key && [:str, :sym].include?(key.type) &&
                     key.value.to_s.downcase.include?('version')

      version_related?(node.receiver)
    end
  end
end
