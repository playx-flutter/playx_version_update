// Publishes ../CHANGELOG.md as a docs page, so the changelog is written once.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const source = join(here, '..', '..', 'CHANGELOG.md');
const target = join(here, '..', 'docs', 'changelog.md');

const body = readFileSync(source, 'utf8')
  // The page has its own title.
  .replace(/^# Changelog\s*/i, '')
  // Entries are written for pub.dev; `<` and `{` would be read as MDX.
  .replace(/</g, '&lt;')
  .replace(/\{/g, '&#123;');

const front = `---
id: changelog
title: Changelog
sidebar_position: 99
---

`;

writeFileSync(target, front + body);
console.log(`Wrote ${target}`);
