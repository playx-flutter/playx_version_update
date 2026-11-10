// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    'intro',
    {
      type: 'category',
      label: 'Getting started',
      collapsed: false,
      items: ['getting-started/installation', 'getting-started/quick-start'],
    },
    {
      type: 'category',
      label: 'Guides',
      collapsed: false,
      items: [
        'guides/check-for-updates',
        'guides/update-dialog-and-page',
        'guides/customizing-the-ui',
        'guides/minimum-version',
        'guides/version-sources',
        'guides/app-ids-and-store-urls',
        'guides/opening-the-store',
        'guides/later-and-skip',
        'guides/events',
        'guides/network-and-errors',
        'guides/android-in-app-updates',
        'guides/ios-and-macos',
        'guides/testing',
      ],
    },
    'troubleshooting',
    {
      type: 'category',
      label: 'Migration',
      collapsed: false,
      items: ['migration/migrating-to-2'],
    },
    'changelog',
  ],
};

export default sidebars;
