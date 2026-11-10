import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';

import styles from './index.module.css';

const features = [
  {
    icon: '🔎',
    title: 'Finds new versions',
    text: 'Reads Google Play, the App Store and the Mac App Store, or your own backend / Remote Config through pluggable version sources.',
  },
  {
    icon: '📲',
    title: 'Native in-app updates',
    text: 'Google Play immediate and flexible updates on Android, with download progress and install handling.',
  },
  {
    icon: '🎨',
    title: 'Update UI you can style',
    text: 'A platform-adaptive dialog and a full-screen page. Change texts, styles, release notes, buttons and dismissal.',
  },
  {
    icon: '🔒',
    title: 'Minimum versions',
    text: 'Force an update below a minimum version, per platform, from the store description or from your own config.',
  },
  {
    icon: '⏰',
    title: 'Later and Skip',
    text: 'Remember "Later" and "Skip this version" with pluggable storage, so users are not nagged on every launch.',
  },
  {
    icon: '📊',
    title: 'Events and error codes',
    text: 'Analytics callbacks for every step and stable error codes with retry hints, so you can react to each failure.',
  },
];

const screenshots = [
  ['screenshot4.jpg', 'Android update dialog'],
  ['screenshot6.jpg', 'Release notes and a forced update'],
  ['screenshot3.jpg', 'iOS update dialog'],
  ['screenshot5.jpg', 'Full-screen update page'],
  ['screenshot7.png', 'Flexible in-app update on Android'],
  ['screenshot2.jpg', 'Immediate in-app update on Android'],
];

const sample = `final result = await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  uiOptions: PlayxUpdateUIOptions(
    showReleaseNotes: true,
    dismissButtonText: 'Later',
  ),
  // Remember "Later" and let users skip a version.
  reminderOptions: PlayxUpdateReminderOptions(allowSkipVersion: true),
);`;

function Hero() {
  return (
    <header className={styles.hero}>
      <div className="container">
        <img
          className={styles.heroLogo}
          src={useBaseUrl('/img/logo.svg')}
          alt=""
          width="84"
          height="84"
        />
        <Heading as="h1" className={styles.heroTitle}>
          Playx Version Update
        </Heading>
        <p className={styles.heroTagline}>
          Keep your Flutter users on the latest version of your app. Version checks, a polished
          update UI and native Android in-app updates, in a few lines.
        </p>
        <div className={styles.buttons}>
          <Link className="button button--primary button--lg" to="/docs/getting-started/installation">
            Get started
          </Link>
          <Link className="button button--secondary button--lg" to="/docs/migration/migrating-to-2">
            Migrating to 2.0
          </Link>
        </div>
        <p className={styles.platforms}>Android · iOS · macOS · custom sources for Windows and Linux</p>
      </div>
    </header>
  );
}

function Features() {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.grid}>
          {features.map((feature) => (
            <div key={feature.title} className={styles.card}>
              <div className={styles.cardIcon}>{feature.icon}</div>
              <Heading as="h3">{feature.title}</Heading>
              <p>{feature.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Sample() {
  return (
    <section className={clsx(styles.section, styles.alt)}>
      <div className="container">
        <div className={styles.sample}>
          <div>
            <Heading as="h2">One call to ask users to update</Heading>
            <p>
              <code>showUpdateDialog</code> checks the store, compares versions and shows the right
              dialog for the platform. Everything else is optional.
            </p>
            <Link to="/docs/getting-started/quick-start">Read the quick start →</Link>
          </div>
          <CodeBlock language="dart">{sample}</CodeBlock>
        </div>
      </div>
    </section>
  );
}

function Gallery() {
  return (
    <section className={styles.section}>
      <div className="container">
        <Heading as="h2" className={styles.center}>
          What your users see
        </Heading>
        <div className={styles.gallery}>
          {screenshots.map(([file, caption]) => (
            <figure key={file} className={styles.shot}>
              <img src={useBaseUrl(`/img/screenshots/${file}`)} alt={caption} loading="lazy" />
              <figcaption>{caption}</figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  return (
    <Layout
      title="Flutter app update library"
      description="Version checks, a customizable update dialog and page, and native Android in-app updates for Flutter."
    >
      <Hero />
      <main>
        <Features />
        <Sample />
        <Gallery />
      </main>
    </Layout>
  );
}
