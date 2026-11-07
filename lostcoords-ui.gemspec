require_relative "lib/lostcoords/ui/version"

Gem::Specification.new do |spec|
  spec.name = "lostcoords-ui"
  spec.version = Lostcoords::Ui::VERSION
  spec.authors = [ "Lost Coordinates" ]
  spec.summary = "Rails UI components with Tailwind CSS and Stimulus."
  spec.homepage = "https://github.com/lostcoords/ui"
  spec.metadata = {
    "source_code_uri" => "https://github.com/lostcoords/ui",
    "documentation_uri" => "https://ui.lostcoords.com",
    "bug_tracker_uri" => "https://github.com/lostcoords/ui/issues",
    "changelog_uri" => "https://github.com/lostcoords/ui/releases",
    "allowed_push_host" => "https://rubygems.org"
  }
  spec.required_ruby_version = ">= 3.2"
  spec.license = "MIT"
  spec.files = Dir.chdir(__dir__) do
    Dir[
      "app/**/*",
      "config/**/*",
      "lib/**/*",
      "vendor/heroicons/**/*",
      "LICENSE",
      "README.md"
    ]
  end
  spec.require_paths = [ "lib" ]

  spec.add_dependency "actionview", ">= 8.0"
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "nokogiri", ">= 1.16"
  spec.add_dependency "tailwind_merge", "~> 1.5"
  spec.add_dependency "unicode-emoji", "~> 4.2"
end
