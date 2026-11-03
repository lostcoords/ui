namespace :lostcoords do
  namespace :ui do
    namespace :tokens do
      desc "Fail unless the stylesheet at PATH defines every property in Lostcoords::Ui::TOKENS"
      task :check, [ :path ] do |_, args|
        require "lostcoords/ui/tokens"
        path = args.fetch(:path, "app/assets/tailwind/tokens.css")
        missing = Lostcoords::Ui::Tokens.missing_from(File.read(path))
        abort "#{path} does not define: #{missing.join(" ")}" if missing.any?

        puts "#{path} defines all #{Lostcoords::Ui::TOKENS.size} lostcoords-ui tokens"
      end

      desc "Print the properties the gem reads from the host, derived by building it against the at-rules in PATH"
      task :generate, [ :path ] do |_, args|
        require "lostcoords/ui/tokens"
        require "tailwindcss/ruby"
        path = args.fetch(:path, "app/assets/tailwind/tokens.css")
        puts Lostcoords::Ui::Tokens.derive(path, tailwindcss: Tailwindcss::Ruby.executable)
      end
    end

    desc "Print every helper the engine gives host views, with its signature, as a Markdown list"
    task :builders do
      require "lostcoords/ui/builders"
      puts Lostcoords::Ui::Builders.markdown
    end
  end
end
