module Lostcoords::Ui
  module FormHelper
    SEGMENTED_BASE =
      "inline-flex items-center gap-1 rounded-2xl bg-paper-2 p-1"

    SEGMENTED_TAB_BASE =
      "inline-flex items-center justify-center gap-1.5 whitespace-nowrap " \
      "min-h-11 rounded-xl border-0 bg-transparent " \
      "px-4 py-2 font-body text-sm font-medium cursor-pointer no-underline " \
      "text-ink-2 hover:text-ink " \
      "aria-selected:bg-paper aria-selected:text-ink " \
      "aria-pressed:bg-paper aria-pressed:text-ink " \
      "aria-[current]:not-aria-[current=false]:bg-paper aria-[current]:not-aria-[current=false]:text-ink " \
      "transition-[background-color,color,box-shadow,transform] duration-[150ms] ease-out " \
      "active:scale-[0.96] disabled:opacity-40 disabled:pointer-events-none " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    SEGMENTED_TAB_ACTIVE = "bg-paper text-ink hover:text-ink"

    INPUT_BASE =
      "w-full max-w-full min-w-0 " \
      "px-3 " \
      "font-body text-base bg-(--field-bg,var(--paper-2)) text-ink placeholder:text-ink-3 " \
      "border border-transparent rounded-2xl outline-none " \
      "transition-[border-color,box-shadow] duration-150 ease-out " \
      "focus:shadow-(--focus-halo) " \
      "aria-invalid:border-berry aria-invalid:shadow-[0_0_0_3px_color-mix(in_oklab,var(--berry)_16%,transparent)]"

    FIELD_BASE = "min-w-0 mb-5 last:mb-0 has-aria-invalid:[&>label]:text-berry"

    FIELD_LABEL_BASE =
      "block font-body text-sm font-semibold text-ink-3 " \
      "mb-2.5 transition-colors duration-[120ms] ease-out"

    FORM_ACTIONS_BASE = "flex flex-wrap items-center justify-end gap-2"

    # The toast's surface (shared/_toast), set in the flow: the tone lives in the icon, not the fill.
    FORM_ALERT_BASE =
      "flex items-start gap-2 mb-4 py-3 px-4 rounded-2xl bg-(--glass-hud-solid) text-(--glass-hud-ink) text-sm font-semibold " \
      "motion-safe:animate-alert-in"

    FORM_ALERT_ICONS = {
      error: [ "exclamation-circle", "text-berry" ],
      notice: [ "check-circle", "text-leaf" ]
    }.freeze

    def segmented_class(extra: nil)
      tw(SEGMENTED_BASE, extra)
    end

    def segmented_tab_class(active: false, extra: nil)
      tw(SEGMENTED_TAB_BASE, (SEGMENTED_TAB_ACTIVE if active), extra)
    end

    def input_class(size: :base, extra: nil)
      tw(INPUT_BASE, TailwindHelper::CONTROL_SIZES.fetch(size.to_sym, TailwindHelper::CONTROL_SIZES[:base]), extra)
    end

    def dropdown_trigger_class(size: :base, extra: nil)
      button_class(variant: :secondary, size: size, block: true,
        extra: tw("justify-start text-start ps-5 pe-4 gap-3 [&_.caret]:ms-auto [&_.caret]:shrink-0", extra))
    end

    def select_class(size: :base, extra: nil)
      tw(input_class(size: size), "select-control rounded-full ps-5 pe-11 cursor-pointer hover:bg-paper-3", extra)
    end

    def textarea_class(extra: nil)
      tw(INPUT_BASE, "min-h-28 py-2.5 resize-y", extra)
    end

    def field_class(extra: nil)
      tw(FIELD_BASE, extra)
    end

    def field_label_class(extra: nil)
      tw(FIELD_LABEL_BASE, extra)
    end

    def form_actions_class(extra: nil)
      tw(FORM_ACTIONS_BASE, extra)
    end

    def form_alert_class(extra: nil)
      tw(FORM_ALERT_BASE, extra)
    end

    def form_alert_icon(tone: :error)
      name, color = FORM_ALERT_ICONS.fetch(tone.to_sym, FORM_ALERT_ICONS[:error])
      heroicon name, variant: :mini, options: { class: tw("size-5 shrink-0", color), "aria-hidden": "true" }
    end
  end
end
