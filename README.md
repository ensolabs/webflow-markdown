# Webflow Markdown: Markdown -> Webflow compatible RTF

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

## Code Blocks: Markdown → Syntax-Highlighted SVG

Code blocks are the one thing Webflow's editor handles poorly. Pasting a raw `<pre><code>` block into the Webflow editor tends to lose formatting, mangle indentation, and strip syntax highlighting — and there's no reliable way to get nicely highlighted code to survive the round-trip.

Our workaround: **we don't paste code as text at all — we paste it as an image.**

Every fenced code block in your Markdown is replaced with an `<img>` tag that points at a small Go service which renders the code as a syntax-highlighted SVG on the fly. Because it's just an image, it survives copy/paste into Webflow perfectly and looks identical everywhere.

### How it works

1. **In the browser (this Elm app):** for each code block we take the source text and
   - encode it to UTF-8 bytes,
   - `deflate`-compress it (keeps the URL short even for long snippets),
   - Base64-encode it, and
   - URL-percent-encode the result.

   The block then becomes an image whose `src` is the rendering service plus the encoded code and an optional language hint:

   ```
   https://codimg.alwaysdata.net/code.svg?input=<deflate+base64+urlencoded>&lang=<language>
   ```

   (See `viewCodeBlockImg` / `encodeCodeBlock` in `src/Main.elm`.)

2. **On the backend (Go + Chroma):** the service reverses the pipeline — URL-decode, Base64-decode, inflate — to recover the original source, then runs it through [Chroma](https://github.com/alecthomas/chroma) for syntax highlighting using the supplied `lang` (with auto-detection as a fallback). It returns an SVG with the correct `Content-Type`, so the browser renders it inline.

The compression step matters: code blocks can be long, and deflating before Base64 keeps the resulting URL well within practical length limits. URL-encoding the Base64 output is what makes it safe to drop straight into a query string.

### Why an image instead of HTML?

- It pastes into Webflow cleanly — no lost indentation, no stripped tags, no editor reformatting.
- Highlighting is rendered server-side, so it looks the same regardless of Webflow's own styles.
- The code is fully encoded in the URL, so the rendering service is stateless — there's nothing to store.

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

[https://webflow.enso.no](https://webflow.enso.no)

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
- [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/) - Markdown parsing in Elm

## License

This project is licensed under the MIT License - see the package.json file for details.

## Author

Christian Ekrem <christian@enso.no>
