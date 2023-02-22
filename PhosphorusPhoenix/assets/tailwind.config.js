// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {
      fontFamily: {
        Poppins: ["Poppins", "sans-serif"],
      },

      height: {
        '900': '56rem',
      }

    },
  },

  darkMode: "class",

  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms')
  ]
}
