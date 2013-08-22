gem 'rspec'
require 'ostruct'

RSpec.configure do |c|
  c.color = true
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end

