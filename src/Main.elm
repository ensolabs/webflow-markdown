port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, div, h1, input, label, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, name, placeholder, rel, style, value)
import Html.Events exposing (..)
import Markdown



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = \_ -> init placeholderMarkdown "https://cdn.prod.website-files.com/6214c874431e5f067201a098/css/enso-70214f.d81fe3c7e.css" "rich-text article-body w-richtext"
        , update = update
        , subscriptions = subscriptions
        , view = view "Markdown to HTML"
        }



-- MODEL


type alias Model =
    { markdownInput : String
    , stylesheet : Maybe String
    , contentClassName : String
    }


init : String -> String -> String -> ( Model, Cmd msg )
init markdown stylesheetUrl containerClassName =
    ( Model markdown (Just stylesheetUrl) containerClassName
    , Cmd.none
    )



-- UPDATE


type Msg
    = UpdateMarkdown String
    | UpdateStylesheet String
    | UpdateContentClassName String
    | CopyToClipboard


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMarkdown newText ->
            ( { model | markdownInput = newText }
            , Cmd.none
            )

        UpdateStylesheet url ->
            if String.isEmpty url then
                ( { model | stylesheet = Nothing }
                , Cmd.none
                )

            else
                ( { model | stylesheet = Just url }
                , Cmd.none
                )

        UpdateContentClassName newClassName ->
            ( { model | contentClassName = newClassName }
            , Cmd.none
            )

        CopyToClipboard ->
            ( model, triggerCopy htmlOutputId )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- PORTS


port triggerCopy : String -> Cmd msg



-- VIEW


view : String -> Model -> Document Msg
view title model =
    { title = title
    , body =
        [ topBar
            [ stylesheetInput model.stylesheet
            , customInput
                model.contentClassName
                "Content class name(s):"
                UpdateContentClassName
                []
            ]
        , div
            [ style "width" "100vw"
            , style "height" "100%"
            , style "display" "flex"
            , style "align-items" "flex-start"
            , style "justify-content" "center"
            , style "overflow" "hidden"
            ]
            [ -- Left column: Markdown input
              panel "Markdown Input"
                [ textarea
                    ([ style "width" "100%"
                     , style "font-family" "monospace"
                     , style "font-size" "1rem"
                     , style "display" "flex"
                     , style "field-sizing" "normal"
                     , value model.markdownInput
                     , onInput UpdateMarkdown
                     , autofocus True
                     ]
                        ++ contentStylesFullFlexHeight
                    )
                    []
                ]

            -- Right column: HTML output
            , panel "HTML Preview"
                [ div
                    ([ class model.contentClassName
                     , style "cursor" "pointer"
                     , onClick CopyToClipboard
                     , id htmlOutputId
                     ]
                        ++ contentStylesFullFlexHeight
                    )
                  <|
                    Markdown.toHtml
                        Nothing
                        model.markdownInput
                ]
            ]
        ]
    }


panel : String -> List (Html msg) -> Html msg
panel title content =
    div
        [ style "flex" "1"
        , style "padding" "1rem"
        , style "min-width" "300px"
        , style "min-height" "calc(100vh - 100px)"
        , style "flex-direction" "column"
        , style "display" "flex"
        ]
        (h1 [ revertStyle ] [ text title ] :: content)


topBar : List (Html msg) -> Html msg
topBar content =
    div
        [ revertStyle
        , style "display" "flex"
        , style "gap" "1rem"
        , style "background-color" "rgba(255, 255, 255, 0.8)"
        , style "justify-content" "space-between"
        , style "align-items" "center"
        , style "position" "sticky"
        , style "top" "0"
        , style "z-index" "100"
        , style "padding" "1rem"
        ]
        content


revertStyle : Html.Attribute msg
revertStyle =
    style "all" "revert"


contentStyles : List (Html.Attribute msg)
contentStyles =
    [ style "border" "1px solid #ccc"
    , style "border-radius" "0.5rem"
    , style "padding" "1rem"
    , style "box-sizing" "border-box"
    , style "width" "100%"
    ]


contentStylesFullFlexHeight : List (Html.Attribute msg)
contentStylesFullFlexHeight =
    [ style "flex" "1"
    , style "min-height" "100%"
    ]
        ++ contentStyles


customInput : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
customInput inputValue labelText onInputHandler additionalElements =
    label [ name labelText, style "flex" "1", style "width" "100%" ]
        ([ div [] [ text labelText ]
         , input
            (contentStyles
                ++ [ value inputValue
                   , onInput onInputHandler
                   , placeholder labelText
                   , style "overflow-x" "scroll"
                   , style "min-width" "360px"
                   , style "padding" "0 0.5rem"
                   ]
            )
            []
         ]
            ++ additionalElements
        )


stylesheetInput : Maybe String -> Html Msg
stylesheetInput stylesheet =
    customInput
        (Maybe.withDefault "" stylesheet)
        "Stylesheet URL:"
        UpdateStylesheet
        [ case stylesheet of
            Just url ->
                node "link"
                    [ href url
                    , rel "stylesheet"
                    ]
                    []

            Nothing ->
                text ""
        ]



-- CONSTANTS


htmlOutputId : String
htmlOutputId =
    "html-output"


placeholderMarkdown : String
placeholderMarkdown =
    String.trimLeft
        """
## The best tool for note-taking?

The one you have close at hand. ReMarkable this, vintage inherited bio-dynamic paper that – it'll do you no good what-so-ever if it's not readily available when you need it. I've spent way too much time trying to find the "ideal" solution for keeping track of notes and ideas through my workday. But all I _really_ need is this:

- To jot down new notes and ideas _fast!_.
- To search through previous notes equally fast.

## What could possibly be better...

...Than to create notes from the comfort of your beloved terminal that's already open anyway, and to do super-fast full text fuzzy searches in all you've ever written? Did I mention it's fast?

If you prefer to write things down on paper, and never ever **a)** lose your precious Moleskin or **b)** forget to _always_ bring said Moleskin at all times, then bless your soul. Read no further, go on with your made up life. If not, please [do enjoy](https://github.com/cekrem/ripnote):

```
$ yarn global add ripnote
```

or

```
$ npm install -g ripnote
```

#### And then:

![ripnote](https://github.com/cekrem/ripnote/raw/main/screenshot.gif)

"""
