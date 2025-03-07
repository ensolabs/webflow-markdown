port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, div, h1, input, label, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, name, placeholder, rel, style, tabindex, value)
import Html.Events exposing (..)
import Markdown



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init =
            \_ ->
                init
                    placeholderMarkdown
                    "https://cdn.prod.website-files.com/6214c874431e5f067201a098/css/enso-70214f.d81fe3c7e.css"
                    "rich-text article-body w-richtext"
        , update = update
        , subscriptions = subscriptions
        , view = view "Markdown to HTML"
        }



-- MODEL


type alias Model =
    { markdownInput : String
    , stylesheet : Maybe String
    , contentClassName : String
    , showCopySuccess : Bool
    }


init : String -> String -> String -> ( Model, Cmd msg )
init markdown stylesheetUrl containerClassName =
    ( Model markdown (Just stylesheetUrl) containerClassName False
    , Cmd.none
    )



-- UPDATE


type Msg
    = UpdateMarkdown String
    | UpdateStylesheet String
    | UpdateContentClassName String
    | CopyToClipboard
    | CopySuccess


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMarkdown newText ->
            ( { model | markdownInput = newText, showCopySuccess = False }
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

        CopySuccess ->
            ( { model | showCopySuccess = True }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    copySuccess (\_ -> CopySuccess)



-- PORTS


port triggerCopy : String -> Cmd msg


port copySuccess : (() -> msg) -> Sub msg



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
        , div styles.mainLayout
            [ -- Left column: Markdown input
              panel "Markdown Input"
                [ textarea
                    (styles.markdownEditor
                        ++ [ value model.markdownInput
                           , onInput UpdateMarkdown
                           , autofocus True
                           ]
                    )
                    []
                ]

            -- Right column: HTML output
            , panel "HTML Preview"
                [ div
                    (styles.htmlPreview
                        ++ [ class model.contentClassName
                           , onClick CopyToClipboard
                           , id htmlOutputId
                           , tabindex 1
                           , onBlur (UpdateMarkdown model.markdownInput)
                           ]
                    )
                  <|
                    Markdown.toHtml
                        Nothing
                        model.markdownInput
                        ++ (if model.showCopySuccess then
                                [ div styles.copySuccess
                                    [ text "Copied to clipboard!" ]
                                ]

                            else
                                []
                           )
                ]
            ]
        ]
    }


topBar : List (Html msg) -> Html msg
topBar content =
    div styles.topBar content


panel : String -> List (Html msg) -> Html msg
panel title content =
    div styles.flexPanel
        (h1 styles.reset [ text title ] :: content)


customInput : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
customInput inputValue labelText onInputHandler additionalElements =
    label (name labelText :: styles.inputLabel)
        ([ div [] [ text labelText ]
         , input
            (styles.inputField
                ++ [ value inputValue
                   , onInput onInputHandler
                   , placeholder labelText
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



-- STYLES


type alias Style msg =
    List (Html.Attribute msg)


styles :
    { reset : Style msg
    , flex : Style msg
    , column : Style msg
    , fullWidth : Style msg
    , container : Style msg
    , flexGrow : Style msg
    , flexPanel : Style msg
    , contentArea : Style msg
    , topBar : Style msg
    , mainLayout : Style msg
    , inputField : Style msg
    , markdownEditor : Style msg
    , htmlPreview : Style msg
    , inputLabel : Style msg
    , copySuccess : Style msg
    }
styles =
    let
        reset =
            [ style "all" "revert" ]

        flex =
            [ style "display" "flex" ]

        column =
            flex ++ [ style "flex-direction" "column" ]

        fullWidth =
            [ style "width" "100%" ]

        container =
            [ style "border" "1px solid #ccc"
            , style "border-radius" "0.5rem"
            , style "padding" "1rem"
            , style "box-sizing" "border-box"
            ]
                ++ fullWidth

        flexGrow =
            [ style "flex" "1" ]
    in
    { reset = reset
    , flex = flex
    , column = column
    , fullWidth = fullWidth
    , container = container
    , flexGrow = flexGrow
    , flexPanel =
        flexGrow
            ++ column
            ++ [ style "padding" "1rem"
               , style "min-width" "300px"
               , style "min-height" "calc(100vh - 100px)"
               ]
    , contentArea =
        container
            ++ flexGrow
            ++ [ style "min-height" "100%" ]
    , topBar =
        reset
            ++ flex
            ++ [ style "gap" "1rem"
               , style "background-color" "rgba(255, 255, 255, 0.8)"
               , style "justify-content" "space-between"
               , style "align-items" "center"
               , style "position" "sticky"
               , style "top" "0"
               , style "z-index" "100"
               , style "padding" "1rem"
               ]
    , mainLayout =
        [ style "width" "100vw"
        , style "height" "100%"
        ]
            ++ flex
            ++ [ style "align-items" "flex-start"
               , style "justify-content" "center"
               ]
    , inputField =
        container
            ++ [ style "overflow-x" "scroll"
               , style "min-width" "360px"
               , style "padding" "0 0.5rem"
               ]
    , markdownEditor =
        container
            ++ flexGrow
            ++ [ style "font-family" "monospace"
               , style "min-height" "100%"
               , style "height" "100%"
               , style "font-size" "1rem"
               , style "display" "block"
               , style "box-sizing" "border-box"
               , style "resize" "none"
               , style "background" "none"
               , style "field-sizing" "content"
               ]
    , htmlPreview =
        container
            ++ flexGrow
            ++ [ style "min-height" "100%"
               , style "cursor" "pointer"
               , style "position" "relative"
               ]
    , inputLabel =
        style "flex" "1" :: fullWidth
    , copySuccess =
        [ style "position" "absolute"
        , style "top" "0"
        , style "right" "0"
        , style "padding" "1rem"
        , style "background-color" "rgba(255, 255, 255, 0.8)"
        , style "border-radius" "0.5rem"
        , style "z-index" "100"
        ]
    }



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
