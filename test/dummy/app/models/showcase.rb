require_relative "../../../../lib/lostcoords/ui/components"

module Showcase
  # stage: :panel shows the example centred in a muted panel that sets the same context as a card.
  # :bare shows it on the page at full width, for surfaces (cards, code blocks, tables) and page layouts.
  STAGES = %i[panel bare].freeze

  Example = Data.define(:specimen, :title, :stage) do
    def initialize(specimen:, title:, stage:)
      raise ArgumentError, "unknown stage #{stage.inspect}" unless STAGES.include?(stage)

      super
    end


    def source = File.read(File.expand_path("../views/showcase/specimens/_#{specimen}.html.erb", __dir__)).strip
    def note
      return unless specimen == :button_custom_icon

      'For custom SVGs and spinners, use data-icon="inline-start" or data-icon="inline-end". The button reduces padding on that edge for optical balance. The icon: option sets this automatically.'
    end

    def builders
      names = Lostcoords::Ui::Components.all.map(&:name)
      source.scan(/\blc_\w+/).map(&:to_sym).uniq & names
    end
  end

  # A section documents the helpers it owns. Other helpers its examples call link to their own page.
  Section = Data.define(:id, :title, :description, :examples, :components) do
    def initialize(id:, title:, description:, examples:, components: [ :"lc_#{id}" ])
      super
    end

    def builders = examples.flat_map(&:builders).uniq
    def related = builders - components
  end

  def self.sections
    [
      Section.new(:foundations, "Foundations", "Typography, spacing and reading rhythm shared by every app.", [
        Example.new(:typography, "Text styles", :panel),
        Example.new(:typography_japanese, "Japanese text", :panel),
        Example.new(:eyebrow, "Eyebrow", :panel),
        Example.new(:layout, "Page rhythm", :bare),
        Example.new(:layout_responsive, "Responsive containers", :bare),
        Example.new(:reading, "Reading content", :bare),
        Example.new(:reading_japanese, "Japanese reading", :bare),
        Example.new(:motion_controls, "Hover and press", :panel),
        Example.new(:motion_feedback, "Motion feedback", :panel),
        Example.new(:layout_split, "Main column and aside", :bare),
        Example.new(:layout_columns, "Balanced columns", :bare)
      ], %i[lc_stack lc_inline lc_container lc_split lc_columns lc_section lc_section_header lc_heading lc_text lc_prose]),
      Section.new(:code_block, "Code block", "Source snippets with copying, optional highlighting and collapsible long content.", [
        Example.new(:code_block, "Plain source", :bare),
        Example.new(:code_block_title, "With a filename", :bare),
        Example.new(:code_block_long, "Collapsible source", :bare)
      ]),
      Section.new(:button, "Button", "Actions, links and native Rails forms.", [
        Example.new(:button, "Default", :panel),
        Example.new(:button_options, "Variants", :panel),
        Example.new(:button_tones, "Destructive tone", :panel),
        Example.new(:button_glass, "Glass over content", :bare),
        Example.new(:button_sizes, "Sizes", :panel),
        Example.new(:button_with_icon, "With an icon", :panel),
        Example.new(:button_custom_icon, "Custom icons and content", :panel),
        Example.new(:button_loading, "Loading", :panel),
        Example.new(:button_disabled, "Disabled", :panel),
        Example.new(:button_link, "As a link", :panel),
        Example.new(:button_form, "HTTP actions", :panel),
        Example.new(:icon_button, "Icon buttons", :panel),
        Example.new(:select_trigger, "Select trigger", :panel),
        Example.new(:split_button, "Split button", :panel),
        Example.new(:split_button_variants, "Split button variants and sizes", :panel),
        Example.new(:button_expanded, "Expanded swap and decorative span", :panel)
      ], %i[lc_button lc_button_link_to lc_button_to lc_icon_button lc_icon_button_link_to lc_icon_button_to lc_icon lc_select_trigger lc_split_button]),
      Section.new(:copy_button, "Copy button", "Copy text or a live field value with animated confirmation and accessible feedback.", [
        Example.new(:copy_button, "Labels, icons and disabled controls", :panel),
        Example.new(:copy_button_source, "Copy from an element", :panel),
        Example.new(:copy_button_localized, "Translated labels", :panel)
      ]),
      Section.new(:badge, "Badge", "Labels, counts and status.", [
        Example.new(:badge, "Tones", :panel),
        Example.new(:badge_status, "Pill status", :panel)
      ]),
      Section.new(:toggle, "Toggle", "Pressed controls, filter links and radio choices.", [
        Example.new(:toggle, "Filters", :panel),
        Example.new(:toggle_links, "Navigation", :panel),
        Example.new(:toggle_disabled, "Disabled and ghost", :panel),
        Example.new(:toggle_icons, "Icon-only toggles", :panel)
      ]),
      Section.new(:avatar, "Avatar", "Initials or an image representing a person.", [
        Example.new(:avatar, "Initials and images", :panel),
        Example.new(:avatar_sizes, "Sizes", :panel),
        Example.new(:avatar_stack, "Avatar groups", :panel)
      ], %i[lc_avatar lc_avatar_stack]),
      Section.new(:icon_badge, "Icon badge", "A small container for a symbol.", [
        Example.new(:icon_badge, "Shapes and sizes", :panel),
        Example.new(:icon_badge_circle, "Round icons and tones", :panel)
      ]),
      Section.new(:card, "Card", "Surfaces for related content.", [
        Example.new(:card, "Default", :bare),
        Example.new(:card_compact, "Compact", :bare),
        Example.new(:card_link, "Linked card", :bare),
        Example.new(:card_inset, "Custom spacing", :bare),
        Example.new(:card_unpadded, "Edge-to-edge content", :bare),
        Example.new(:card_form, "With form controls", :bare),
        Example.new(:card_validation, "Validation feedback", :bare)
      ]),
      Section.new(:glass, "Glass", "A translucent surface for controls floating over content.", [
        Example.new(:glass, "Search bar", :bare)
      ]),
      Section.new(:table, "Table", "Native tables with clear headers and subtle row dividers. Keep captions, headers and scroll containers in the view.", [
        Example.new(:table, "Records", :bare)
      ]),
      Section.new(:empty_state, "Empty state", "A starting point when there is no content yet.", [
        Example.new(:empty_state, "Empty state", :panel),
        Example.new(:empty_state_composed, "Title, text and icon on a card", :bare)
      ]),
      Section.new(:stats, "Stats", "Headline numbers, in a line or as tiles.", [
        Example.new(:stats, "In a line", :panel),
        Example.new(:stats_grid, "Tiles", :panel)
      ], %i[lc_stats lc_stat]),
      Section.new(:time, "Time", "A short relative time, as X shows it, with the full date on hover.", [
        Example.new(:time, "Relative and dated", :panel)
      ]),
      Section.new(:field, "Field", "Labels, controls and validation that stay connected.", [
        Example.new(:field, "Label and hint", :panel),
        Example.new(:invalid_field, "Validation", :panel),
        Example.new(:rails_field, "Rails forms", :panel),
        Example.new(:layout_form_actions, "Form actions", :panel),
        Example.new(:form_builder, "Form builder", :panel),
        Example.new(:fieldset, "Grouped controls", :panel)
      ], %i[lc_field lc_fieldset lc_form_with]),
      Section.new(:checkbox, "Checkbox", "Native checkboxes with labels and hints.", [
        Example.new(:checkbox, "Checkboxes", :panel)
      ]),
      Section.new(:radio, "Radio", "One choice from a short list.", [
        Example.new(:radio, "Radio group", :panel),
        Example.new(:radio_cards, "Cards", :panel)
      ], %i[lc_radio lc_choice_group]),
      Section.new(:switch, "Switch", "An on or off setting that submits like a checkbox.", [
        Example.new(:switch, "Switches", :panel)
      ]),
      Section.new(:input, "Input", "Native single-line input.", [
        Example.new(:input, "Sizes", :panel),
        Example.new(:input_states, "Disabled and read-only", :panel)
      ]),
      Section.new(:select, "Native select", "Native options with consistent sizing.", [
        Example.new(:select, "Native select", :panel)
      ]),
      Section.new(:textarea, "Textarea", "Room for more than one line.", [
        Example.new(:textarea, "Textarea", :panel)
      ]),
      Section.new(:char_counter, "Character counter", "A ring that fills as a field nears its character limit.", [
        Example.new(:char_counter, "Counting a field", :panel)
      ]),
      Section.new(:alert, "Alert", "Inline feedback, warnings and errors.", [
        Example.new(:alert, "Error", :panel),
        Example.new(:alert_success, "Success", :panel),
        Example.new(:alert_details, "Title and actions", :panel)
      ]),
      Section.new(:tabs, "Tabs", "Panels of related content behind one tab list, with arrow key navigation.", [
        Example.new(:tabs, "Tabs", :bare),
        Example.new(:tabs_vertical, "Vertical, with manual activation", :bare)
      ]),
      Section.new(:breadcrumb, "Breadcrumb", "The path to the current page.", [
        Example.new(:breadcrumb, "Breadcrumb", :panel)
      ]),
      Section.new(:nav_list, "Nav list", "Navigation that marks the current page: sidebars, page contents, tab rows and a phone dock.", [
        Example.new(:nav_list, "Sidebar", :panel),
        Example.new(:nav_list_compact, "On this page", :panel),
        Example.new(:nav_list_row, "Row with a sliding indicator", :bare),
        Example.new(:nav_list_dock, "Dock", :panel)
      ]),
      Section.new(:tab_bar, "Tab bar", "Links to the views of a page as a row of underlined tabs, with counts.", [
        Example.new(:tab_bar, "Tabs that share the row", :bare),
        Example.new(:tab_bar_scroll, "Scrolling when it overflows", :bare)
      ]),
      Section.new(:sidebar, "Sidebar", "A sticky app sidebar that folds to an icon rail and remembers the choice.", [
        Example.new(:sidebar, "Navigation and an account menu", :bare),
        Example.new(:sidebar_rail, "Folded to a rail", :bare)
      ]),
      Section.new(:toc, "Table of contents", "An \"On this page\" list that marks the section the reader has scrolled to.", [
        Example.new(:toc, "Links you list", :panel),
        Example.new(:toc_headings, "From rendered headings", :bare)
      ]),
      Section.new(:app_header, "App header", "A sticky glass header with your brand, navigation and actions.", [
        Example.new(:app_header, "Header", :bare)
      ]),
      Section.new(:docs_shell, "Docs shell", "A documentation layout: sidebar, page and an \"On this page\" column, with a menu on phones.", [
        Example.new(:docs_shell, "Documentation page", :bare)
      ]),
      Section.new(:dock, "Dock", "A floating bar of primary destinations and quick actions at the bottom of a phone screen.", [
        Example.new(:dock, "Dock with actions", :panel)
      ]),
      Section.new(:pager, "Pager", "Previous and next links between pages in a sequence.", [
        Example.new(:pager, "Pager", :bare),
        Example.new(:pager_compact, "Compact", :panel)
      ]),
      Section.new(:link, "Link", "Inline text links with a visible underline.", [
        Example.new(:link, "Tones", :panel)
      ]),
      Section.new(:skip_link, "Skip link", "Lets keyboard users jump past repeated navigation.", [
        Example.new(:skip_link, "Skip link", :panel)
      ]),
      Section.new(:description_list, "Description list", "Labelled details, such as record properties.", [
        Example.new(:description_list, "Details", :bare)
      ]),
      Section.new(:toggle_group, "Toggle group", "Mutually exclusive choices with keyboard navigation and form values.", [
        Example.new(:toggle_group, "Mutually exclusive choices", :panel),
        Example.new(:toggle_group_links, "Navigation links", :panel),
        Example.new(:toggle_group_pills, "Wrapping pills", :panel),
        Example.new(:toggle_group_form, "Form values, native radios and reset", :panel)
      ], %i[lc_toggle_group lc_toggle_group_item]),
      Section.new(:kbd, "Keyboard shortcut", "Page-wide keys that focus or press an element, and the hints that show them.", [
        Example.new(:kbd, "Focus a field", :panel)
      ]),
      Section.new(:spinner, "Spinner", "An action in progress.", [
        Example.new(:spinner, "Sizes and labels", :panel)
      ]),
      Section.new(:skeleton, "Skeleton", "A placeholder while content loads.", [
        Example.new(:skeleton, "Placeholder", :panel)
      ]),
      Section.new(:menu, "Menu", "Actions in a floating panel.", [
        Example.new(:row_menu, "Actions", :panel),
        Example.new(:menu_options, "Icon trigger, hints, choices and groups", :panel)
      ], %i[lc_menu lc_menu_option lc_menu_group]),
      Section.new(:popover, "Popover", "Content anchored to a trigger.", [
        Example.new(:open_popover, "Anchored content", :panel),
        Example.new(:row_popover, "Opened from a row", :panel)
      ]),
      Section.new(:tooltip, "Tooltip", "A short hint on hover and keyboard focus.", [
        Example.new(:tooltip, "Tooltips", :panel)
      ]),
      Section.new(:hovercard, "Hover card", "A preview of what a link points to, on hover and keyboard focus.", [
        Example.new(:hovercard, "Profile preview", :panel)
      ]),
      Section.new(:dialog, "Dialog", "A focused task, with a sheet layout on phones.", [
        Example.new(:modal_dialog, "Modal", :panel),
        Example.new(:dialog_fit, "Mobile dialog", :panel),
        Example.new(:dialog_heights, "Mobile height options", :panel),
        Example.new(:dialog_context, "Compact dialog", :panel),
        Example.new(:sheet_popover, "Popover sheet", :panel),
        Example.new(:dialog_controlled, "Opened by your controller", :panel),
        Example.new(:confirm_sheet, "Turbo confirm", :panel)
      ], %i[lc_dialog lc_confirm_sheet lc_sheet]),
      Section.new(:toast, "Toast", "Brief feedback after an action.", [
        Example.new(:toast, "Brief feedback", :panel),
        Example.new(:toast_region, "Over dialogs and sticky headers", :panel),
        Example.new(:toast_region_placement, "Centred, at the top on phones", :panel)
      ], %i[lc_toast lc_toast_region]),
      Section.new(:search, "Search", "A full-screen search with grouped results.", [
        Example.new(:search, "Filtered in the browser", :panel)
      ], %i[lc_search lc_search_group lc_search_result]),
      Section.new(:collapsible, "Collapsible", "Content that expands in place.", [
        Example.new(:collapsible, "Expandable content", :bare),
        Example.new(:collapsible_summary, "Row summary with a chevron", :panel),
        Example.new(:collapsible_button, "Button summary", :panel)
      ]),
      Section.new(:list_group, "List group", "Grouped rows of settings, with a heading and footnote.", [
        Example.new(:list_group, "Settings", :bare),
        Example.new(:list_field, "Form rows", :panel)
      ], %i[lc_list_section lc_list_group lc_list_row lc_list_item lc_list_field]),
      Section.new(:emoji, "Emoji picker", "Search, categories and skin tones.", [
        Example.new(:html, "Emoji picker", :panel)
      ], %i[lc_emoji_picker])
    ].sort_by { |section| [ section.id == :foundations ? 0 : 1, section.title.downcase ] }
  end

  def self.description(id) = sections.find { |section| section.id == id }.description
  def self.owner(name) = sections.find { |section| section.components.include?(name) }
end
