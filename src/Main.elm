port module Main exposing (main)

import Browser exposing (Document)
import Constants exposing (htmlOutputId, stylesheetOverrideContent)
import Html exposing (Html, div, h2, input, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, placeholder, rel, value)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Http
import Markdown
import Process
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view "Markdown to Webflow RTF"
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { markdownInput = ""
      , stylesheet = Just "https://cdn.prod.website-files.com/6214c874431e5f067201a098/css/enso-70214f.d81fe3c7e.css"
      , contentClassName = "rich-text article-body w-richtext"
      , showCopySuccess = False
      , addStylesheetOverride = False
      , showEditor = True
      }
    , fetchReadme
    )



-- MODEL


type alias Model =
    { markdownInput : String
    , stylesheet : Maybe String
    , contentClassName : String
    , showCopySuccess : Bool
    , addStylesheetOverride : Bool
    , showEditor : Bool
    }


fetchReadme : Cmd Msg
fetchReadme =
    Http.get
        { url = "https://raw.githubusercontent.com/ensolabs/webflow-markdown/refs/heads/master/README.md"
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
    | GotReadme (Result Http.Error String)
    | ToggleStylesheetOverride
    | ToggleEditor


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
            , Process.sleep 3000 |> Task.perform (always ClearCopySuccess)
            )

        ClearCopySuccess ->
            ( { model | showCopySuccess = False }, Cmd.none )

        GotReadme result ->
            case result of
                Ok readmeContent ->
                    ( { model | markdownInput = readmeContent }, Cmd.none )

                Err _ ->
                    ( { model | markdownInput = "# Error\n\nFailed to load README content." }, Cmd.none )

        ToggleStylesheetOverride ->
            ( { model | addStylesheetOverride = not model.addStylesheetOverride }, Cmd.none )

        ToggleEditor ->
            ( { model | showEditor = not model.showEditor }, Cmd.none )



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
        [ lazy stylesheetOverride model.addStylesheetOverride
        , appContainer
            [ headerSection model
            , mainContent model
            , copySuccessToast model.showCopySuccess
            ]
        ]
    }



-- COMPONENTS


appContainer : List (Html msg) -> Html msg
appContainer content =
    div [ class "flex flex-col h-screen bg-gray-50" ] content


headerSection : Model -> Html Msg
headerSection model =
    div [ class "bg-white p-4 border-b shadow-sm" ]
        [ div [ class "flex flex-wrap gap-4 mb-2" ]
            [ inputWithLabel "Stylesheet URL:"
                (Maybe.withDefault "" model.stylesheet)
                UpdateStylesheet
                [ injectStylesheet model.stylesheet ]
            , inputWithLabel "Content class name(s):"
                model.contentClassName
                UpdateContentClassName
                []
            ]
        , div [ class "flex gap-2 justify-end mt-4" ]
            [ toggleButton
                model.addStylesheetOverride
                "Add basic GitHub Markdown styling"
                "Remove basic GitHub Markdown styling"
                ToggleStylesheetOverride
            , toggleButton
                model.showEditor
                "Show editor"
                "Hide editor"
                ToggleEditor
            ]
        ]


mainContent : Model -> Html Msg
mainContent model =
    div [ class "flex flex-1 overflow-hidden p-4 gap-4 flex-col sm:flex-row" ]
        [ if model.showEditor then
            columnPanel "Markdown Input" <|
                markdownEditor model.markdownInput

          else
            text ""
        , columnPanel "Webflow RTF Preview (click to copy)" <|
            htmlPreview model
        ]



-- HELPER COMPONENTS


inputWithLabel : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
inputWithLabel labelText inputValue onChange additionalElements =
    div [ class "flex-1 min-w-[250px]" ]
        ([ div [ class "mb-1 text-sm font-medium" ] [ text labelText ]
         , input
            [ class "w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-300"
            , value inputValue
            , onInput onChange
            , placeholder labelText
            ]
            []
         ]
            ++ additionalElements
        )


toggleButton : Bool -> String -> String -> msg -> Html msg
toggleButton isActive enableText disableText onClickMsg =
    div
        [ class "px-4 py-2 rounded-full text-sm cursor-pointer transition-colors bg-gray-200 hover:bg-gray-300"
        , onClick onClickMsg
        ]
        [ text
            (if isActive then
                disableText

             else
                enableText
            )
        ]


columnPanel : String -> Html msg -> Html msg
columnPanel title content =
    div [ class "flex flex-1 flex-col min-w-[300px] overflow-hidden" ]
        [ h2 [ class "text-lg font-semibold mb-2" ] [ text title ]
        , div [ class "flex-1 border rounded overflow-hidden" ] [ content ]
        ]


markdownEditor : String -> Html Msg
markdownEditor markdownInput =
    textarea
        [ class "outline-none w-full h-full p-4 font-mono resize-none"
        , value markdownInput
        , onInput UpdateMarkdown
        , autofocus True
        ]
        []


htmlPreview : Model -> Html Msg
htmlPreview model =
    div
        [ class (model.contentClassName ++ " w-full h-full p-4 overflow-auto cursor-pointer")
        , onClick CopyToClipboard
        , id htmlOutputId
        ]
        [ Markdown.toHtml [] model.markdownInput ]


copySuccessToast : Bool -> Html msg
copySuccessToast showCopySuccess =
    if showCopySuccess then
        div
            [ class "fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 p-4 bg-white rounded shadow-lg z-50" ]
            [ text "Copied to clipboard – you can paste it into your Webflow page." ]

    else
        text ""


injectStylesheet : Maybe String -> Html msg
injectStylesheet stylesheet =
    case stylesheet of
        Just url ->
            node "link"
                [ href url
                , rel "stylesheet"
                ]
                []

        Nothing ->
            text ""


stylesheetOverride : Bool -> Html Msg
stylesheetOverride addStylesheetOverride =
    if addStylesheetOverride then
        node "style" [] [ text stylesheetOverrideContent ]

    else
        text ""
