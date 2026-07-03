import I18n from 'i18n-js';
import en from '../locales/en.json';
import ur from '../locales/ur.json';

I18n.translations = {
  en: en,
  ur: ur,
};

I18n.fallbacks = true;
I18n.defaultLocale = 'en';

export const setLanguage = (lang) => {
  I18n.locale = lang;
};

export const t = (key, options = {}) => {
  return I18n.t(key, options);
};

export default I18n;
