# frozen_string_literal: true

module ActiveRecord::TypedStore
  module IdentityCoder
    extend self

    def load(data)
      data || {}
    end

    def dump(data)
      data || {}
    end
  end
end
