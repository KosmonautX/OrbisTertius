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

      padding: {
        '2.8': '44.8rem',
      },


      height: {
        '900': '56rem',
        '128': '32rem',

      }

    },
  },

  darkMode: "class",

  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms')
  ]
}
