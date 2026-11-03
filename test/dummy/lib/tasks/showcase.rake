namespace :lostcoords do
  namespace :ui do
    desc "Render the showcase to a static site in DIR (default docs/): its pages, stylesheet and ES modules"
    task :showcase, [ :dir ] => [ "tailwindcss:build", :environment ] do |_, args|
      dir = Pathname(File.expand_path(args.fetch(:dir, "docs")))
      session = ActionDispatch::Integration::Session.new(Rails.application).tap { |it| it.host! "localhost" }
      fetch = lambda do |path|
        session.get(path)
        abort "#{path} answered #{session.response.status}" unless session.response.successful?
        session.response.body
      end
      undigest = ->(path) { path.sub(/-\h{8}(?=\.\w+\z)/, "") }

      pages = { "index.html" => fetch.("/"), "emoji-catalog.html" => fetch.("/emoji-catalog.html") }
      assets = pages.values.flat_map { |html| html.scan(%r{/assets/[^"'\s)]+}) }.uniq

      FileUtils.rm_rf(dir.join("assets"))
      assets.each do |path|
        target = dir.join(undigest.(path.delete_prefix("/")))
        target.dirname.mkpath
        target.binwrite(fetch.(path).sub(%r{^//# sourceMappingURL=.*\n?}, ""))
      end
      pages.each do |name, html|
        dir.join(name).write(html.gsub(%r{/assets/[^"'\s)]+}) { |path| ".#{undigest.(path)}" })
      end

      dir.join("CNAME").write("ui.lostcoords.com\n")

      puts "Wrote #{pages.size} pages and #{assets.size} assets to #{dir}"
    end
  end
end
