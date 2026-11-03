require_relative "lib/lostcoords/ui/version"

Gem::Specification.new do |spec|
  spec.name = "lostcoords-ui"
  spec.version = Lostcoords::Ui::VERSION
  spec.authors = [ "Lost Coordinates" ]
  spec.summary = "Rails UI components for Lost Coordinates apps."
  spec.license = "MIT"
  spec.files = Dir.chdir(__dir__) do
    Dir[
      "app/**/*",
      "config/**/*",
      "lib/**/*",
      "LICENSE",
      "README.md"
    ]
  end
  spec.require_paths = [ "lib" ]

  spec.add_dependency "heroicons", "~> 2.2"
  spec.add_dependency "importmap-rails", ">= 2.0"
  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "tailwind_merge", "~> 1.5"
  spec.add_dependency "unicode-emoji", "~> 4.2"
end
