module SlackGamebot
  module Dispatch
    module Hook
      def included(caller)
        caller.hooks ||= []
        caller.hooks << name.demodulize.underscore.to_sym
      end
    end
  end
end
