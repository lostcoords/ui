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
        Example.new(:reading_japanese, "Japanese reading", :page)
      ]),
      Section.new(:motion, "Motion", "Shared motion settings and feedback tied to real interaction states.", [
        Example.new(:motion_controls, "Hover and press", :card),
        Example.new(:motion_feedback, "Label and icon feedback", :card)
      ]),
      Section.new(:button, "Button", "Actions, links and native Rails forms.", [
        Example.new(:button, "Default", :card),
        Example.new(:button_options, "Variants", :card),
        Example.new(:button_sizes, "Sizes", :card),
        Example.new(:button_with_icon, "With an icon", :card),
        Example.new(:button_custom_icon, "Custom icons and content", :card),
        Example.new(:button_loading, "Loading", :card),
        Example.new(:button_disabled, "Disabled", :card),
        Example.new(:button_link, "As a link", :card),
        Example.new(:button_form, "HTTP actions", :card)
      ]),
      Section.new(:copy_button, "Copy button", "Copy text or a live field value with animated confirmation and accessible feedback.", [
        Example.new(:copy_button, "Labels, icons and disabled controls", :card),
        Example.new(:copy_button_source, "Copy from an element", :card),
        Example.new(:copy_button_localized, "Translated labels", :card)
      ]),
      Section.new(:icon_button, "Icon button", "An icon action with an accessible label.", [
        Example.new(:icon_button, "Shapes and sizes", :card)
      ]),
      Section.new(:badge, "Badge", "Labels, counts and status.", [
        Example.new(:badge, "Tones", :card),
        Example.new(:status_pill, "Status", :card),
        Example.new(:eyebrow, "Eyebrow", :card)
      ]),
      Section.new(:pill, "Pill", "Filters and navigation.", [
        Example.new(:pill, "Filters", :card),
        Example.new(:pill_links, "Navigation", :card),
        Example.new(:pill_disabled, "Disabled and ghost", :card)
      ]),
      Section.new(:avatar, "Avatar", "Initials or an image representing a person.", [
        Example.new(:avatar, "Initials and images", :card)
      ]),
      Section.new(:avatar_stack, "Avatar stack", "A group of people in a compact row.", [
        Example.new(:avatar_stack, "A group of people", :card)
      ]),
      Section.new(:icon_badge, "Icon badge", "A small container for a symbol.", [
        Example.new(:icon_badge, "Icon badge", :card)
      ]),
      Section.new(:medallion, "Medallion", "A symbol with a little more presence.", [
        Example.new(:medallion, "Tones and sizes", :card)
      ]),
      Section.new(:card, "Card", "Surfaces for related content.", [
        Example.new(:card, "Default", :page),
        Example.new(:card_dense, "Dense", :page),
        Example.new(:card_link, "Linked card", :page),
        Example.new(:surface, "Surface", :page),
        Example.new(:form_card, "Form card", :page)
      ]),
      Section.new(:empty_state, "Empty state", "A starting point when there is no content yet.", [
        Example.new(:empty_state, "Empty state", :page)
      ]),
      Section.new(:field, "Field", "Labels, controls and validation that stay connected.", [
        Example.new(:field, "Label and hint", :page),
        Example.new(:invalid_field, "Validation", :page),
        Example.new(:rails_field, "Rails forms", :page),
        Example.new(:form_actions, "Form actions", :page)
      ]),
      Section.new(:input, "Input", "Native single-line input.", [
        Example.new(:input, "Sizes", :page),
        Example.new(:input_states, "Disabled and read-only", :page)
      ]),
      Section.new(:select, "Select", "Native options with consistent sizing.", [
        Example.new(:select, "Native select", :page)
      ]),
      Section.new(:textarea, "Textarea", "Room for more than one line.", [
        Example.new(:textarea, "Textarea", :page)
      ]),
      Section.new(:form_alert, "Form alert", "Feedback inside a form.", [
        Example.new(:form_alert, "Error", :card),
        Example.new(:form_notice, "Notice", :card)
      ]),
      Section.new(:segmented, "Segmented control", "Mutually exclusive choices.", [
        Example.new(:segmented, "Mutually exclusive choices", :card),
        Example.new(:segmented_form, "Form values and reset", :card)
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
      Section.new(:dialog, "Dialog", "A focused task, with a sheet layout on phones.", [
        Example.new(:modal_dialog, "Modal", :card)
      ]),
      Section.new(:sheet, "Sheet", "A draggable dialog with configurable heights.", [
        Example.new(:sheet, "Fit to content", :card),
        Example.new(:sheet_detents, "Multiple heights", :card)
      ]),
      Section.new(:toast, "Toast", "Brief feedback after an action.", [
        Example.new(:toast, "Brief feedback", :card)
      ]),
      Section.new(:disclosure, "Disclosure", "Content that expands in place.", [
        Example.new(:disclosure, "Expandable content", :page)
      ]),
      Section.new(:emoji, "Emoji picker", "Search, categories and skin tones.", [
        Example.new(:html, "Emoji picker", :card)
      ])
    ]
  end

  def self.description(id) = sections.find { |section| section.id == id }.description
  def self.builders = sections.flat_map(&:builders).uniq
end
