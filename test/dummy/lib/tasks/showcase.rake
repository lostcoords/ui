namespace :lostcoords do
  namespace :ui do
    desc "Render the showcase to a static site in DIR (default docs/): its pages, stylesheet and ES modules"
    task :showcase, [ :dir ] => [ "tailwindcss:build", :environment ] do |_, args|
      dir = Pathname(File.expand_path(args.fetch(:dir, "docs")))
      session = ActionDispatch::Integration::Session.new(Rails.application).tap { |it| it.host! "localhost" }
      fetch = lambda do |path|
        session.get(path)
        abort "#{path} answered #{session.response.status}" unless session.response.successful?
        session.response.body.gsub(/<input\b(?=[^>]*\bname="authenticity_token")[^>]*>/, "")
      end

      pages = { "index.html" => fetch.("/"), "emoji-catalog.html" => fetch.("/emoji-catalog.html") }
      Showcase.sections.each do |section|
        pages["components/#{section.id}.html"] = fetch.("/components/#{section.id}.html")
      end
      pages["tokens.html"] = fetch.("/tokens.html")
      assets = pages.values.flat_map { |html| html.scan(%r{/assets/[^"'\s)]+}) }.uniq

      FileUtils.rm_rf(dir.join("assets"))
      FileUtils.rm_rf(dir.join("components"))
      assets.each do |path|
        target = dir.join(path.delete_prefix("/"))
        target.dirname.mkpath
        target.binwrite(fetch.(path).sub(%r{^//# sourceMappingURL=.*\n?}, ""))
      end
      pages.each do |name, html|
        target = dir.join(name)
        target.dirname.mkpath
        depth = Pathname(name).each_filename.to_a.length.pred
        prefix = depth.zero? ? "./" : "../" * depth
        target.write(html.gsub(%r{/assets/[^"'\s)]+}) { |path| "#{prefix}#{path.delete_prefix("/")}" })
      end

      dir.join("api.json").write(fetch.("/api.json"))
      dir.join("llms.txt").write(fetch.("/llms.txt"))
      dir.join("wada-license.txt").write(fetch.("/wada-license.txt"))
      dir.join("CNAME").write("ui.lostcoords.com\n")

      puts "Wrote #{pages.size} pages and #{assets.size} assets to #{dir}"
    end
  end
end
