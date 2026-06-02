port module Main exposing (main)

import Base64
import Browser exposing (Document)
import Bytes.Encode as Encode
import Constants exposing (htmlOutputId, stylesheetOverrideContent)
import Flate
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Lazy as Lazy
import Http
import Markdown.Parser as Markdown
import Markdown.Renderer
import Process
import Task
import Url



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
        [ Lazy.lazy stylesheetOverride model.addStylesheetOverride
        , appContainer
            [ logoSection
            , headerSection model
            , mainContent model
            , copySuccessToast model.showCopySuccess
            , footerSection
            ]
        ]
    }



-- COMPONENTS


appContainer : List (Html msg) -> Html msg
appContainer content =
    Html.div [ Attr.class "flex flex-col h-screen bg-gray-50" ] content


logoSection : Html Msg
logoSection =
    Html.div [ Attr.class "bg-white p-2 pb-4 " ]
        [ Html.img [ Attr.src "Logo.svg", Attr.width 100 ] [] ]


footerSection : Html Msg
footerSection =
    Html.div [ Attr.class "text-center text-sm pt-4" ]
        [ Html.a [ Attr.href "https://enso.no", Attr.target "_blank" ] [ Html.text "Made with ❤️ by Ensō" ] ]


headerSection : Model -> Html Msg
headerSection model =
    Html.div [ Attr.class "bg-slate-200 p-4 pt-8" ]
        [ Html.div [ Attr.class "flex flex-wrap gap-4 mb-2" ]
            [ inputWithLabel "Stylesheet URL:"
                (Maybe.withDefault "" model.stylesheet)
                UpdateStylesheet
                [ injectStylesheet model.stylesheet ]
            , inputWithLabel "Content class name(s):"
                model.contentClassName
                UpdateContentClassName
                []
            ]
        , Html.div [ Attr.class "flex gap-2 justify-end mt-4" ]
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
    Html.div [ Attr.class "flex flex-1 overflow-hidden p-4 gap-4 flex-col sm:flex-row" ]
        [ if model.showEditor then
            columnPanel "Markdown Input" <|
                markdownEditor model.markdownInput

          else
            Html.text ""
        , columnPanel "Webflow RTF Preview (click to copy)" <|
            htmlPreview model
        ]



-- HELPER COMPONENTS


inputWithLabel : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
inputWithLabel labelText inputValue onChange additionalElements =
    Html.div [ Attr.class "flex-1 min-w-[250px]" ]
        ([ Html.div [ Attr.class "mb-1 text-sm font-medium" ] [ Html.text labelText ]
         , Html.input
            [ Attr.class "w-full px-3 py-2 border rounded bg-white focus:outline-none focus:ring-2 focus:ring-blue-300"
            , Attr.value inputValue
            , Events.onInput onChange
            , Attr.placeholder labelText
            ]
            []
         ]
            ++ additionalElements
        )


toggleButton : Bool -> String -> String -> msg -> Html msg
toggleButton isActive enableText disableText onClickMsg =
    Html.div
        [ Attr.class "px-4 py-2 rounded-full text-sm cursor-pointer transition-colors bg-slate-600 hover:bg-slate-800 text-white"
        , Events.onClick onClickMsg
        ]
        [ Html.text
            (if isActive then
                disableText

             else
                enableText
            )
        ]


columnPanel : String -> Html msg -> Html msg
columnPanel title content =
    Html.div [ Attr.class "flex flex-1 flex-col min-w-[300px] overflow-hidden pt-2" ]
        [ Html.h2 [ Attr.class "text-lg font-semibold mb-2" ] [ Html.text title ]
        , Html.div [ Attr.class "flex-1 border rounded overflow-hidden" ] [ content ]
        ]


markdownEditor : String -> Html Msg
markdownEditor markdownInput =
    Html.textarea
        [ Attr.class "outline-none w-full h-full p-4 font-mono resize-none"
        , Attr.value markdownInput
        , Events.onInput UpdateMarkdown
        , Attr.autofocus True
        ]
        []


htmlPreview : Model -> Html Msg
htmlPreview model =
    Html.div
        [ Attr.class (model.contentClassName ++ " w-full h-full p-4 overflow-auto cursor-pointer")
        , Events.onClick CopyToClipboard
        , Attr.id htmlOutputId
        ]
        [ parseMarkdown model.markdownInput ]


parseMarkdown : String -> Html msg
parseMarkdown rawMarkdown =
    case
        rawMarkdown
            |> Markdown.parse
            |> Result.mapError
                (List.map Markdown.deadEndToString >> String.join "\n")
            |> Result.andThen (\ast -> Markdown.Renderer.render customRenderer ast)
    of
        Ok rendered ->
            Html.div [] rendered

        Err errors ->
            Html.text errors


customRenderer : Markdown.Renderer.Renderer (Html msg)
customRenderer =
    let
        default =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { default
        | codeBlock =
            \{ body, language } ->
                let
                    lang =
                        case language of
                            Just l ->
                                "&lang=" ++ l

                            Nothing ->
                                ""

                    src =
                        "https://codimg.alwaysdata.net/code.svg?input="
                            --                        "http://localhost:8100/code.svg?input="
                            ++ encodeCodeBlock body
                            ++ lang
                in
                Html.img [ Attr.src src ] []
    }


encodeCodeBlock : String -> String
encodeCodeBlock =
    Encode.string
        >> Encode.encode
        >> Flate.deflate
        >> Base64.fromBytes
        >> Maybe.withDefault "invalid data"
        >> String.replace "+" "_"


copySuccessToast : Bool -> Html msg
copySuccessToast showCopySuccess =
    if showCopySuccess then
        Html.div
            [ Attr.class "fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 p-4 bg-white rounded shadow-lg z-50" ]
            [ Html.text "Copied to clipboard – you can paste it into your Webflow page." ]

    else
        Html.text ""


injectStylesheet : Maybe String -> Html msg
injectStylesheet stylesheet =
    case stylesheet of
        Just url ->
            Html.node "link"
                [ Attr.href url
                , Attr.rel "stylesheet"
                ]
                []

        Nothing ->
            Html.text ""


stylesheetOverride : Bool -> Html Msg
stylesheetOverride addStylesheetOverride =
    if addStylesheetOverride then
        Html.node "style" [] [ Html.text stylesheetOverrideContent ]

    else
        Html.text ""
