require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |sp|
  sp.pattern = Dir.glob("spec/**/*_spec.rb")
  sp.rspec_opts = "--format documentation"
end
