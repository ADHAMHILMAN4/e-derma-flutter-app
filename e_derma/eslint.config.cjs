import { defineConfig } from 'eslint';

export default defineConfig({
  languageOptions: {
    parserOptions: {
      ecmaVersion: 2020,
      sourceType: 'module',
    },
  },
  globals: {
    // You can define global variables here if needed
  },
  rules: {
    'no-unused-vars': 'warn',
    'no-console': 'off',
  },
});
