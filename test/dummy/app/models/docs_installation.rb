module DocsInstallation
  LAYOUT = <<~ERB.strip.freeze
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  ERB
  FIRST_COMPONENT = '<%= ui_button "Create project", icon: "plus" %>'.freeze

  def self.stylesheet
    <<~CSS
      @layer theme, base, layout, components, modules, utilities;

      @import "tailwindcss/theme.css" layer(theme);
      @import "tailwindcss/preflight.css" layer(base);
      @import "tailwindcss/utilities.css" layer(utilities);

      @plugin "@tailwindcss/typography";

      @import "../builds/tailwind/lostcoords_ui.css";
    CSS
  end
end
