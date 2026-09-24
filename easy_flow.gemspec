require_relative "lib/easy_flow/version"

Gem::Specification.new do |spec|
  spec.name        = "easy_flow"
  spec.version     = EasyFlow::VERSION
  spec.authors     = [ "tylercschneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/DYB-Development/easy_flow"
  spec.summary     = "Guided, versioned, branching flows for Rails apps."
  spec.description = "EasyFlow stores flows as versioned documents of steps and the connections between them, and runs a visitor through the live version one step at a time. Apps register their own step types."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "keystone_ui-react", ">= 0.1.2"
end
