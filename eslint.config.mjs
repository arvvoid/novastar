import path from 'node:path';
import { fileURLToPath } from 'node:url';

import js from '@eslint/js';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import importPlugin from 'eslint-plugin-import';
import unusedImports from 'eslint-plugin-unused-imports';
import eslintConfigPrettier from 'eslint-config-prettier';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const customImportResolver = path.resolve(__dirname, 'eslint-plugin-import-resolver.js');

export default [
  {
    linterOptions: {
      reportUnusedDisableDirectives: 'off',
    },
  },
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/coverage/**',
      '**/bak/**',
      '**/obj/**',
      'packages/native/bin/**',
      'packages/native/decompiled/**',
      'packages/native/dll/**',
      'packages/native/generated/Session.ts',
      '**/*.spec.ts',
      '**/*.test.ts',
      'packages/screen/src/ScanboardData.test.ts',
    ],
  },
  js.configs.recommended,
  {
    files: ['**/*.ts', '**/*.mts', '**/*.cts'],
    languageOptions: {
      parser: tsParser,
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        BigInt: 'readonly',
        Buffer: 'readonly',
        BufferEncoding: 'readonly',
        NodeJS: 'readonly',
        clearTimeout: 'readonly',
        console: 'readonly',
        global: 'readonly',
        setTimeout: 'readonly',
        WebAssembly: 'readonly',
      },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      import: importPlugin,
      'unused-imports': unusedImports,
    },
    settings: {
      'import/resolver': {
        typescript: {
          alwaysTryTypes: true,
          project: 'packages/*/tsconfig.json',
        },
        [customImportResolver]: { someConfig: 1 },
      },
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      'no-undef': 'off',
      'no-redeclare': 'off',
      'no-unused-expressions': ['error', { allowShortCircuit: true, allowTernary: true }],
      'no-useless-constructor': 'off',
      'no-shadow': 'off',
      '@typescript-eslint/no-shadow': 'error',
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          args: 'after-used',
          argsIgnorePattern: '^_',
          ignoreRestSiblings: true,
        },
      ],
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-empty-interface': 'off',
      '@typescript-eslint/no-empty-object-type': 'off',
      '@typescript-eslint/no-duplicate-enum-values': 'off',
      'sort-imports': ['error', { ignoreDeclarationSort: true, ignoreCase: true }],
      'unused-imports/no-unused-imports': 'error',
      'no-restricted-syntax': [
        'error',
        {
          selector: 'ForInStatement',
          message:
            'for..in loops iterate over the entire prototype chain. Prefer Object.keys/Object.values/Object.entries.',
        },
        {
          selector: 'LabeledStatement',
          message: 'Labels make code harder to maintain and understand.',
        },
        {
          selector: 'WithStatement',
          message: '`with` is not allowed in strict mode and makes code unpredictable.',
        },
      ],
    },
  },
  {
    files: ['packages/native/generated/**/*.ts', 'packages/native/lib/common/**/*.ts'],
    rules: {
      camelcase: 'off',
      'no-bitwise': 'off',
      'no-nested-ternary': 'off',
      '@typescript-eslint/no-shadow': 'warn',
      '@typescript-eslint/no-unused-vars': 'warn',
    },
  },
  eslintConfigPrettier,
];
