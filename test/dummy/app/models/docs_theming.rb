module DocsTheming
  COLORS = <<~CSS.strip.freeze
    :root {
      --sky: oklch(52% 0.14 155);
      --sky-deep: oklch(46% 0.14 155);
      --sky-soft: oklch(96% 0.02 155);
    }
    html[data-theme="dark"] {
      --sky: oklch(75% 0.14 155);
      --sky-deep: oklch(70% 0.14 155);
      --sky-soft: color-mix(in oklab, var(--sky) 18%, var(--paper));
    }
  CSS
  FONTS = <<~CSS.strip.freeze
    :root {
      --f-body: "Inter", ui-sans-serif, system-ui, sans-serif;
      --f-display: "Inter", ui-sans-serif, system-ui, sans-serif;
    }
  CSS
  SHAPE = <<~CSS.strip.freeze
    body {
      --radius-xl: 0.625rem;
      --radius-3xl: 1rem;
    }

    :root {
      --shadow: 0 2px 12px rgb(0 0 0 / 0.08);
    }

    html[data-theme="dark"] {
      --shadow: 0 2px 12px rgb(0 0 0 / 0.3);
    }
  CSS
end
