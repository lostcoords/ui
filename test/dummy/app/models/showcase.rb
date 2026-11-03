require_relative "../../../../lib/lostcoords/ui/components"

module Showcase
  Example = Data.define(:specimen, :title, :stage) do
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

  Section = Data.define(:id, :title, :description, :examples) do
    def builders = examples.flat_map(&:builders).uniq
  end

  def self.sections
    [
      Section.new(:foundations, "Foundations", "Typography, spacing and reading rhythm shared by every app.", [
        Example.new(:typography, "Text styles", :page),
        Example.new(:typography_japanese, "Japanese text", :page),
        Example.new(:layout, "Page rhythm", :page),
        Example.new(:layout_responsive, "Responsive containers", :page),
        Example.new(:reading, "Reading content", :page),
        Example.new(:reading_japanese, "Japanese reading", :page),
        Example.new(:motion_controls, "Hover and press", :card),
        Example.new(:motion_feedback, "Motion feedback", :card)
      ]),
      Section.new(:code_block, "Code block", "Source snippets with copying, optional highlighting and collapsible long content.", [
        Example.new(:code_block, "Plain source", :flush),
        Example.new(:code_block_title, "With a filename", :flush),
        Example.new(:code_block_long, "Collapsible source", :flush)
      ]),
      Section.new(:button, "Button", "Actions, links and native Rails forms.", [
        Example.new(:button, "Default", :card),
        Example.new(:button_options, "Variants", :card),
        Example.new(:button_glass, "Glass over content", :page),
        Example.new(:button_sizes, "Sizes", :card),
        Example.new(:button_with_icon, "With an icon", :card),
        Example.new(:button_custom_icon, "Custom icons and content", :card),
        Example.new(:button_loading, "Loading", :card),
        Example.new(:button_disabled, "Disabled", :card),
        Example.new(:button_link, "As a link", :card),
        Example.new(:button_form, "HTTP actions", :card),
        Example.new(:icon_button, "Icon buttons", :card)
      ]),
      Section.new(:copy_button, "Copy button", "Copy text or a live field value with animated confirmation and accessible feedback.", [
        Example.new(:copy_button, "Labels, icons and disabled controls", :card),
        Example.new(:copy_button_source, "Copy from an element", :card),
        Example.new(:copy_button_localized, "Translated labels", :card)
      ]),
      Section.new(:badge, "Badge", "Labels, counts and status.", [
        Example.new(:badge, "Tones", :card),
        Example.new(:badge_status, "Status", :card)
      ]),
      Section.new(:toggle, "Toggle", "Pressed controls and filter navigation.", [
        Example.new(:toggle, "Filters", :card),
        Example.new(:toggle_links, "Navigation", :card),
        Example.new(:toggle_disabled, "Disabled and ghost", :card)
      ]),
      Section.new(:avatar, "Avatar", "Initials or an image representing a person.", [
        Example.new(:avatar, "Initials and images", :card),
        Example.new(:avatar_stack, "Avatar groups", :card)
      ]),
      Section.new(:icon_badge, "Icon badge", "A small container for a symbol.", [
        Example.new(:icon_badge, "Shapes and sizes", :card),
        Example.new(:icon_badge_circle, "Round icons and tones", :card)
      ]),
      Section.new(:card, "Card", "Surfaces for related content.", [
        Example.new(:card, "Default", :page),
        Example.new(:card_compact, "Compact", :page),
        Example.new(:card_link, "Linked card", :page),
        Example.new(:card_unpadded, "Custom spacing", :page),
        Example.new(:card_form, "With form controls", :page),
        Example.new(:card_validation, "Validation feedback", :page)
      ]),
      Section.new(:table, "Table", "Native tables with clear headers and subtle row dividers. Keep captions, headers and scroll containers in the view.", [
        Example.new(:table, "Records", :page)
      ]),
      Section.new(:empty_state, "Empty state", "A starting point when there is no content yet.", [
        Example.new(:empty_state, "Empty state", :page)
      ]),
      Section.new(:field, "Field", "Labels, controls and validation that stay connected.", [
        Example.new(:field, "Label and hint", :page),
        Example.new(:invalid_field, "Validation", :page),
        Example.new(:rails_field, "Rails forms", :page),
        Example.new(:layout_form_actions, "Form actions", :page),
        Example.new(:form_builder, "Form builder", :page)
      ]),
      Section.new(:checkbox, "Checkbox", "Native checkboxes with labels and hints.", [
        Example.new(:checkbox, "Checkboxes", :page)
      ]),
      Section.new(:radio, "Radio", "One choice from a short list.", [
        Example.new(:radio, "Radio group", :page),
        Example.new(:radio_cards, "Cards", :page)
      ]),
      Section.new(:switch, "Switch", "An on or off setting that submits like a checkbox.", [
        Example.new(:switch, "Switches", :page)
      ]),
      Section.new(:input, "Input", "Native single-line input.", [
        Example.new(:input, "Sizes", :page),
        Example.new(:input_states, "Disabled and read-only", :page)
      ]),
      Section.new(:select, "Native select", "Native options with consistent sizing.", [
        Example.new(:select, "Native select", :page)
      ]),
      Section.new(:textarea, "Textarea", "Room for more than one line.", [
        Example.new(:textarea, "Textarea", :page)
      ]),
      Section.new(:alert, "Alert", "Inline feedback, warnings and errors.", [
        Example.new(:alert, "Error", :card),
        Example.new(:alert_success, "Success", :card),
        Example.new(:alert_details, "Title and actions", :card)
      ]),
      Section.new(:tabs, "Tabs", "Panels of related content behind one tab list, with arrow key navigation.", [
        Example.new(:tabs, "Tabs", :page)
      ]),
      Section.new(:breadcrumb, "Breadcrumb", "The path to the current page.", [
        Example.new(:breadcrumb, "Breadcrumb", :card)
      ]),
      Section.new(:nav_list, "Nav list", "Vertical navigation that marks the current page, for sidebars and page contents.", [
        Example.new(:nav_list, "Sidebar", :page),
        Example.new(:nav_list_compact, "On this page", :page)
      ]),
      Section.new(:pager, "Pager", "Previous and next links between pages in a sequence.", [
        Example.new(:pager, "Pager", :page),
        Example.new(:pager_compact, "Compact", :card)
      ]),
      Section.new(:link, "Link", "Inline text links with a visible underline.", [
        Example.new(:link, "Tones", :page)
      ]),
      Section.new(:skip_link, "Skip link", "Lets keyboard users jump past repeated navigation.", [
        Example.new(:skip_link, "Skip link", :card)
      ]),
      Section.new(:description_list, "Description list", "Labelled details, such as record properties.", [
        Example.new(:description_list, "Details", :page)
      ]),
      Section.new(:toggle_group, "Toggle group", "Mutually exclusive choices with keyboard navigation and form values.", [
        Example.new(:toggle_group, "Mutually exclusive choices", :card),
        Example.new(:toggle_group_form, "Form values and reset", :card)
      ]),
      Section.new(:spinner, "Spinner", "An action in progress.", [
        Example.new(:spinner, "Sizes and labels", :card)
      ]),
      Section.new(:skeleton, "Skeleton", "A placeholder while content loads.", [
        Example.new(:skeleton, "Placeholder", :page)
      ]),
      Section.new(:menu, "Menu", "Actions in a floating panel.", [
        Example.new(:row_menu, "Actions", :card)
      ]),
      Section.new(:popover, "Popover", "Content anchored to a trigger.", [
        Example.new(:open_popover, "Anchored content", :card)
      ]),
      Section.new(:tooltip, "Tooltip", "A short hint on hover and keyboard focus.", [
        Example.new(:tooltip, "Tooltips", :card)
      ]),
      Section.new(:dialog, "Dialog", "A focused task, with a sheet layout on phones.", [
        Example.new(:modal_dialog, "Modal", :card),
        Example.new(:dialog_fit, "Mobile dialog", :card),
        Example.new(:dialog_heights, "Mobile height options", :card),
        Example.new(:dialog_context, "Compact dialog", :card)
      ]),
      Section.new(:toast, "Toast", "Brief feedback after an action.", [
        Example.new(:toast, "Brief feedback", :card)
      ]),
      Section.new(:collapsible, "Collapsible", "Content that expands in place.", [
        Example.new(:collapsible, "Expandable content", :page)
      ]),
      Section.new(:emoji, "Emoji picker", "Search, categories and skin tones.", [
        Example.new(:html, "Emoji picker", :card)
      ])
    ].sort_by { |section| [ section.id == :foundations ? 0 : 1, section.title.downcase ] }
  end

  def self.description(id) = sections.find { |section| section.id == id }.description
  def self.builders = sections.flat_map(&:builders).uniq
end
