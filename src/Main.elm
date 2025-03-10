port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, div, h1, input, label, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, name, placeholder, rel, tabindex, value)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
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
        [ div [ class "flex flex-col min-h-screen" ]
            [ lazy topBar
                [ stylesheetInput model.stylesheet
                , customInput
                    model.contentClassName
                    "Content class name(s):"
                    UpdateContentClassName
                    []
                ]
            , div [ class "flex flex-1" ]
                [ -- Left column: Markdown input
                  panel "Markdown Input"
                    [ lazy2 textarea
                        [ class "w-full h-full font-mono resize-none bg-transparent"
                        , value model.markdownInput
                        , onInput UpdateMarkdown
                        , autofocus True
                        ]
                        []
                    ]

                -- Right column: HTML output
                , panel "HTML Preview"
                    [ lazy2 div
                        [ class (model.contentClassName ++ " w-full h-full cursor-pointer relative")
                        , onClick CopyToClipboard
                        , id htmlOutputId
                        , tabindex 1
                        , onBlur (UpdateMarkdown model.markdownInput)
                        ]
                      <|
                        Markdown.toHtml
                            Nothing
                            model.markdownInput
                            ++ (if model.showCopySuccess then
                                    [ div [ class "absolute top-0 margin-auto p-4 bg-white/80 rounded" ]
                                        [ text "Copied to clipboard!" ]
                                    ]

                                else
                                    []
                               )
                    ]
                ]
            ]
        ]
    }


topBar : List (Html msg) -> Html msg
topBar content =
    div [ class "sticky top-0 z-10 flex justify-between gap-8 items-center p-4 bg-white/80" ] content


panel : String -> List (Html msg) -> Html msg
panel title content =
    div [ class "w-1/2 p-4 flex flex-col" ]
        (h1 [ class "mb-2" ] [ text title ]
            :: List.map (\c -> div [ class "flex-1 border rounded p-4" ] [ c ]) content
        )


customInput : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
customInput inputValue labelText onInputHandler additionalElements =
    label [ name labelText, class "flex-1" ]
        ([ div [] [ text labelText ]
         , input
            [ class "w-full px-2 py-1 border rounded"
            , value inputValue
            , onInput onInputHandler
            , placeholder labelText
            ]
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
