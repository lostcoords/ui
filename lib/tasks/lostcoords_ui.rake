namespace :lostcoords do
  namespace :ui do
    desc "Print the component rendering helpers and their signatures"
    task :components do
      require "lostcoords/ui/components"
      puts Lostcoords::Ui::Components.markdown
    end

    desc "Print the style builders and their signatures"
    task :builders do
      require "lostcoords/ui/builders"
      puts Lostcoords::Ui::Builders.markdown
    end
  end
end
