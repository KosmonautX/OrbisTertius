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
      width: {
        '577': '36rem',
        '416': '26rem',
      },
      height: {
        '704': '44rem',
        '688': '43rem',
        '784': '49rem',
        '848': '53rem',
        '880': '55rem',
      },
      borderRadius: {
        'xxl': '20px',
      },
      spacing: {
        '55px': '55px',
        '60px': '60px',
      },

      padding: {
        2.8: "44.8rem",
      },

      inset: {
        "64px": "64px",
        "311px": "311px",
        "560px": "560px",
      },

      height: {
        900: "56rem",
        128: "32rem",
        272: "17rem",
        428: "26rem",
      },
      borderRadius: {
        25: "25px",
      },
      margin: {
        "550px": "550px",
        "600px": "600px",
      },
      maxHeight: {
        464: "29rem",
      },
    },
  },

  darkMode: "class",

  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
