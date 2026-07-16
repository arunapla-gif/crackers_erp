/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        active: '#ff6b6b',
        'active-dark': '#c24141',
        'active-soft': '#fff1f2',
      }
    },
  },
  plugins: [],
}
