import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    root: __dirname,
    resolveAlias: {
      tailwindcss: path.join(__dirname, 'node_modules/tailwindcss'),
      'tw-animate-css': path.join(__dirname, 'node_modules/tw-animate-css'),
      shadcn: path.join(__dirname, 'node_modules/shadcn'),
    },
  },
  experimental: {
    optimizePackageImports: [
      '@hugeicons/react',
      '@hugeicons/core-free-icons',
    ],
  },
};

export default nextConfig;
