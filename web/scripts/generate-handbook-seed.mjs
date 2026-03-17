#!/usr/bin/env node
/**
 * Generates SQL seed file for the student handbook from handbook_final.json
 * Schema: articles table (chapter_id, chapter_title, section_id, section_title,
 *         sub_section_id, sub_section_title, title, body_text, content_type,
 *         page_approx, institution)
 */

import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..', '..');
const defaultJsonPath = join(projectRoot, 'web', 'seed.txt');
const defaultOutputPath = join(projectRoot, 'web', 'lib', 'supabase', 'seed-handbook.sql');
const jsonPath = process.argv[2] ? join(projectRoot, process.argv[2]) : defaultJsonPath;
const outputPath = process.argv[3] ? join(projectRoot, process.argv[3]) : defaultOutputPath;

/** Escape single quotes for PostgreSQL: ' -> '' */
function escapeSql(str) {
  if (str == null || str === '') return null;
  return String(str).replace(/'/g, "''");
}

/** Convert value to SQL literal - returns NULL for null/undefined */
function toSql(value, escape = true) {
  if (value == null || value === '' || value === 'N/A') return 'NULL';
  const str = String(value);
  if (escape) return `'${escapeSql(str)}'`;
  return `'${str}'`;
}

/** Parse sub_section: "5.1.1 Requirements for Admission" -> { id: "5.1.1", title: "Requirements for Admission" } */
function parseSubSection(subSection) {
  if (!subSection || subSection === 'N/A') return { id: null, title: null };
  const match = subSection.match(/^([\d.]+)\s+(.+)$/);
  if (match) {
    return { id: match[1], title: match[2] };
  }
  return { id: subSection, title: subSection };
}

const data = JSON.parse(readFileSync(jsonPath, 'utf-8'));

const inserts = data.map((article) => {
  const { id: sub_section_id, title: sub_section_title } = parseSubSection(article.sub_section);
  const rawPage = article.metadata?.page_approx;
  const pageApprox = typeof rawPage === 'number' && !isNaN(rawPage) ? rawPage : null;
  const institution = article.metadata?.institution ?? null;

  const chapterId = toSql(article.chapter_id);
  const chapterTitle = toSql(article.chapter_title);
  const sectionId = toSql(article.section_id);
  const sectionTitle = toSql(article.section_title);
  const subSectionId = toSql(sub_section_id);
  const subSectionTitle = toSql(sub_section_title);
  const title = toSql(article.section_title); // Use section_title as display title
  const bodyText = toSql(article.body_text);
  const contentType = toSql(article.content_type);
  const pageApproxSql = pageApprox != null && typeof pageApprox === 'number' ? String(pageApprox) : 'NULL';
  const institutionSql = toSql(institution);

  return `INSERT INTO articles (chapter_id, chapter_title, section_id, section_title, sub_section_id, sub_section_title, title, body_text, content_type, page_approx, institution)
VALUES (${chapterId}, ${chapterTitle}, ${sectionId}, ${sectionTitle}, ${subSectionId}, ${subSectionTitle}, ${title}, ${bodyText}, ${contentType}, ${pageApproxSql}, ${institutionSql});`;
});

const sql = `-- ===============================
-- STUDENT HANDBOOK SEED DATA
-- Generated from ${jsonPath.replace(/\\/g, '/')}
-- Run this in Supabase SQL Editor after schema is applied
-- ===============================

-- Clear existing handbook data (optional - comment out if you want to append)
TRUNCATE TABLE articles RESTART IDENTITY CASCADE;

${inserts.join('\n\n')}
`;

writeFileSync(outputPath, sql, 'utf-8');
console.log(`Generated ${data.length} article inserts -> ${outputPath}`);
