module Lostcoords::Ui
  module SearchHelper
    RESULT_DETAIL = "line-clamp-2 text-xs text-muted-foreground [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground"

    # A search trigger that opens a full-screen search over the page. Attributes go to the trigger,
    # which is what sits in your layout. Results come from one of three places:
    #
    # - src: the server renders them. As the user types, the field requests src with the query in
    #   param and shows the HTML it answers, built from lc_search_group and lc_search_result. Without
    #   JavaScript the field submits to src as a normal GET.
    # - The block: rows rendered there are filtered in the browser by their text and keywords.
    # - Your own code: handle lc-search:query, call preventDefault and fill event.detail.results.
    #
    # The block also renders what shows before anything is typed. empty: is the note for a query with
    # no results, where %{query} stands for the query, and prompt: the note shown before anything is
    # typed when there is nothing else to show. Pass id: when a page has two searches, and shortcut: nil
    # to drop the page shortcut.
    def lc_search(label:, src: nil, param: "q", placeholder: label, trigger: lc_t("lostcoords.ui.search.trigger"), empty: lc_t("lostcoords.ui.search.empty"), prompt: nil,
      shortcut: "mod+k", id: "lc-search", **attributes, &block)
      lc_label!(label, :label)
      lc_label!(trigger, :trigger)
      lc_label!(param, :param)
      lc_label!(id, :id)
      lc_label!(empty, :empty)
      defaults = { class: "lc-search-trigger", aria: { label: label } }
      data = { lc_search_target: "trigger", action: "lc-search#open", slot: "search-trigger" }
      required = { type: "button", aria: { haspopup: "dialog", controls: id }, data: shortcut ? lc_shortcut_data(shortcut, data) : data }
      render "lostcoords/ui/components/lc_search", id:, label:, src:, param:, placeholder:, trigger:, empty:, prompt: prompt.presence, shortcut:,
        attributes: lc_attributes(defaults, attributes, required), content: (capture(&block) if block)
    end

    # A titled group of results.
    def lc_search_group(title, **attributes, &block)
      lc_label!(title, :title)
      defaults = { class: "flex flex-col py-related", aria: { label: title }, data: { slot: "search-group" } }
      tag.section(**lc_attributes(defaults, attributes)) do
        safe_join([ tag.h2(title, class: "px-heading pb-related font-mono text-xs font-medium uppercase tracking-widest text-muted-foreground", data: { slot: "search-group-title" }), (capture(&block) if block) ])
      end
    end

    # One result: a link with an optional icon badge and a line of detail. keywords: adds words the
    # browser filter matches without showing them. A block replaces the title and detail.
    def lc_search_result(title, url, detail: nil, icon: nil, keywords: nil, **attributes, &block)
      lc_label!(url, :url)
      lc_label!(title, :title) unless block
      defaults = { class: "lc-search-result group/result flex min-h-control-lg w-full items-center gap-heading rounded-2xl px-heading py-related text-start no-underline", data: { slot: "search-result", lc_search_target: "result", lc_search_keywords: keywords.presence } }
      tag.a(**lc_attributes(defaults, attributes, { href: url })) do
        body = block ? capture(&block) : tag.span(class: "flex min-w-0 flex-1 flex-col gap-tight") do
          safe_join([ tag.span(title, class: "truncate text-label font-semibold", data: { slot: "search-result-title" }), tag.span(detail, class: RESULT_DETAIL, data: { slot: "search-result-detail" }) ])
        end
        safe_join([ (lc_icon_badge(icon: icon) if icon), body, lc_icon("arrow-turn-down-left", options: { class: "size-4 shrink-0 text-muted-foreground opacity-0 group-hover/result:opacity-100 group-focus-visible/result:opacity-100", "aria-hidden": true }) ].compact)
      end
    end
  end
end
