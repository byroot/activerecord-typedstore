lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'database_cleaner'
require 'activerecord-typedstore'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

Time.zone = 'UTC'

if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord.yaml_column_permitted_classes |= [Date, Time, BigDecimal]
elsif ActiveRecord::Base.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord::Base.yaml_column_permitted_classes |= [Date, Time, BigDecimal]
end

RSpec.configure do |config|
  config.order = 'random'
end
