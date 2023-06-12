// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      fontFamily: {
        poppins: ["Poppins"],
      },

      padding: {
        2.8: "44.8rem",
      },

      inset: {
        "60px": "60px",
      },

      spacing: {
        "66px": "66px",
      },

      height: {
        900: "56rem",
        128: "32rem",
        272: "17rem",
      },
      borderRadius: {
        19: "19px",
      },
      margin: {
        "550px": "550px",
      },
      maxHeight: {
        500: "31rem",
      },
    },
  },

  darkMode: "class",

  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
