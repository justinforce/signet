notification :off

guard :rspec, all_after_pass: true, all_on_start: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{spec/(spec_helper\.rb|(factories|support/.+\.rb))}) { 'spec' }
end
