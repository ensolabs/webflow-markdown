port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, br, div, h1, input, label, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, name, placeholder, rel, tabindex, value)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Http
import Markdown
import Process
import Task



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
    , showReadme : Bool
    , readmeContent : Maybe String
    }


init : String -> String -> String -> ( Model, Cmd Msg )
init markdown stylesheetUrl containerClassName =
    ( Model markdown (Just stylesheetUrl) containerClassName False True Nothing
    , fetchReadme
    )


fetchReadme : Cmd Msg
fetchReadme =
    Http.get
        { url = "https://raw.githubusercontent.com/cekrem/webflow-markdown-preview/refs/heads/master/README.md"
        , expect = Http.expectString GotReadme
        }



-- UPDATE


type Msg
    = UpdateMarkdown String
    | UpdateStylesheet String
    | UpdateContentClassName String
    | CopyToClipboard
    | CopySuccess
    | ClearCopySuccess
    | ToggleReadme
    | GotReadme (Result Http.Error String)


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
            ( { model | showCopySuccess = True }
            , Process.sleep 1000 |> Task.perform (always ClearCopySuccess)
            )

        ClearCopySuccess ->
            ( { model | showCopySuccess = False }, Cmd.none )

        ToggleReadme ->
            ( { model | showReadme = not model.showReadme }, Cmd.none )

        GotReadme result ->
            case result of
                Ok readmeContent ->
                    ( { model | readmeContent = Just readmeContent }, Cmd.none )

                Err _ ->
                    ( { model | readmeContent = Just "Failed to load README content." }, Cmd.none )



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
        [ mobileCopOut [ class "flex flex-col h-screen justify-center items-center" ]
            [ lazy topBar
                [ stylesheetInput
                    model.stylesheet
                , customInput
                    model.contentClassName
                    "Content class name(s):"
                    UpdateContentClassName
                    []
                , div [ class "absolute right-4 top-2 rounded-full bg-gray-200 px-2 py-1 text-center cursor-pointer", onClick ToggleReadme ]
                    [ text
                        (if model.showReadme then
                            "Close readme"

                         else
                            "Show readme"
                        )
                    ]
                ]
            , div [ class "w-full flex flex-1 sm:overflow-hidden" ]
                [ if model.showReadme then
                    modalPanel "README"
                        [ case model.readmeContent of
                            Just content ->
                                div [ class <| model.contentClassName ++ "items-center" ]
                                    (Markdown.toHtml Nothing content)

                            Nothing ->
                                div [ class "text-center p-4" ] [ text "Loading README..." ]
                        ]

                  else
                    text ""
                , -- Left column: Markdown input
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
                        [ class (model.contentClassName ++ " w-full h-full cursor-pointer")
                        , onClick CopyToClipboard
                        , id htmlOutputId
                        , tabindex 1
                        ]
                      <|
                        (if model.showCopySuccess then
                            [ div [ class "fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 p-4 bg-white/80 rounded shadow-md z-50" ]
                                [ text "Copied to clipboard!" ]
                            ]

                         else
                            []
                        )
                            ++ Markdown.toHtml
                                Nothing
                                model.markdownInput
                            ++ [ br [] [] ]
                    ]
                ]
            ]
        ]
    }


topBar : List (Html msg) -> Html msg
topBar content =
    div [ class "sticky w-full top-0 z-10 h-24 flex justify-between gap-8 items-center p-4 bg-white" ] content


panel : String -> List (Html msg) -> Html msg
panel title content =
    div [ class "w-full sm:w-1/2 p-4 flex flex-col h-[calc(100vh-6rem)] overflow-hidden" ]
        (h1 [ class "mb-2" ] [ text title ]
            :: List.map (\c -> div [ class "flex-1 border rounded p-4 overflow-auto" ] [ c ]) content
        )


modalPanel : String -> List (Html msg) -> Html msg
modalPanel title content =
    div [ class "absolute w-full p-4 flex flex-col h-[calc(100vh-6rem)] overflow-hidden bg-white/95" ]
        (h1 [ class "mb-2" ] [ text title ]
            :: List.map (\c -> div [ class "flex-1 border rounded p-4 overflow-auto" ] [ c ]) content
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


mobileCopOut : List (Html.Attribute msg) -> List (Html msg) -> Html msg
mobileCopOut attributes content =
    div [ class "w-full h-full overflow-hidden" ]
        [ div (class "h-0 w-0 sm:h-full sm:w-full" :: attributes)
            (div [ class "sm:hidden fixed top-0 left-0 w-screen h-screen z-50 flex items-center justify-center bg-white overflow-hidden" ] [ div [] [ text "This app only works on desktop. Please use a desktop browser." ] ]
                :: content
            )
        ]



-- div [ class "sm:hidden fixed top-0 left-0 w-screen h-screen z-50 flex items-center justify-center bg-white overflow-hidden" ] [ div [] [ text "This app only works on desktop. Please use a desktop browser." ] ]
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
