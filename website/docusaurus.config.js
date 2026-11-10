// @ts-check
import { themes as prismThemes } from 'prism-react-renderer';

const repo = 'https://github.com/playx-flutter/playx_version_update';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Playx Version Update',
  tagline: 'Keep your Flutter users on the latest version of your app',
  favicon: 'img/logo.svg',

  url: 'https://playx-flutter.github.io',
  baseUrl: '/playx_version_update/',
  organizationName: 'playx-flutter',
  projectName: 'playx_version_update',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  markdown: {
    hooks: { onBrokenMarkdownLinks: 'throw' },
  },

  i18n: { defaultLocale: 'en', locales: ['en'] },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          editUrl: `${repo}/edit/main/website/`,
        },
        blog: false,
        theme: { customCss: './src/css/custom.css' },
      }),
    ],
  ],

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      /** @type {import('@easyops-cn/docusaurus-search-local').PluginOptions} */
      ({
        hashed: true,
        indexBlog: false,
        docsRouteBasePath: '/docs',
        highlightSearchTermsOnTargetPage: true,
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/screenshots/screenshot4.jpg',
      colorMode: { respectPrefersColorScheme: true },
      navbar: {
        title: 'Playx Version Update',
        logo: { alt: 'Playx Version Update', src: 'img/logo.svg' },
        items: [
          { type: 'docSidebar', sidebarId: 'docs', position: 'left', label: 'Docs' },
          { to: '/docs/migration/migrating-to-2', label: 'Migration', position: 'left' },
          {
            href: 'https://playx-flutter.github.io/playx_version_update/api/',
            label: 'API reference',
            position: 'left',
          },
          { to: '/docs/changelog', label: 'Changelog', position: 'left' },
          { href: 'https://pub.dev/packages/playx_version_update', label: 'pub.dev', position: 'right' },
          { href: repo, label: 'GitHub', position: 'right' },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              { label: 'Getting started', to: '/docs/getting-started/installation' },
              { label: 'Guides', to: '/docs/guides/check-for-updates' },
              { label: 'Migration to 2.0', to: '/docs/migration/migrating-to-2' },
            ],
          },
          {
            title: 'Package',
            items: [
              { label: 'pub.dev', href: 'https://pub.dev/packages/playx_version_update' },
              { label: 'Changelog', to: '/docs/changelog' },
              { label: 'Issues', href: `${repo}/issues` },
            ],
          },
          {
            title: 'More',
            items: [
              { label: 'GitHub', href: repo },
              { label: 'Sourcya', href: 'https://sourcya.io' },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Sourcya. MIT licensed.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['dart', 'kotlin', 'yaml', 'bash', 'xml-doc'],
      },
    }),
};

export default config;
