#!/usr/bin/env node
/**
 * Seeds the articles table from handbook_final.json using the Supabase service role key.
 * Run from the web/ directory: node scripts/seed-db.mjs
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { createClient } from '@supabase/supabase-js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const jsonPath = join(projectRoot, 'backend', 'handbook_final.json');

// Read env from .env.local
import { readFileSync as rf } from 'fs';
const envPath = join(__dirname, '..', '.env.local');
const envContent = rf(envPath, 'utf8');
const env = Object.fromEntries(
  envContent.split('\n')
    .filter(line => line.includes('='))
    .map(line => {
      const idx = line.indexOf('=');
      return [line.slice(0, idx).trim(), line.slice(idx + 1).trim()];
    })
);

const SUPABASE_URL = env['NEXT_PUBLIC_SUPABASE_URL'];
const SERVICE_ROLE_KEY = env['SUPABASE_SERVICE_ROLE_KEY'];

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const raw = JSON.parse(readFileSync(jsonPath, 'utf8'));
const articles = Array.isArray(raw) ? raw : raw.articles ?? Object.values(raw);

console.log(`Read ${articles.length} articles from handbook_final.json`);

// Clear existing data
const { error: truncateError } = await supabase.from('articles').delete().neq('id', '00000000-0000-0000-0000-000000000000');
if (truncateError) {
  console.error('Error clearing articles:', truncateError.message);
  process.exit(1);
}
console.log('Cleared existing articles.');

// Insert in batches of 50
const BATCH = 50;
let inserted = 0;
for (let i = 0; i < articles.length; i += BATCH) {
  const batch = articles.slice(i, i + BATCH).map(a => ({
    chapter_id: a.chapter_id ?? null,
    chapter_title: a.chapter_title ?? null,
    section_id: a.section_id ?? null,
    section_title: a.section_title ?? null,
    sub_section_id: a.sub_section_id ?? null,
    sub_section_title: a.sub_section_title ?? null,
    title: a.title ?? null,
    body_text: a.body_text ?? null,
    content_type: a.content_type ?? null,
    page_approx: a.page_approx != null ? Number(a.page_approx) : null,
    institution: a.institution ?? null,
  }));

  const { error } = await supabase.from('articles').insert(batch);
  if (error) {
    console.error(`Batch ${i / BATCH + 1} error:`, error.message);
    process.exit(1);
  }
  inserted += batch.length;
  console.log(`Inserted ${inserted}/${articles.length}`);
}

console.log(`Done! Inserted ${inserted} articles.`);
