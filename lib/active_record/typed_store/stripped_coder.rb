# frozen_string_literal: true

module ActiveRecord::TypedStore
  class StrippedCoder
    def initialize(coder = JSON)
      @coder = coder || raise(ArgumentError, "needs to be based on another coder (can't be nil)")
    end

    def load(data)
      @coder.load(data) || {}
    end

    def dump(data)
      stripped = (data || {}).filter do |_k, value|
        value.present? || value.is_a?(FalseClass)
      end
      @coder.dump(stripped)
    end
  end
end
