# Webflow Markdown: Markdown -> Webflow RTF

A simple tool that lets you write content in Markdown and convert it to HTML that's ready to paste into Webflow.

Optional: preview hacky article styling overrides with the toggle button above.

## The Problem

Using the built-in Webflow editor for long articles can be a hassle. It's not optimized for writing extensive content, and it can slow down your workflow.

## The Solution

This tool allows you to:

- Write your articles in Markdown using your preferred editor and setup
- Preview how it will look with your Webflow site's CSS (specifically configured for enso.no)
- Generate clean HTML that you can copy and paste directly into Webflow

The preview in this tool uses the same CSS as enso.no, ensuring that what you see is what you'll get when you paste the HTML into your Webflow site.

## How to Use

- Write your content in the Markdown editor on the left
- See the live preview on the right
- When you're satisfied, copy the generated HTML from the preview (just click on it!)
- Paste it into the Webflow editor

The tool is pre-configured with the enso.no stylesheet at the time of coding, but if that becomes stale you can replace it with a fresh link using the input on top.

## Features

- Live preview with your site's actual CSS
- Simple, distraction-free interface
- Supports all standard Markdown syntax
- Customizable content class name to match your Webflow setup
- Option to use different stylesheets for different sites

## Live Demo

You can use the hosted version of this tool at:

[https://webflow-markdown-preview.onrender.com](https://webflow-markdown-preview.onrender.com)

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v12 or higher recommended)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [Elm](https://guide.elm-lang.org/install/elm.html) (0.19.1)

### Installation

- Clone this repository

  ```
  git clone https://github.com/ensolabs/webflow-markdown.git
  cd webflow-markdown
  ```

- Install dependencies
  ```
  npm install
  # or
  yarn
  ```

### Development

To run the development server with hot reloading:

```
npm run dev
# or
yarn dev
```

### Building for Production

To build the application for production:

```
npm run build
# or
yarn build
```

This will generate the production files in the `public_html` directory.

### Running the Production Build

To serve the production build:

```
npm start
# or
yarn start
```

### Deployment

The project is set up to automatically deploy to GitHub Pages when changes are pushed to the master branch. The deployment is handled by a GitHub Actions workflow.

## Built With

- [Elm](https://elm-lang.org/) - A delightful language for reliable web applications
- [pablohirafuji/elm-markdown](https://package.elm-lang.org/packages/pablohirafuji/elm-markdown/latest/) - Markdown parsing in Elm

## License

This project is licensed under the MIT License - see the package.json file for details.

## Author

Christian Ekrem <christian@enso.no>
