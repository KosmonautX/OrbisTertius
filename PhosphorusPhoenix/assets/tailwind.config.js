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
      container: {
        center: true,
      },

      height: {
        '732': '46rem',//Mobile Height 
        '800': '50rem',//Desktop Height
        '760': '47rem',//Desktop Image Height
        '400': '25rem',//comment height in mobile View
      },

      width: {
        '443': '27rem',//Width in Mobile 
        '600': '38rem',//Widhh in Desktop
        '700': '43rem',
        '800': '50rem',
        '1200': '75rem',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
