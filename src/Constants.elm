module Constants exposing (htmlOutputId, stylesheetOverrideContent)

-- CONSTANTS


htmlOutputId : String
htmlOutputId =
    "html-output"


stylesheetOverrideContent : String
stylesheetOverrideContent =
    """
    .article-body {
        line-height: 1.5 !important;
        max-width: 80ch !important;
        margin: 0 auto !important;
        font-size: 100% !important;
        text-rendering: optimizeLegibility !important;
      }

      .article-body h1,
      .article-body h2,
      .article-body h3,
      .article-body h4,
      .article-body h5,
      .article-body h6 {
        margin-top: 2rem !important;
        margin-bottom: 1rem !important;
        line-height: 1.2 !important;
      }
      .article-body h1:first-child,
      .article-body h2:first-child,
      .article-body h3:first-child,
      .article-body h4:first-child,
      .article-body h5:first-child,
      .article-body h6:first-child {
        margin-top: 0 !important;
      }

      .article-body h1 {
        font-size: 2rem !important;
      }
      .article-body h2 {
        font-size: 1.75rem !important;
      }
      .article-body h3 {
        font-size: 1.5rem !important;
      }
      .article-body h4 {
        font-size: 1.25rem !important;
      }
      .article-body h5 {
        font-size: 1.1rem !important;
      }
      .article-body h6 {
        font-size: 1rem !important;
        text-transform: uppercase !important;
      }

      .article-body p {
        margin-bottom: 0.75rem !important;
        margin-top: 0.75rem !important;
      }

      .article-body ul,
      .article-body ol {
        margin-bottom: 1.5rem !important;
        padding-left: 2rem !important;
      }

      .article-body ul li {
        list-style-type: disc !important;
        margin-bottom: 0.5rem !important;
      }

      .article-body ol li {
        list-style-type: decimal !important;
        margin-bottom: 0.5rem !important;
      }

      .article-body blockquote {
        font-style: italic !important;
        padding-left: 1rem !important;
        border-left: 4px solid currentColor !important;
        margin-bottom: 1.5rem !important;
      }

      .article-body pre {
        padding: 1rem !important;
        overflow-x: auto !important;
        border-radius: 5px !important;
        font-size: 0.875rem !important;
      }

      .article-body code {
        font-family: monospace !important;
        background: rgba(0, 0, 0, 0.1) !important;
        padding: 0.2rem 0.4rem !important;
        border-radius: 3px !important;
      }

      .article-body img {
        max-width: 100% !important;
        height: auto !important;
        display: block !important;
        margin: 1.5rem 0 !important;
      }

      /* Responsive adjustments */
      @media (max-width: 768px) {
        .article-body {
          font-size: 90% !important;
        }
        .article-body h1 {
          font-size: 1.75rem !important;
        }
        .article-body h2 {
          font-size: 1.5rem !important;
        }
        .article-body h3 {
          font-size: 1.25rem !important;
        }
      }
    """
