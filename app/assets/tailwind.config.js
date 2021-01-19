const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      spacing: {
        '86': '21.5rem', // Chat width
        '125': '31.25rem' // Video player height (mobile)
      },
    },
    customForms: theme => ({
      default: {
        'input, textarea, multiselect, checkbox, radio, select': {
          '&:focus': {
            boxShadow: '0 0 0 3px rgba(254, 178, 178, 0.5)',
            borderColor: theme('colors.red.400'),
          }
        },
        'checkbox, radio': {
          color: theme('colors.red.400'),
        }
      }
    })
  },
  variants: {
    borderWidth: ['responsive', 'first', 'hover', 'focus'],
    backgroundColor: ['responsive', 'hover', 'focus', 'odd', 'even'],
    borderColor: ['responsive', 'hover', 'focus', 'odd', 'even'],
    margin: ['responsive', 'first'],
    opacity: ['responsive', 'hover', 'focus', 'disabled'],
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
  purge: {
    enabled: process.env.NODE_ENV !== 'development',
    content: [
      '../assets/elm/src/*.elm',
      '../lib/**/*.leex',
      '../lib/**/*.eex',
      '../lib/**/*.ex'
    ],
  },
}
