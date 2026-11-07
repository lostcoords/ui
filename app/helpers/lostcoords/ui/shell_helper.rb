module Lostcoords::Ui
  # Page chrome: the sticky application header, the documentation layout and the phone dock.
  module ShellHelper
    DOCS_SHELL = "lc-docs-shell mx-auto flex w-full max-w-360 gap-10 px-5 sm:px-8 lg:px-10"
    DOCS_SHELL_ASIDE = "sticky top-(--lc-sticky-offset,0rem) hidden h-[calc(100dvh-var(--lc-sticky-offset,0rem))] shrink-0 overflow-y-auto"

    # A sidebar, the page and an optional "On this page" column. navigation: is the sidebar, usually
    # lc_nav_list; it also fills a collapsible menu above the page below lg. contents: is usually lc_toc
    # and shows from xl. main: adds attributes to the <main>, such as a max width for reading pages.
    def lc_docs_shell(navigation:, contents: nil, menu_label: lc_t("lostcoords.ui.docs_shell.menu"), sidebar_label: lc_t("lostcoords.ui.docs_shell.sidebar"), main: {}, **attributes, &block)
      lc_label!(menu_label, :menu_label)
      lc_label!(sidebar_label, :sidebar_label)
      raise ArgumentError, "lc_docs_shell needs navigation:" if navigation.blank?

      chevron = lc_icon("chevron-down", options: { class: "size-4 transition-transform duration-(--lc-motion-quick) group-open/menu:rotate-180", "aria-hidden": true })
      menu = tag.details(class: "group/menu relative z-raised rounded-2xl lc-squircle bg-muted lg:hidden", data: { slot: "docs-shell-menu" }) do
        safe_join([
          tag.summary(safe_join([ menu_label, chevron ]), class: "flex min-h-12 cursor-pointer list-none items-center justify-between gap-content px-4 text-label [&::-webkit-details-marker]:hidden"),
          tag.div(navigation, class: "max-h-[60dvh] overflow-y-auto p-3 pt-0")
        ])
      end
      page = tag.main(**lc_attributes({ id: "main", class: "isolate min-w-0 flex-1 py-5 lg:py-10", data: { slot: "docs-shell-main" } }, main)) do
        safe_join([ menu, tag.div(capture(&block), class: "pt-6 lg:pt-0") ])
      end

      tag.div(**lc_attributes({ class: DOCS_SHELL, data: { slot: "docs-shell" } }, attributes)) do
        safe_join([
          tag.aside(navigation, tabindex: 0, aria: { label: sidebar_label }, class: lc_tw(DOCS_SHELL_ASIDE, "lc-docs-shell__sidebar w-52 py-8 pe-4 lg:block"),
            data: { slot: "docs-shell-sidebar", controller: "lc-scroll-keeper", lc_scroll_keeper_key_value: "lc-docs-shell" }),
          page,
          (tag.aside(contents, class: lc_tw(DOCS_SHELL_ASIDE, "w-44 py-12 ps-4 xl:block"), data: { slot: "docs-shell-contents" }) if contents.present?)
        ].compact)
      end
    end

    # A sticky header whose glass fades in once the page scrolls. Yields a builder: header.brand,
    # header.nav and header.actions render in that order along the bar. bar: adds attributes to the
    # bar, such as a max width. While it renders, --lc-sticky-offset clears it for anchors and sidebars.
    def lc_app_header(bar: {}, **attributes, &block)
      raise ArgumentError, "lc_app_header needs a block" unless block

      content = capture(Parts::AppHeader.new(self), &block)
      tag.header(**lc_attributes({ class: "lc-app-header sticky top-0 z-sticky px-3 pt-3 pb-4 sm:px-6",
        data: { slot: "app-header", controller: "lc-app-header", action: "scroll@window->lc-app-header#scroll" } }, attributes)) do
        tag.div(**lc_attributes({ class: "relative isolate mx-auto flex min-h-16 w-full max-w-page items-center gap-related px-3 py-2 sm:gap-content sm:px-5", data: { slot: "app-header-bar" } }, bar)) do
          safe_join([ tag.span(class: lc_glass_class(thick: true, extra: "lc-app-header__glass pointer-events-none absolute inset-0 -z-(--lc-z-raised)"), aria: { hidden: true }), content ])
        end
      end
    end

    # A floating bar at the bottom of a phone screen: dock.nav for primary destinations and dock.menu
    # for a button whose actions fan out above it. It reserves its height at the end of the page, so
    # render it last, and it hides while the on-screen keyboard is open.
    def lc_dock(**attributes, &block)
      raise ArgumentError, "lc_dock needs a block" unless block

      content = capture(Parts::Dock.new(self), &block)
      tag.div(**lc_attributes({ class: "lc-dock", data: { slot: "dock", controller: "lc-dock",
        action: "resize@window->lc-dock#keyboard focusin@document->lc-dock#keyboard focusout@document->lc-dock#keyboard" } }, attributes)) do
        safe_join([ content, tag.div(class: "lc-dock__space", aria: { hidden: true }) ])
      end
    end
  end
end
