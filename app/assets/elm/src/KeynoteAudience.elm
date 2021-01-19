port module KeynoteAudience exposing (Flags, Model, Msg(..), init, main, subscriptions, update)

import Browser
import Html exposing (Html, button, div, input)
import Html.Attributes exposing (class, id, step, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import String
import Svg exposing (path, svg)
import Svg.Attributes exposing (d, fill, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox)



-- MODEL


type alias Flags =
    { environment : String
    , appId : String
    , channel : String
    , token : String
    , uid : Int
    , volume : Int
    }


type alias Model =
    { environment : String
    , appId : String
    , channel : String
    , token : String
    , uid : Int
    , connected : Bool
    , fullscreen : Bool
    , volume : Int
    , mediaStreams : List Media
    }


mediaDecoder : Decode.Decoder Media
mediaDecoder =
    Decode.map2 Media
        (Decode.field "user" Decode.int)
        (Decode.field "mediaType" Decode.string)


type alias Media =
    { user : Int
    , mediaType : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { environment = flags.environment
      , appId = flags.appId
      , channel = flags.channel
      , token = flags.token
      , uid = flags.uid
      , connected = False
      , fullscreen = False
      , volume = flags.volume
      , mediaStreams = []
      }
    , mounted flags
    )



-- UPDATE


type Msg
    = NoOp
    | Connected Bool
    | AdjustVolume String
    | Fullscreen
    | CloseFullscreen Bool
    | Subscribed Encode.Value
    | Unsubscribed Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fullscreen ->
            ( { model | fullscreen = True }, fullscreen True )

        CloseFullscreen direction ->
            ( { model | fullscreen = direction }, Cmd.none )

        AdjustVolume volume ->
            let
                parsedVolume =
                    Maybe.withDefault 0 <| String.toInt volume
            in
            ( { model | volume = parsedVolume }, volumeChange parsedVolume )

        Connected status ->
            ( { model | connected = status }, Cmd.none )

        Subscribed mediaJson ->
            case Decode.decodeValue mediaDecoder mediaJson of
                Ok media ->
                    ( { model | mediaStreams = media :: model.mediaStreams }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Unsubscribed mediaJson ->
            case Decode.decodeValue mediaDecoder mediaJson of
                Ok media ->
                    ( { model
                        | mediaStreams =
                            List.filter
                                (\mediaStream -> mediaStream.user /= media.user)
                                model.mediaStreams
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ connected Connected
        , subscribed Subscribed
        , unsubscribed Unsubscribed
        , closeFullscreen CloseFullscreen
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ id "session-video"
        , class "relative flex w-full bg-black"
        , style "height" "100%"
        ]
        [ div [ class "absolute bottom-0 z-10 flex justify-center w-full py-2" ] <|
            if model.mediaStreams /= [] then
                [ button
                    [ onClick Fullscreen
                    , class "flex items-center justify-center p-2 mx-2 bg-gray-500 opacity-75 rounded-full"
                    ]
                    [ svg
                        [ Svg.Attributes.class "h-6 w-6 text-white"
                        , fill "currentColor"
                        , viewBox "0 0 19 20"
                        ]
                        [ path
                            [ d "M3 8V4M3 4H7M3 4L7 8M15 8V4M15 4H11M15 4L11 8M3 12V16M3 16H7M3 16L7 12M15 16L11 12M15 16V12M15 16H11"
                            , stroke "currentColor"
                            , strokeLinecap "round"
                            , strokeLinejoin "round"
                            , strokeWidth "2"
                            ]
                            []
                        ]
                    ]
                , input
                    [ class "absolute transform -rotate-90 origin-center left-0"
                    , style "left" "-20px"
                    , style "bottom" "40px"
                    , style "width" "75px"
                    , type_ "range"
                    , Html.Attributes.min "0"
                    , Html.Attributes.max "100"
                    , step "1"
                    , onInput AdjustVolume
                    , value <| String.fromInt model.volume
                    ]
                    []
                , div
                    [ id "secondary"
                    , class "w-48 h-48 absolute right-0 bottom-0"
                    ]
                    []
                ]

            else
                [ div
                    [ id "secondary"
                    , class "w-48 h-48 absolute right-0 bottom-0"
                    ]
                    []
                ]
        ]



-- OUTBOUND PORTS


port mounted : Flags -> Cmd msg


port fullscreen : Bool -> Cmd msg


port volumeChange : Int -> Cmd msg



-- INBOUND PORTS


port connected : (Bool -> msg) -> Sub msg


port closeFullscreen : (Bool -> msg) -> Sub msg


port subscribed : (Encode.Value -> msg) -> Sub msg


port unsubscribed : (Encode.Value -> msg) -> Sub msg
