module Api
  module Helpers
    module ErrorHelpers
      extend ActiveSupport::Concern

      included do
        rescue_from :all, backtrace: true do |e|
          backtrace = e.backtrace[0..5].join("\n  ")
          Api::Middleware.logger.error "#{e.class.name}: #{e.message}\n  #{backtrace}"
          error = { type: 'other_error', message: e.message }
          error[:backtrace] = backtrace
          error!(error, 400)
        end
        # rescue document validation errors into detail json
        rescue_from Mongoid::Errors::Validations do |e|
          backtrace = e.backtrace[0..5].join("\n  ")
          Api::Middleware.logger.warn "#{e.class.name}: #{e.message}\n  #{backtrace}"
          error!({
                   type: 'param_error',
                   message: e.document.errors.full_messages.uniq.join(', ') + '.',
                   detail: e.document.errors.messages.transform_values(&:uniq)
                 }, 400)
        end
        rescue_from Grape::Exceptions::Validation do |e|
          backtrace = e.backtrace[0..5].join("\n  ")
          Api::Middleware.logger.warn "#{e.class.name}: #{e.message}\n  #{backtrace}"
          error!({
                   type: 'param_error',
                   message: 'Invalid parameters.',
                   detail: { e.params.join(', ') => [e.message] }
                 }, 400)
        end
        rescue_from Grape::Exceptions::ValidationErrors do |e|
          backtrace = e.backtrace[0..5].join("\n  ")
          Api::Middleware.logger.warn "#{e.class.name}: #{e.message}\n  #{backtrace}"
          error!({
                   type: 'param_error',
                   message: 'Invalid parameters.',
                   detail: e.errors.transform_keys do |k|
                     # JSON does not permit having a key of type Array
                     k.count == 1 ? k.first : k.join(', ')
                   end
                 }, 400)
        end
      end
    end
  end
end
