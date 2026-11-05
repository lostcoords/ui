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

# Runs with tailwindcss-rails' own engines step, before every tailwindcss:build and tailwindcss:watch.
# Apps without tailwindcss-rails import the gem's stylesheets by path instead.
if defined?(Tailwindcss::Engines)
  namespace :tailwindcss do
    task :engines do
      require "lostcoords/ui/stylesheets"
      Lostcoords::Ui::Stylesheets.write(Rails.root.join("app/assets/builds/tailwind"))
    end
  end
end
