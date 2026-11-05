require "unicode/emoji"
require "yaml"
require_relative "translation_helper"

module Lostcoords::Ui
  module EmojiPickerHelper
    include TranslationHelper

    def lc_emoji_picker(form:, field:, label:, catalog_url:, value: nil, quick: [], recent: [], recent_scope: nil, auto_submit: false, **attributes)
      lc_label!(label, :label)
      lc_label!(catalog_url, :catalog_url)
      render "lostcoords/ui/components/emoji_picker", form: form, field: field, label: label, catalog_url: catalog_url, value: value, quick: quick, recent: recent, recent_scope: recent_scope, auto_submit: auto_submit, attributes: attributes
    end

    SEARCH_NAMES_PATH = Lostcoords::Ui.root.join("config/emoji_search_names.yml")
    SEARCH_NAMES_JA_PATH = Lostcoords::Ui.root.join("config/emoji_search_names_ja.yml")
    SEARCH_ALIASES_PATH = Lostcoords::Ui.root.join("config/emoji_search_aliases.yml")

    # Representative glyph for each category's tab in the picker navigation.
    CATEGORY_ICONS = {
      "smileys_emotion" => "😀",
      "people_body" => "🧑",
      "animals_nature" => "🐻",
      "food_drink" => "🍔",
      "travel_places" => "🚗",
      "activities" => "⚽",
      "objects" => "💡",
      "symbols" => "🔣",
      "flags" => "🏁"
    }.freeze

    KANA_DIGRAPHS = {
      "きゃ" => "kya", "きゅ" => "kyu", "きょ" => "kyo",
      "しゃ" => "sha", "しゅ" => "shu", "しょ" => "sho",
      "ちゃ" => "cha", "ちゅ" => "chu", "ちょ" => "cho",
      "にゃ" => "nya", "にゅ" => "nyu", "にょ" => "nyo",
      "ひゃ" => "hya", "ひゅ" => "hyu", "ひょ" => "hyo",
      "みゃ" => "mya", "みゅ" => "myu", "みょ" => "myo",
      "りゃ" => "rya", "りゅ" => "ryu", "りょ" => "ryo",
      "ぎゃ" => "gya", "ぎゅ" => "gyu", "ぎょ" => "gyo",
      "じゃ" => "ja", "じゅ" => "ju", "じょ" => "jo",
      "びゃ" => "bya", "びゅ" => "byu", "びょ" => "byo",
      "ぴゃ" => "pya", "ぴゅ" => "pyu", "ぴょ" => "pyo",
      "ふぁ" => "fa", "ふぃ" => "fi", "ふぇ" => "fe", "ふぉ" => "fo",
      "てぃ" => "ti", "でぃ" => "di", "うぃ" => "wi", "うぇ" => "we", "うぉ" => "wo"
    }.freeze
    KANA_ROMAJI = {
      "あ" => "a", "い" => "i", "う" => "u", "え" => "e", "お" => "o",
      "か" => "ka", "き" => "ki", "く" => "ku", "け" => "ke", "こ" => "ko",
      "さ" => "sa", "し" => "shi", "す" => "su", "せ" => "se", "そ" => "so",
      "た" => "ta", "ち" => "chi", "つ" => "tsu", "て" => "te", "と" => "to",
      "な" => "na", "に" => "ni", "ぬ" => "nu", "ね" => "ne", "の" => "no",
      "は" => "ha", "ひ" => "hi", "ふ" => "fu", "へ" => "he", "ほ" => "ho",
      "ま" => "ma", "み" => "mi", "む" => "mu", "め" => "me", "も" => "mo",
      "や" => "ya", "ゆ" => "yu", "よ" => "yo",
      "ら" => "ra", "り" => "ri", "る" => "ru", "れ" => "re", "ろ" => "ro",
      "わ" => "wa", "を" => "wo", "ん" => "n",
      "が" => "ga", "ぎ" => "gi", "ぐ" => "gu", "げ" => "ge", "ご" => "go",
      "ざ" => "za", "じ" => "ji", "ず" => "zu", "ぜ" => "ze", "ぞ" => "zo",
      "だ" => "da", "ぢ" => "ji", "づ" => "zu", "で" => "de", "ど" => "do",
      "ば" => "ba", "び" => "bi", "ぶ" => "bu", "べ" => "be", "ぼ" => "bo",
      "ぱ" => "pa", "ぴ" => "pi", "ぷ" => "pu", "ぺ" => "pe", "ぽ" => "po",
      "ぁ" => "a", "ぃ" => "i", "ぅ" => "u", "ぇ" => "e", "ぉ" => "o",
      "ゃ" => "ya", "ゅ" => "yu", "ょ" => "yo", "ゎ" => "wa"
    }.freeze
    CATEGORY_KEYS = {
      "Smileys & Emotion" => "smileys_emotion",
      "People & Body" => "people_body",
      "Animals & Nature" => "animals_nature",
      "Food & Drink" => "food_drink",
      "Travel & Places" => "travel_places",
      "Activities" => "activities",
      "Objects" => "objects",
      "Symbols" => "symbols",
      "Flags" => "flags"
    }.freeze

    def lc_emoji_picker_groups
      Lostcoords::Ui::EmojiPickerHelper.groups.map do |group|
        group.merge(name: lc_t("lostcoords.ui.emoji_picker.categories.#{group[:key]}", default: group[:name]))
      end
    end

    def lc_emoji_picker_count
      lc_emoji_picker_groups.sum { |group| group[:emojis].size }
    end

    def lc_emoji_picker_version
      "#{Unicode::Emoji::EMOJI_VERSION}-#{I18n.locale}-search-v3"
    end

    def lc_emoji_picker_search_text(emoji)
      Lostcoords::Ui::EmojiPickerHelper.search_text_for(emoji)
    end

    def lc_emoji_picker_search_name(emoji)
      Lostcoords::Ui::EmojiPickerHelper.search_name_for(emoji, locale: I18n.locale)
    end

    def lc_emoji_picker_search_labels(emoji)
      Lostcoords::Ui::EmojiPickerHelper.search_labels_for(emoji).join("|")
    end

    def lc_emoji_picker_toneable?(emoji)
      Lostcoords::Ui::EmojiPickerHelper.toneable?(emoji)
    end

    def self.groups
      @groups ||= Unicode::Emoji::LIST.filter_map do |name, subgroups|
        emojis = subgroups.values.flatten.uniq.reject { |emoji| skin_tone_variant?(emoji) }
        next if emojis.empty?

        key = category_key(name)
        { key: key, name:, icon: CATEGORY_ICONS[key], emojis: emojis.freeze }
      end.freeze
    end

    def self.search_text_for(emoji)
      search_index.fetch(emoji) { emoji }
    end

    # Primary, human-facing name. Prefers the reader's language so the preview
    # and accessible label read naturally; falls back across languages.
    def self.search_name_for(emoji, locale: :en)
      if locale.to_s.start_with?("ja")
        japanese_search_names[emoji]&.first || search_names[emoji] || emoji
      else
        search_names[emoji] || japanese_search_names[emoji]&.first || emoji
      end
    end

    def self.search_labels_for(emoji)
      [
        search_names[emoji],
        *Array(japanese_search_names[emoji]),
        *Array(curated_aliases[emoji])
      ].compact_blank.uniq
    end

    def self.search_index
      @search_index ||= begin
        index = Hash.new { |hash, key| hash[key] = [] }

        Unicode::Emoji::LIST.each do |name, subgroups|
          category_key = category_key(name)
          category_terms = [ name, category_key.tr("_", " ") ]

          subgroups.each do |subgroup, emojis|
            subgroup_terms = [ subgroup, subgroup.tr("_-", " ") ]

            emojis.each do |emoji|
              next if skin_tone_variant?(emoji)

              labels = search_labels_for(emoji)
              index[emoji].concat([
                emoji,
                *labels,
                *romaji_terms(labels),
                *category_terms,
                *subgroup_terms
              ])
            end
          end
        end

        index.transform_values { |terms| terms.compact_blank.uniq.join(" ").downcase }.freeze
      end
    end

    def self.search_names
      @search_names ||= YAML.load_file(SEARCH_NAMES_PATH).freeze
    end

    def self.japanese_search_names
      @japanese_search_names ||= YAML.load_file(SEARCH_NAMES_JA_PATH).freeze
    end

    def self.curated_aliases
      @curated_aliases ||= YAML.load_file(SEARCH_ALIASES_PATH).transform_values { |terms| Array(terms) }.freeze
    end

    # Romaji equivalents for any kana-bearing terms, so a Japanese name can be
    # found by typing on a Latin keyboard (e.g. "neko" finds 🐱).
    def self.romaji_terms(terms)
      Array(terms).filter_map do |term|
        next unless contains_kana?(term)

        kana_to_romaji(term)
      end.compact_blank
    end

    def self.contains_kana?(term)
      term.to_s.match?(/[぀-ヿ]/)
    end

    def self.kana_to_romaji(term)
      kana = term.to_s.each_char.map do |char|
        codepoint = char.ord
        codepoint.between?(0x30A1, 0x30F6) ? (codepoint - 0x60).chr(Encoding::UTF_8) : char
      end.join

      result = +""
      index = 0
      while index < kana.length
        char = kana[index]
        pair = kana[index, 2]

        if char == "っ"
          next_pair = KANA_DIGRAPHS[kana[index + 1, 2]]
          next_char = next_pair || KANA_ROMAJI[kana[index + 1]]
          result << next_char[0] if next_char.present?
          index += 1
        elsif char == "ー"
          index += 1
        elsif KANA_DIGRAPHS[pair]
          result << KANA_DIGRAPHS[pair]
          index += 2
        elsif KANA_ROMAJI[char]
          result << KANA_ROMAJI[char]
          index += 1
        else
          result << char
          index += 1
        end
      end

      result
    end

    def self.skin_tone_variant?(emoji)
      (emoji.codepoints & Unicode::Emoji::EMOJI_MODIFIERS).any?
    end

    # A "simple" modifier base: one base codepoint (optionally with a variation
    # selector) drawn from Unicode's modifier-base set. We deliberately skip ZWJ
    # sequences (families, couples) where applying a single skin tone is wrong.
    def self.toneable?(emoji)
      @toneable ||= {}
      @toneable.fetch(emoji) do
        @toneable[emoji] = begin
          codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }
          codepoints.length == 1 && Unicode::Emoji::EMOJI_MODIFIER_BASES.include?(codepoints.first)
        end
      end
    end

    def self.category_key(name)
      CATEGORY_KEYS.fetch(name) { name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") }
    end
  end
end
