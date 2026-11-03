module Showcase
  Example = Data.define(:specimen, :calls, :stage) do
    def initialize(specimen:, calls:, stage: :card)
      super(specimen:, calls: calls.is_a?(Hash) ? calls : { value: calls }, stage:)
    end

    def builders = calls.values.map { |call| call[/\A\w+[?!]?/].to_sym }
  end

  Section = Data.define(:id, :title, :examples) do
    def builders = examples.flat_map(&:builders).uniq
  end

  DIALOG_CHROME = {
    trigger: "button_class(variant: :secondary)",
    actions: "form_actions_class",
    cancel: "button_class(variant: :ghost)",
    confirm: "button_class(variant: :danger)"
  }.freeze

  def self.matrix(specimen, builder, stage: :card, across: nil, **options)
    spread = across ? options.delete(across) : [ nil ]
    combinations(options).map do |fixed|
      calls = spread.to_h do |value|
        arguments = across ? fixed.merge(across => value) : fixed
        [ across ? value : :value, "#{builder}(#{arguments.map { |key, argument| "#{key}: #{argument.inspect}" }.join(", ")})" ]
      end
      Example.new(specimen:, calls:, stage:)
    end
  end

  def self.combinations(options)
    return [ {} ] if options.empty?

    options.values.then { |first, *rest| first.product(*rest) }.map { |values| options.keys.zip(values).to_h }
  end

  def self.example(specimen, calls, stage: :card) = Example.new(specimen:, calls:, stage:)

  def self.sections
    ui = Lostcoords::Ui
    [
      Section.new(:buttons, "Buttons", [
        *matrix(:button, "button_class", across: :size, variant: ui::ButtonHelper::BUTTON_VARIANTS.keys, size: ui::ButtonHelper::BUTTON_SIZES.keys),
        example(:button, "button_class(variant: :accent, block: true)"),
        *matrix(:icon_button, "icon_button_class", across: :size, shape: ui::ButtonHelper::ICON_BUTTON_SHAPES.keys, size: ui::ButtonHelper::ICON_BUTTON_SIZES.keys)
      ]),
      Section.new(:badges, "Badges and pills", [
        *matrix(:badge, "badge_class", across: :tone, tone: ui::BadgeHelper::BADGE_TONES.keys),
        *matrix(:status_pill, "status_pill_class", across: :tone, tone: ui::BadgeHelper::STATUS_PILL_TONES.keys),
        example(:eyebrow, "eyebrow_class"),
        *matrix(:pill, "pill_class", across: :active, active: [ false, true ]),
        example(:pill, "pill_class(ghost: true)"),
        example(:pill, "pill_class(size: :sm)"),
        example(:pill_toggles, { row: "pill_row_class", pill: "pill_class" }),
        example(:pill_links, { row: "pill_row_class", pill: "pill_class(size: :sm)" }),
        *matrix(:medallion, "icon_medallion_class", across: :tone, size: ui::BadgeHelper::ICON_MEDALLION_SIZES.keys, tone: ui::BadgeHelper::ICON_MEDALLION_TONES.keys)
      ]),
      Section.new(:avatars, "Avatars and icon badges", [
        *matrix(:avatar, "avatar_class", across: :size, size: ui::BadgeHelper::AVATAR_SIZES.keys),
        example(:avatar, "avatar_class(ink: true, linked: true)"),
        example(:avatar_stack, { stack: "avatar_stack_class", row: "avatar_stack_row_class", avatar: "avatar_class" }),
        example(:avatar_stack, { stack: "avatar_stack_class(compact: true)", row: "avatar_stack_row_class", avatar: "avatar_class" }),
        *matrix(:icon_badge, "icon_badge_class", across: :size, size: ui::BadgeHelper::ICON_BADGE_SIZES.keys)
      ]),
      Section.new(:cards, "Cards", [
        *matrix(:card, "card_class", stage: :page, across: :dense, interactive: [ false, true ], dense: [ false, true ]),
        example(:card, "card_surface_class(extra: \"p-5\")", stage: :page),
        *matrix(:card, "form_card_class", stage: :page, padding: ui::CardHelper::FORM_CARD_PADDINGS.keys),
        example(:empty_state, { card: "form_card_class(padding: :empty)", empty: "empty_state_class" }, stage: :page)
      ]),
      Section.new(:fields, "Fields", [
        example(:field, { field: "field_class", label: "field_label_class", input: "input_class" }, stage: :page),
        example(:invalid_field, { field: "field_class", label: "field_label_class", input: "input_class" }, stage: :page),
        *matrix(:input, "input_class", stage: :page, across: :size, size: ui::TailwindHelper::CONTROL_SIZES.keys),
        example(:select, "select_class", stage: :page),
        example(:select, "select_class(size: :sm)", stage: :page),
        example(:textarea, "textarea_class", stage: :page),
        example(:dropdown_trigger, "dropdown_trigger_class", stage: :page),
        example(:form_actions, { actions: "form_actions_class", cancel: "button_class(variant: :ghost)", submit: "button_class(variant: :accent)" }, stage: :page)
      ]),
      Section.new(:alerts, "Form alerts", [
        example(:html, "render(\"lostcoords/ui/components/form_alert\", message: \"That name is already taken.\")"),
        example(:html, "render(\"lostcoords/ui/components/form_alert\", tone: :notice, message: \"Saved.\")"),
        example(:form_alert, { alert: "form_alert_class", icon: "form_alert_icon(tone: :notice)" })
      ]),
      Section.new(:segmented, "Segmented controls", [
        example(:segmented, { bar: "segmented_class", tab: "segmented_tab_class", current: "segmented_tab_class(active: true)" }),
        example(:segmented_tabs, { bar: "segmented_class", tab: "segmented_tab_class" })
      ]),
      Section.new(:feedback, "Spinner and skeleton", [
        *matrix(:spinner, "spinner_class", across: :size, size: ui::FeedbackHelper::SPINNER_SIZES.keys),
        example(:html, "render(\"lostcoords/ui/components/spinner\", size: :lg)"),
        example(:skeleton, "skeleton_class(extra: \"h-4 w-48\")", stage: :page),
        example(:html, "render(\"lostcoords/ui/components/skeleton\", class: \"h-10 w-full\")", stage: :page)
      ]),
      Section.new(:menus, "Menus", [
        example(:row_menu, { popover: "menu_popover_class", option: "menu_option_class", danger: "menu_option_class(tone: :danger)", trigger: "icon_button_class(shape: :circle)" }),
        example(:sort_menu, { popover: "menu_popover_class(align: :start)", option: "menu_option_class", danger: "menu_option_class(tone: :danger)", trigger: "button_class(variant: :secondary, size: :sm)" }),
        example(:open_popover, "popover_class(extra: \"static block w-64 p-4\")"),
        example(:open_popover, "menu_popover_class(align: :center, extra: \"static translate-x-0\")")
      ]),
      Section.new(:glass, "Glass surfaces", [
        *matrix(:glass, "glass_class", shape: ui::GlassHelper::GLASS_SHAPES.keys),
        example(:glass, "glass_class(shape: :bar, thick: true)")
      ]),
      Section.new(:dialogs, "Dialogs", [
        example(:confirm_dialog, { dialog: "dialog_class", **DIALOG_CHROME }),
        example(:modal_dialog, { dialog: "dialog_class(extra: \"sm:w-[min(94vw,40rem)]\")", **DIALOG_CHROME }),
        example(:context_dialog, {
          dialog: "dialog_class(:context)", menu: "menu_popover_class", option: "menu_option_class(tone: :danger)",
          **DIALOG_CHROME, trigger: "icon_button_class(shape: :circle)"
        }),
        example(:surface, "dialog_surface_class(extra: \"p-5\")", stage: :page)
      ]),
      Section.new(:sheet, "Sheet", [
        example(:sheet, {
          data: "sheet_data({ confirm_dialog_target: \"dialog\" }, detents: \"medium large\")",
          dialog: "dialog_class",
          row: "sheet_row_class",
          label: "sheet_row_label_class",
          text: "sheet_text_input_class",
          datetime: "sheet_datetime_input_class",
          chip: "sheet_chip_class",
          current: "sheet_chip_class(active: true)",
          member: "sheet_chip_class(member: true)",
          avatar: "avatar_class(size: :sm)",
          trigger: "button_class(variant: :secondary)",
          done: "button_class(variant: :accent, block: true)"
        })
      ]),
      Section.new(:disclosure, "Disclosure", [
        example(:disclosure, "card_class(dense: true, extra: \"disclosure-animated\")", stage: :page)
      ]),
      Section.new(:toast, "Toast", [
        example(:toast, { toast: "glass_class(shape: :hud, extra: \"flex items-center gap-2 py-3 px-4 text-sm font-semibold\")", icon: "form_alert_icon(tone: :notice)", trigger: "button_class(variant: :secondary)" })
      ]),
      Section.new(:emoji, "Emoji picker", [
        example(:html, "render(\"lostcoords/ui/components/emoji_picker\", form: showcase_form, field: :emoji, quick: %w[🥝 🍣 🍜 ☕], label: \"Choose an emoji\", catalog_url: \"emoji-catalog.html\")"),
        example(:value, "emoji_picker_groups.map { |group| group[:icon] }.join"),
        example(:value, "emoji_picker_count"),
        example(:value, "emoji_picker_version"),
        example(:value, "emoji_picker_search_name(\"🥝\")"),
        example(:value, "emoji_picker_search_text(\"🥝\")"),
        example(:value, "emoji_picker_search_labels(\"🥝\")"),
        example(:value, "emoji_picker_toneable?(\"👍\")")
      ]),
      Section.new(:merging, "Class merging", [
        example(:value, "tw(\"p-2 p-4\", nil, [\"m-1\"])")
      ])
    ]
  end

  def self.builders = sections.flat_map(&:builders).uniq
end
