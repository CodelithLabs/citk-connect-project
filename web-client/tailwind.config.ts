import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic":
          "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
      },
      colors: {
        'bg-dark': '#121212',
        'surface-dark': '#1E1E1E',
        'on-background': '#FFFFFF',
        'on-surface': '#FFFFFF',
        'on-surface-variant': '#BDBDBD',
        'g-blue': '#4285F4',
        'g-red': '#DB4437',
        'g-yellow': '#F4B400',
        'g-green': '#0F9D58',
      }
    },
  },
  plugins: [],
};
export default config;
