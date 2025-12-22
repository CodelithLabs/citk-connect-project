/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
 
    // Or if using `src` directory:
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'bg-dark': 'var(--bg-dark)',
        'surface-dark': 'var(--surface-dark)',
        'sidebar-bg': 'var(--sidebar-bg)',
        'on-background': 'var(--md-sys-color-on-background)',
        'on-surface-variant': 'var(--md-sys-color-on-surface-variant)',
        'g-blue': 'var(--g-blue)',
        'g-red': 'var(--g-red)',
        'g-yellow': 'var(--g-yellow)',
        'g-green': 'var(--g-green)',
      },
      borderRadius: {
        'radius-sm': 'var(--radius-sm)',
        'radius-md': 'var(--radius-md)',
        'radius-lg': 'var(--radius-lg)',
        'radius-full': 'var(--radius-full)',
      }
    },
  },
  plugins: [],
}