require 'roar/representer'
require 'roar/json'
require 'roar/json/hal'

require 'api/presenters/paginated_presenter'

Dir[File.expand_path('../presenters', __FILE__) + '/**/*.rb'].each do |file|
  require file
end
