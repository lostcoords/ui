module Lostcoords::Ui
  module Helpers
    paths = Dir[Lostcoords::Ui::Engine.root.join("app/helpers/lostcoords/ui/*_helper.rb")].sort_by do |path|
      [ %w[tailwind_helper.rb button_helper.rb].index(File.basename(path)) || 2, path ]
    end
    paths.each do |path|
      require path
      include Lostcoords::Ui.const_get(File.basename(path, ".rb").camelize)
    end
  end
end
