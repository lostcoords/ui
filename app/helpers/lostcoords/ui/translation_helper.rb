module Lostcoords::Ui
  module TranslationHelper
    private

    def lc_t(key, **options)
      I18n.translate(key, **options)
    end
  end
end
