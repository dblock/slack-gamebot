module Mongoid
  class Criteria
    def respond_to?(method, include_private = false)
      # see https://github.com/intridea/grape/blob/master/lib/grape/dsl/inside_route.rb#L209, causes a merge without options
      method == 'merge' ? false : super
    end
  end
end
