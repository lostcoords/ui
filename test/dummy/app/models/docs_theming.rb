module DocsTheming
  COLORS = <<~CSS.strip.freeze
    :root {
      --primary: oklch(46% 0.14 155);
    }
    html[data-theme="dark"] {
      --primary: oklch(75% 0.14 155);
    }
  CSS
  FONTS = <<~CSS.strip.freeze
    :root {
      --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
      --font-display: "Inter", ui-sans-serif, system-ui, sans-serif;
    }
  CSS
  SHAPE = <<~CSS.strip.freeze
    :root {
      --radius: 0.375rem;
      --lc-shadow: 0 2px 12px rgb(0 0 0 / 0.08);
    }

    html[data-theme="dark"] {
      --lc-shadow: 0 2px 12px rgb(0 0 0 / 0.3);
    }
  CSS
end
