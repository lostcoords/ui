module Lostcoords::Ui
  module DescriptionListHelper
    STAT_TONES = { default: "text-foreground", primary: "text-primary", success: "text-success", warning: "text-warning", destructive: "text-destructive" }.freeze
    STATS_COLUMNS = { nil => "grid-cols-[repeat(auto-fit,minmax(min(100%,9rem),1fr))]", 2 => "grid-cols-2", 3 => "grid-cols-3", 4 => "grid-cols-2 sm:grid-cols-4" }.freeze
    STATS_LAYOUTS = {
      inline: "flex flex-wrap items-baseline gap-x-section gap-y-tight",
      grid: "grid gap-related"
    }.freeze
    STAT = "flex min-w-0 items-baseline gap-tight group-data-[layout=grid]/stats:flex-col group-data-[layout=grid]/stats:items-stretch " \
      "group-data-[layout=grid]/stats:rounded-2xl group-data-[layout=grid]/stats:lc-squircle group-data-[layout=grid]/stats:bg-tile group-data-[layout=grid]/stats:p-content"

    # Yields a builder; `list.item "Owner", "Ada"` or `list.item("Owner") { … }` adds a row.
    # Rows stack on phones and sit in two columns from the sm breakpoint.
    def lc_description_list(**attributes, &block)
      defaults = { class: "m-0 min-w-0 divide-y divide-border [&>div:first-child]:pt-0 [&>div:last-child]:pb-0", data: { slot: "description-list" } }
      tag.dl(**lc_attributes(defaults, attributes)) do
        capture(Parts::DescriptionList.new(self), &block) if block
      end
    end

    # Headline numbers as a description list of lc_stat items. layout: :inline runs them along a line,
    # each value followed by its label; :grid gives each a tile, the label under the value, in
    # columns: (2, 3 or 4; nil fits as many as the width allows).
    def lc_stats(layout: :inline, columns: nil, **attributes, &block)
      layout = lc_option!(:layout, layout, STATS_LAYOUTS.keys)
      raise ArgumentError, "columns: lays out a grid; pass layout: :grid" if columns && layout != :grid

      columns = lc_option!(:columns, columns, STATS_COLUMNS.keys.compact) if columns
      classes = lc_tw("group/stats m-0 min-w-0", STATS_LAYOUTS.fetch(layout), (STATS_COLUMNS.fetch(columns) if layout == :grid))
      tag.dl(**lc_attributes({ class: classes, data: { slot: "stats", layout: layout } }, attributes)) do
        capture(&block) if block
      end
    end

    # One number in lc_stats: the value in bold tabular figures and its label in muted text. tone:
    # colours the value with a status tone. A block replaces the value, such as a link around it.
    def lc_stat(value = nil, label:, tone: :default, **attributes, &block)
      lc_label!(label, :label)
      tone = lc_option!(:tone, tone, STAT_TONES.keys)
      value = capture(&block) if block
      raise ArgumentError, "lc_stat needs a value or a block" if value.nil?

      tag.div(**lc_attributes({ class: STAT, data: { slot: "stat", tone: (tone unless tone == :default) }.compact }, attributes)) do
        safe_join([
          tag.dt(label, class: "order-last text-small text-muted-foreground group-data-[layout=grid]/stats:text-caption", data: { slot: "stat-label" }),
          tag.dd(value, class: lc_tw("m-0 text-heading font-semibold tabular-nums", STAT_TONES.fetch(tone)), data: { slot: "stat-value" })
        ])
      end
    end
  end
end
