port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, br, div, h1, input, label, node, text, textarea)
import Html.Attributes exposing (autofocus, class, href, id, name, placeholder, rel, value)
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
    , addStylesheetOverride : Bool
    , showEditor : Bool
    }


init : String -> String -> String -> ( Model, Cmd Msg )
init markdown stylesheetUrl containerClassName =
    ( Model markdown (Just stylesheetUrl) containerClassName False False Nothing False True
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
        [ mobileCopOut [ class "flex flex-col h-screen justify-center items-center" ]
            [ lazy stylesheetOverride model.addStylesheetOverride
            , lazy topBar
                [ stylesheetInput
                    model.stylesheet
                , customInput
                    model.contentClassName
                    "Content class name(s):"
                    UpdateContentClassName
                    []
                , buttons
                    [ button ToggleReadme
                        [ text
                            (if model.showReadme then
                                "Close readme"

                             else
                                "Show readme"
                            )
                        ]
                    , button ToggleStylesheetOverride
                        [ text
                            (if model.addStylesheetOverride then
                                "Disable stylesheet override"

                             else
                                "Enable stylesheet override"
                            )
                        ]
                    , button ToggleEditor
                        [ text
                            (if model.showEditor then
                                "Hide editor"

                             else
                                "Show editor"
                            )
                        ]
                    ]
                ]
            , div [ class "w-full flex flex-1 overflow-hidden justify-center" ]
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
                , if model.showEditor then
                    -- Left column: Markdown input
                    panel "Markdown Input"
                        [ lazy2 textarea
                            [ class "outline-none w-full h-full font-mono resize-none bg-transparent"
                            , value model.markdownInput
                            , onInput UpdateMarkdown
                            , autofocus True
                            ]
                            []
                        ]

                  else
                    text ""

                -- Right column: HTML output
                , panel "HTML Preview (click to copy)"
                    [ lazy2 div
                        [ class (model.contentClassName ++ " w-full h-full cursor-pointer")
                        , onClick CopyToClipboard
                        , id htmlOutputId
                        ]
                      <|
                        Markdown.toHtml
                            Nothing
                            model.markdownInput
                            ++ br [] []
                            :: (if model.showCopySuccess then
                                    [ div [ class "fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 p-4 bg-white/80 rounded shadow-md z-50" ] [ text "Copied to clipboard!" ]
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
    div [ class "sticky w-full top-0 z-10 h-32 flex justify-between gap-8 items-end p-4 bg-white" ] content


panel : String -> List (Html msg) -> Html msg
panel title content =
    div [ class "min-w-[50%] p-4 flex flex-col h-[calc(100vh-8rem)] overflow-hidden" ]
        (h1 [ class "mb-2" ] [ text title ]
            :: List.map (\c -> div [ class "flex-1 border rounded p-4 overflow-auto" ] [ c ]) content
        )


modalPanel : String -> List (Html msg) -> Html msg
modalPanel title content =
    div [ class "w-full absolute p-4 flex flex-1 flex-col h-[calc(100vh-8rem)] overflow-hidden bg-white/95" ]
        (h1 [ class "mb-2" ] [ text title ]
            :: List.map (\c -> div [ class "flex-1 border rounded p-4 overflow-auto" ] [ c ]) content
        )


customInput : String -> String -> (String -> msg) -> List (Html msg) -> Html msg
customInput inputValue labelText onInputHandler additionalElements =
    withLabel labelText <|
        input
            [ class "w-full px-2 py-1 border rounded"
            , value inputValue
            , onInput onInputHandler
            , placeholder labelText
            ]
            []
            :: additionalElements


withLabel : String -> List (Html msg) -> Html msg
withLabel labelText content =
    label [ name labelText, class "flex-1" ]
        (div [] [ text labelText ] :: content)


buttons : List (Html msg) -> Html msg
buttons content =
    div [ class "absolute top-2 right-2 left-2 flex gap-2 justify-around" ] content


button : a -> List (Html a) -> Html a
button onClickMsg content =
    div [ class "rounded-full bg-gray-200 px-4 py-2 text-sm text-center cursor-pointer", onClick onClickMsg ] content


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


stylesheetOverride : Bool -> Html Msg
stylesheetOverride addStylesheetOverride =
    if addStylesheetOverride then
        node "style" [] [ text stylesheetOverrideContent ]

    else
        text ""


mobileCopOut : List (Html.Attribute msg) -> List (Html msg) -> Html msg
mobileCopOut attributes content =
    div [ class "w-full h-full overflow-hidden" ]
        [ div (class "h-0 w-0 sm:h-full sm:w-full" :: attributes)
            (div [ class "sm:hidden fixed top-0 left-0 w-screen h-screen z-50 flex items-center justify-center bg-white overflow-hidden text-center p-4 text-lg" ] [ div [] [ text "This app only works on desktop. Please use a desktop browser." ] ]
                :: content
            )
        ]



-- CONSTANTS


htmlOutputId : String
htmlOutputId =
    "html-output"


placeholderMarkdown : String
placeholderMarkdown =
    String.trimLeft
        """
        ## Hvorfor snakke om Elm i 2025?

I en verden dominert av React, Vue og Svelte kan det virke merkelig å løfte frem Elm – et nisje-språk som har eksistert siden 2012, men som nesten har færre releases siden da enn React har på et år. Men nettopp nå, når frontend-utviklingen blir stadig mer kompleks, og hvor klientene gjør tunge løft som før hørte hjemme på andre siden av et API-kall, er det verdt å se nærmere på hva Elm gjør riktig.

## Hva er Elm?

Elm er et funksjonelt programmeringsspråk spesielt designet for webapplikasjoner. Her er nøkkelforskjellene fra moderne JavaScript-rammeverk:

- **Ingen runtime-feil** – Når koden kompilerer, kan den kjøre uten uventede krasj
- **Fullstendig håndtering av all mulig state** – Kompilatoren hjelper deg med alle grensetilfeller
- **Forutsigbar arkitektur** – [The Elm Architecture](https://guide.elm-lang.org/architecture/) (TEA) gir en klar struktur som skalerer godt
- **Automatisk versjonshåndtering** – Kompilatoren oppdager breaking changes

---

## React vs. Elm: Samme retning, ulik tilnærming

Det er fascinerende å se hvordan React har utviklet seg de siste årene:

- React introduserte hooks for å håndtere state mer funksjonelt
- Redux (inspirert av Elm) ble standard for kompleks håndtering av state
- TypeScript (sterk typing) ble nesten obligatorisk for seriøse prosjekter
- React Server Components isolerer sideeffekter på serversiden

**Men det er en viktig forskjell:** React _anbefaler_ funksjonell programmering og immutabilitet, mens Elm _krever_ det. I React kan du fortsatt mutere variabler og state, blande paradigmer, og skape runtime-feil. I Elm er det rett og slett umulig. For ikke å snakke om hvor historieløs og uansvarlig tilnærming til arkitektur man finner i både store og små React-prosjekter.

Som en senior React-utvikler sa til meg nylig: "God React-kode i 2025 ligner mistenkelig på Elm-kode fra 2015."

Hva gjør Elm annerledes?

---

## En kjapp historietime før vi går videre

For å forstå hvorfor Elm er bygget som det er, og hvorfor det fortsatt er relevant, må vi ta et skritt tilbake og se på den større historien om programmeringsparadigmer. Denne utviklingen handler om noe fundamentalt: **Hvordan vi gradvis har fjernet farlige friheter for å skape mer pålitelig kode.**

**Merk**: Nå skal det sies at funksjonell programmering strengt tatt er eldre enn de andre paradigmene. Men jeg velger likevel å plassere det på slutten av en rekke iterasjoner som utvikler seg fra kaos til kontroll.

## Paradigmeutvikling: Å ta vekk muligheter for å få mer kontroll

#### 🏗 Før strukturert programmering – _"Full frihet, full kaos"_

Før 1960-tallet skrev utviklere ofte kode i en **rent imperativ stil**, hvor programmer besto av sekvenser av kommandoer med **GOTO-setninger** for å hoppe mellom ulike deler av programmet.

🔴 **Problem:** Koden ble vanskelig å forstå og vedlikeholde («spaghetti-kode»). Ingen garantier for at en sekvens av operasjoner var fornuftig, og feil ble uforutsigbare. "Undefined behaviour" ble en slags obligatorisk blindpassasjer.

---

#### 📏 Strukturert programmering – _"Ingen flere vilkårlige hopp!"_

[Edsger W. Dijkstra](https://en.wikipedia.org/wiki/Edsger_W._Dijkstra) og andre datavitere på 1960-70-tallet argumenterte for at all programlogikk burde kunne uttrykkes gjennom **sekvenser, valg (if/while/switch) og løkker**. Dette gjorde programmer mer forutsigbare. Dijkstras berømte artikkel ["Go To Statement Considered Harmful"](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf) (1968) var et vendepunkt.

✂ **Fjernet:** GOTO
✅ **Resultat:** Klarere kontrollflyt, lettere å debugge

---

#### 🏛 Objektorientert programmering (OOP) – _"Trygg polymorfisme!"_

OOP oppsto på 1980-90-tallet som en respons på behovet for mer fleksible og utvidbare systemer. Den største innovasjonen var – etter min mening – kanskje ikke innkapsling av tilstand, men **trygg polymorfisme** gjennom grensesnitt og arv.

✂ **Fjernet:** Utrygge "pointers to functions" og hardkodede avhengigheter
✅ **Resultat:**

- **[Dependency Inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle)** – Høynivåmoduler kan nå avhenge av abstraksjoner, ikke konkrete implementasjoner
- **Plugin-arkitektur** – Systemer kan utvides uten å endre eksisterende kode
- **Testbarhet** – Avhengigheter kan enkelt byttes ut med mock-objekter

Før OOP måtte utviklere bruke farlige "pointers to functions" for å oppnå polymorfisme. OOP gjorde dette trygt og forutsigbart gjennom virtuelle funksjoner og grensesnitt. Som [Robert C. Martin ("Uncle Bob")](https://blog.cleancoder.com/uncle-bob/2016/01/04/ALittleArchitecture.html) påpeker, var dette et stort fremskritt for arkitektonisk fleksibilitet.

---

#### 🧩 Funksjonell programmering (FP) – _"Fjern mutabilitet og bivirkninger!"_

FP har riktignok røtter tilbake til 1950-tallet ([Lisp](<https://en.wikipedia.org/wiki/Lisp_(programming_language)>)), men fikk økt popularitet med språk som [Haskell](https://www.haskell.org/), Elm og moderne bruk i TypeScript og React. Målet er å eliminere **uventede bivirkninger**, sikre at funksjoner alltid gir samme output for samme input, og unngå delt state. Jeg har valgt å se på det som neste (og siste) iterasjon på stigen mot å fjerne kaos.

✂ **Fjernet:**

- Mutabel state
- Skjulte side effects
- Objektorientert kompleksitet

✅ **Resultat:** Mer forutsigbar og testbar kode, men ofte brattere læringskurve.

---

#### 🔄 Fellesnevner: Hver epoke har handlet om å fjerne feilbarlige friheter (ikke legge til nye fancy features)

1. **Strukturert programmering:** Fjernet vilkårlige hopp (GOTO)
2. **OOP:** Fjernet ukontrollert deling av state
3. **FP:** Fjernet mutabilitet og skjulte side effects

Målet har alltid vært det samme: **Mindre kaos, mer kontroll**. 🔥

Dette er selvsagt en forenklet fremstilling av programmeringshistorien, men essensen er klar: **God kode handler ikke om maksimal frihet, men om velvalgte begrensninger.** De beste verktøyene hjelper oss å unngå feil, ikke bare å rette dem.

## Elm: Radikalt funksjonelt

Elm tar dette siste skrittet radikalt ved å gjøre immutabilitet obligatorisk:

```elm
-- Eksempel på Elm som forbyr mutasjon
update : Model -> Model
update model =
    { model | count = model.count + 1 }  -- Returnerer NY modell, mutasjon er umulig

-- Kompilatoren vil stoppe deg hvis du prøver:
-- model.count = 5  ← Kompileringsfeil!
```

Dette minner om [Rich Hickeys](https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy.md) påstand om enkelthet gjennom begrensninger i hans berømte foredrag ["Simple Made Easy"](https://www.youtube.com/watch?v=SxdOUGdseq4), og [Bret Victors](http://worrydream.com/) observasjon fra ["Inventing on Principle"](https://www.youtube.com/watch?v=PUv66718DII): "The most important property of a program is whether it is correct. The second most important is whether it can be changed without breaking its correctness."

---

## Når begrensninger gir frihet

Ironisk nok gir Elms strenge begrensninger oss flere fordeler:

- **Enklere feilsøking**: Når data aldri endres, slipper du å lure på "hvem eller hva endret denne verdien?"

  ```javascript
  // I JavaScript kan dette skje:
  let user = { name: "Ada" };
  someFunction(user); // user kan bli endret her
  console.log(user.name); // Hva er navnet nå? Umulig å vite uten å lese someFunction

  // Du kan også re-assigne `let`
  user = "user is now a string, not an object!";
  console.log(user.name); // Nå er user.name `undefined`
  ```

  I Elm er dette umulig - du får compile-time error hvis du prøver å mutere:

  ```elm
  -- I Elm:
  user = { name = "Ada" }

  -- Dette kompilerer ikke:
  user.name = "Grace"  -- FEIL: Elm har ikke variabel-mutasjon.

  -- Dette kompilerer heller ikke:
  user = { name = "Grace" }  -- FEIL: Elm kan ikke re-assigne variabler

  -- Riktig måte i Elm:
  updatedUser = { user | name = "Grace" }  -- Lager en ny kopi med endret navn

  -- Eller i en funksjon med let-in:
  updateName name user =
      let
          updatedUser = { user | name = name }
      in
      updatedUser
  ```

- **Forutsigbar kode**: Rene funksjoner + uforanderlige data = samme input gir alltid samme output

  ```elm
  -- Elm-funksjoner er alltid rene, og har ikke side effects
  sum : List Int -> Int  -- Gitt samme liste, alltid samme sum; og listen som sendes inn vil (igjen) ikke kunne muteres
  ```

- **Tryggere refaktorering**: Kompilatoren finner alle steder som må oppdateres

  ```elm
  type Msg
      = OldMessage  -- Endrer til NewMessage
      ↓
      = NewMessage
  -- Kompilatoren viser alle case-mønstre som må oppdateres
  ```

- **Mindre mental belastning**: Du trenger ikke holde hele tilstandshistorikken i hodet

  ```elm
  view : Model -> Html Msg  -- Kun gjeldende state er relevant
  ```

Mye av dette ligner unektelig på hvordan React kan se ut i beste fall. Men Elm tvinger deg inn i "beste fall"!

## Moderne fordeler i praksis

I 2025 gir Elm flere konkrete fordeler for moderne webapplikasjoner:

1. **Null runtime exceptions** – Når koden kompilerer, krasjer den ikke:

   ```elm
   -- Dette kompilerer ikke:
   text 5  -- Type error: Expected String, got Int

   -- Dette kompilerer:
   text (String.fromInt 5)  -- Trygt og forutsigbart
   ```

2. **Automatisk refaktorering** – Kompilatoren finner alle steder som må endres:

   ```elm
   -- Endre en datamodell:
   type alias User = { name : String }
   ↓
   type alias User = { name : String, email : String }

   -- Kompilatoren markerer alle funksjoner som må oppdateres
   ```

3. **Garantert håndtering av alle tilstander** – Ingen "undefined is not a function":

   ```elm
   -- Må håndtere både Just og Nothing:
   case maybeUser of
       Just user ->
           viewUser user

       Nothing ->
           text "Ingen bruker funnet"
   ```

4. **Optimalisert rendering** – Virtual DOM med automatisk diffing:

   ```elm
   -- Elm oppdaterer bare DOM-elementer som faktisk endres
   view : Model -> Html Msg
   view model =
       div []
           [ header [] [ text model.title ]
           , content [] [ text model.content ]
           ]
   ```

5. **Forutsigbar state management** – Én kilde til sannhet:

   ```elm
   -- All state er samlet i én modell
   type alias Model =
       { users : List User
       , currentPage : Page
       , isLoading : Bool
       }
   ```

## SOLID by default

Elm-arkitekturen (The Elm Architecture, eller bare TEA) er en enkel, men kraftfull modell for å bygge webapplikasjoner. Den består av tre hoveddeler:

1. **Model** - Applikasjonens tilstand
2. **Update** - Hvordan tilstanden endres som respons på hendelser
3. **View** - Hvordan tilstanden vises i brukergrensesnittet

![The Elm Architecture Diagram](https://guide.elm-lang.org/architecture/buttons.svg)
_Bildekilde: [Elm Guide](https://guide.elm-lang.org/architecture/)_

## Hvordan det fungerer

1. **Brukerinteraksjon** trigger en `Msg` (melding)
2. `Update`-funksjonen tar imot meldingen og returnerer en ny `Model`
3. Den nye `Model`-en sendes til `View`-funksjonen
4. `View`-funksjonen genererer ny HTML som vises til brukeren

Dette mønsteret tvinger frem [SOLID-prinsippene](https://en.wikipedia.org/wiki/SOLID) – enten du vil eller ikke:

1. **[Single Responsibility](https://en.wikipedia.org/wiki/Single-responsibility_principle)** – Elm tvinger deg til å separere View, Update og Model. Hver funksjon har én jobb, og én "reason to change", og kompilatoren klager hvis du prøver å blande ansvarsområder.

2. **[Open/Closed](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle)** – Ny funksjonalitet legges til ved å utvide Msg-typen med nye varianter, ikke ved å modifisere eksisterende kode. Elm-arkitekturen er designet for utvidelse!

3. **[Liskov Substitution](https://en.wikipedia.org/wiki/Liskov_substitution_principle)** – Automatisk oppfylt gjennom Elms typesystem og union types:

   ```elm
   -- I Elm er LSP umulig å bryte - kompilatoren tillater det ikke
   type Shape
       = Circle Float
       | Rectangle Float Float

   area : Shape -> Float
   area shape =
       case shape of
           Circle radius ->
               pi * radius * radius

           Rectangle width height ->
               width * height

   -- Prøv å legge til Triangle uten å oppdatere area-funksjonen
   -- Kompilatoren: "Godt forsøk, prøv igjen."
   ```

4. **[Interface Segregation](https://en.wikipedia.org/wiki/Interface_segregation_principle)** – Elm oppmuntrer til små, fokuserte moduler og typer. Ingen "mega-interfaces" som tvinger implementasjoner til å støtte unødvendige metoder.

5. **[Dependency Inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle)** – All kommunikasjon går gjennom meldinger (Msg) og abstraksjoner. Høynivåmoduler avhenger aldri av lavnivådetaljer.

Der andre språk tilbyr SOLID som "best practices" du kan følge hvis du er disiplinert, er de en obligatorisk del av Elms DNA. Kompilatoren er din ubarmhjertige arkitektur-mentor.

## The Elm Architecture vs. Clean Architecture

Clean Architecture (CA) handler om å organisere kode slik at forretningslogikken er uavhengig av rammeverk og UI. Hvordan passer TEA inn her?

#### 1. Separerer UI fra logikk

- Akkurat som CA, har TEA en klar separasjon mellom presentasjonslaget (**View**) og domenelogikken (**Model + Update**).
- Dette betyr at man kan endre UI uten å endre domenelogikken.

#### 2. Strukturering av forretningslogikk

- TEA har ikke et eksplisitt "use case-lag" slik CA anbefaler.
- Men **Update-funksjonen** kan sees på som en _interactor_ i CA, hvor den tar inn en hendelse og bestemmer en tilstandsendring.

#### 3. Uavhengighet fra eksterne systemer

- I Clean Architecture skal forretningslogikken være **uavhengig** av databaser, UI eller tredjeparts API-er.
- TEA sikrer dette ved å bruke **Cmd** for sideeffekter, slik at API-kall og lignende ligger utenfor kjernearkitekturen.

#### 4. Enkel testing

- Begge arkitekturer fremmer **testbar kode**.
- TEA sin rene funksjonelle tilnærming gjør det lett å enhetsteste **Update-funksjonen** uten å tenke på eksterne avhengigheter.

---

#### Oppsummering

```

| **Kriterium**           | **The Elm Architecture**                                  | **Clean Architecture**              |
| ----------------------- | --------------------------------------------------------- | ----------------------------------- |
| **Separasjonsprinsipp** | God separasjon av UI, logikk og tilstand                  | Fremmer separasjon av lag           |
| **Utvidbarhet**         | Enkel å utvide med nye meldinger, men Update kan bli stor | Fremmer fleksibilitet               |
| **Testbarhet**          | Lett å teste pga. rene funksjoner                         | Fremmer testbarhet                  |
| **Uavhengighet av UI**  | Ja, via Model og Update                                   | Hovedmål i Clean Architecture       |
| **Sideeffekter**        | Håndteres via "Cmd"                                       | Anbefaler isolasjon av sideeffekter |

```

---

TEA samsvarer overraskende godt også med Clean Architecture, selv om det er tilpasset en funksjonell kontekst. Spesielt **separasjon av UI og logikk**, testbarhet og håndtering av sideeffekter er sterke sider ved TEA. Hvis man vil bruke TEA i større systemer, kan det være nyttig å strukturere **Update-funksjonen** mer modulært, slik at den ikke blir en _God-funksjon_.

---

## Moderne frontend-utvikling trenger dette

I 2025 ser vi et paradoks: Verktøyene blir enklere, men applikasjonene blir mer komplekse. Elm adresserer dette gjennom:

1. **Typesikkerhet uten konfigurasjon** – Ingen kompliserte TypeScript-oppsett
2. **Trygg refaktorering** – Kompilatoren finner alle steder som må endres
3. **Isolerte sideeffekter** – Gjør testing og feilsøking enklere
4. **Felles arkitekturmønster** – Reduserer diskusjoner om kodestruktur

## Når bør du vurdere Elm?

Elm passer spesielt godt når:

1. Du bygger en kompleks frontend-applikasjon
2. Robusthet og vedlikeholdbarhet er kritisk
3. Du har mulighet til å trene opp teamet
4. Du starter et nytt prosjekt fra bunnen

## Utfordringene

La oss være ærlige om utfordringene også:

- Bratt læringskurve for utviklere vant til imperativ programmering
- Mindre økosystem enn React/Vue
- Færre utviklere tilgjengelig
- Kan være vanskelig å "selge inn" til beslutningstakere

## Konklusjon

Elms relevans i 2025 ligger ikke i markedsandeler, men som arkitektonisk kompass. Mange av dens prinsipper finner vi igjen i:

- [React Server Components](https://react.dev/blog/2023/03/22/react-labs-what-we-have-been-working-on-march-2023#react-server-components)' isolering av effekter
- TypeScripts stadig strengere type-system
- Veksten av compile-time-verktøy som [tRPC](https://trpc.io/) og [Zod](https://zod.dev/)

Igjen: det diverse "best-practices" oppfordrer den drevne utvikler til å legge vinn på, er en obligatorisk del av Elm. Visst kan (og bør!) du skrive funksjonell React med god arkitektur, sterke typer og isolerte side effects; med Elm får du rett og slett ikke lov til noe annet.

## Ressurser for å komme i gang

- [Elm Guide](https://guide.elm-lang.org/) – Den offisielle guiden
- [Elm in Action](https://amzn.to/41z14kq) – En utmerket bok for å lære hvordan Elm fungerer i større applikasjoner
- [Elm Community](https://elm-lang.org/community) – Et uvanlig hjelpsomt og åpent community, inkludert Slack, Discourse osv
- Mitt [hjemmesnekrede opplegg](https://github.com/cekrem/create-elm-live-app) fra gamledager, for å lage en enkel app med live reload og alt du trenger av tooling
- [Elm Land](https://elm.land/) – Nytt meta-rammeverk

"""


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
