// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      fontFamily: {
        poppins: ["Poppins"],
      },
      width: {
        '577': '36rem',
        '416': '26rem',
      },

      padding: {
        2.8: "44.8rem",
      },

      inset: {
        "60px": "60px",
        "311px": "311px",
      },

      height: {
        900: "56rem",
        128: "32rem",
        272: "17rem",
        428: "26rem",
      },
      borderRadius: {
        19: "19px",
      },
      margin: {
        "550px": "550px",
      },
      maxHeight: {
        464: "29rem",
      },
    },
  },

  darkMode: "class",

  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
