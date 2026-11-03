module Lostcoords::Ui
  module TranslationHelper
    private

    def lc_t(key, **options)
      I18n.translate(key, **options, locale: lc_locale)
    end

    def lc_locale
      I18n.locale
    end
  end
end
