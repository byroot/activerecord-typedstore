module ActiveRecord::TypedStore

  module DumbCoder
    extend self

    def load(data)
      data || {}
    end

    def dump(data)
      data || {}
    end

  end

end
