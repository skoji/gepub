require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rdoc/task'

RSpec::Core::RakeTask.new(:spec => :generate_code)

task :default => :spec

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
end

# also generates 'lib/gepub/book_add_item.rb' 
file 'lib/gepub/metadata_add.rb' => 'tools/generate_function.rb' do
  sh %Q(ruby tools/generate_function.rb)
end

desc 'auto generate code'
task :generate_code => ['lib/gepub/metadata_add.rb'] 
