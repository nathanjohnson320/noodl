port module KeynoteHost exposing
    ( Device
    , EncodingConfig(..)
    , Media
    , Stream(..)
    , StreamPosition(..)
    , deviceDecoder
    , encodeDevice
    , encodeMedia
    , main
    , mediaDecoder
    )

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra as List
import String
import Svg exposing (path, svg)
import Svg.Attributes
    exposing
        ( clipRule
        , d
        , fill
        , fillRule
        , viewBox
        )



-- MODEL


type Stream
    = Camera
    | Screen
    | Audio


type StreamPosition
    = Primary
    | Secondary
    | Hidden


type EncodingConfig
    = Low
    | Medium
    | High


type alias Device =
    { deviceId : String
    , label : String
    }


type alias Media =
    { user : Int
    , mediaType : Stream
    , position : StreamPosition
    , encodingConfig : EncodingConfig
    , device : Device
    }


encodePosition : StreamPosition -> Encode.Value
encodePosition stream =
    case stream of
        Primary ->
            Encode.int 1

        Secondary ->
            Encode.int 2

        Hidden ->
            Encode.int 0


encodeMediaType : Stream -> Encode.Value
encodeMediaType stream =
    case stream of
        Camera ->
            Encode.string "camera"

        Screen ->
            Encode.string "screen"

        Audio ->
            Encode.string "audio"


encodeEncodingConfig : EncodingConfig -> Encode.Value
encodeEncodingConfig config =
    case config of
        Low ->
            Encode.string "low"

        Medium ->
            Encode.string "medium"

        High ->
            Encode.string "high"


encodeDevice : Device -> Encode.Value
encodeDevice device =
    Encode.object
        [ ( "deviceId", Encode.string device.deviceId )
        , ( "label", Encode.string device.label )
        ]


encodeMedia : Media -> Encode.Value
encodeMedia stream =
    Encode.object
        [ ( "user", Encode.int stream.user )
        , ( "mediaType", encodeMediaType stream.mediaType )
        , ( "position", encodePosition stream.position )
        , ( "encodingConfig", encodeEncodingConfig stream.encodingConfig )
        , ( "device", encodeDevice stream.device )
        ]


positionDecoder : Decode.Decoder StreamPosition
positionDecoder =
    Decode.int
        |> Decode.andThen
            (\position ->
                case position of
                    1 ->
                        Decode.succeed Primary

                    2 ->
                        Decode.succeed Secondary

                    0 ->
                        Decode.succeed Hidden

                    _ ->
                        Decode.fail <| "Unknown posotion: " ++ String.fromInt position
            )


streamDecoder : Decode.Decoder Stream
streamDecoder =
    Decode.string
        |> Decode.andThen
            (\stream ->
                case stream of
                    "camera" ->
                        Decode.succeed Camera

                    "screen" ->
                        Decode.succeed Screen

                    "audio" ->
                        Decode.succeed Audio

                    _ ->
                        Decode.fail <| "Unknown posotion: " ++ stream
            )


encodingConfigDecoder : Decode.Decoder EncodingConfig
encodingConfigDecoder =
    Decode.string
        |> Decode.andThen
            (\stream ->
                case stream of
                    "low" ->
                        Decode.succeed Low

                    "medium" ->
                        Decode.succeed Medium

                    "high" ->
                        Decode.succeed High

                    _ ->
                        Decode.fail <| "Unknown encoding: " ++ stream
            )


deviceDecoder : Decode.Decoder Device
deviceDecoder =
    Decode.map2 Device
        (Decode.field "deviceId" Decode.string)
        (Decode.field "label" Decode.string)


mediaDecoder : Decode.Decoder Media
mediaDecoder =
    Decode.map5 Media
        (Decode.field "user" Decode.int)
        (Decode.field "mediaType" streamDecoder)
        (Decode.field "position" positionDecoder)
        (Decode.field "encodingConfig" encodingConfigDecoder)
        (Decode.field "device" deviceDecoder)


type alias Flags =
    { environment : String
    , appId : String
    , channel : String
    , tokenPrimary : String
    , tokenSecondary : String
    }


type alias Model =
    { environment : String
    , appId : String
    , channel : String
    , tokenPrimary : String
    , tokenSecondary : String
    , primary : Stream
    , primaryEncoding : EncodingConfig
    , secondary : Stream
    , secondaryEncoding : EncodingConfig
    , connected : Bool
    , mediaStreams : List Media
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { environment = flags.environment
      , appId = flags.appId
      , channel = flags.channel
      , tokenPrimary = flags.tokenPrimary
      , tokenSecondary = flags.tokenSecondary
      , primary = Screen
      , secondary = Camera
      , connected = False
      , mediaStreams = []
      , primaryEncoding = High
      , secondaryEncoding = Low
      }
    , mounted flags
    )



-- UPDATE


type Msg
    = Connected Bool
    | Stop Media
    | Start Media
    | Stopped Encode.Value
    | Started Encode.Value
    | ToggleAudio
    | Swap
    | Swapped Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Connected status ->
            ( { model | connected = status }, Cmd.none )

        Stop stream ->
            ( model, stop <| encodeMedia stream )

        Start stream ->
            ( model, start <| encodeMedia stream )

        ToggleAudio ->
            let
                cmd =
                    if not (streamActive model Hidden) then
                        start <|
                            encodeMedia
                                { user = 0
                                , mediaType = Audio
                                , position = Hidden
                                , encodingConfig = model.primaryEncoding
                                , device =
                                    { deviceId = ""
                                    , label = ""
                                    }
                                }

                    else
                        stop <|
                            encodeMedia
                                { user = 0
                                , mediaType = Audio
                                , position = Hidden
                                , encodingConfig = model.primaryEncoding
                                , device =
                                    { deviceId = ""
                                    , label = ""
                                    }
                                }
            in
            ( model
            , cmd
            )

        Swap ->
            ( model, swap (Encode.list encodeMedia model.mediaStreams) )

        Swapped mediaJson ->
            case Decode.decodeValue (Decode.list mediaDecoder) mediaJson of
                Ok media ->
                    ( { model
                        | mediaStreams = media
                        , primary = model.secondary
                        , secondary = model.primary
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Started mediaJson ->
            case Decode.decodeValue mediaDecoder mediaJson of
                Ok media ->
                    ( { model | mediaStreams = media :: model.mediaStreams }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Stopped mediaJson ->
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



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


getMedia : Model -> StreamPosition -> Media
getMedia model position =
    case position of
        Primary ->
            { user = 1
            , mediaType = model.primary
            , position = Primary
            , encodingConfig = model.primaryEncoding
            , device =
                { deviceId = ""
                , label = ""
                }
            }

        Secondary ->
            { user = 2
            , mediaType = model.secondary
            , position = Secondary
            , encodingConfig = model.secondaryEncoding
            , device =
                { deviceId = ""
                , label = ""
                }
            }

        Hidden ->
            { user = 0
            , mediaType = Audio
            , position = Hidden
            , encodingConfig = model.primaryEncoding
            , device =
                { deviceId = ""
                , label = ""
                }
            }


streamActive : Model -> StreamPosition -> Bool
streamActive { mediaStreams } position =
    case List.find (\s -> s.position == position) mediaStreams of
        Just _ ->
            True

        Nothing ->
            False


view : Model -> Html Msg
view model =
    div
        [ id "session-video"
        , class "relative flex w-full bg-black"
        , style "height" "100%"
        ]
        [ div [ class "absolute bottom-0 z-10 flex justify-center w-full py-2" ]
            [ if streamActive model Primary then
                button
                    [ class "flex items-center justify-center p-2 mx-2 bg-blue-500 rounded-full"
                    , onClick <| Stop <| getMedia model Primary
                    ]
                    [ svg
                        [ Svg.Attributes.class "h-6 w-6 text-white"
                        , fill "none"
                        , viewBox "0 0 20 20"
                        ]
                        [ path
                            [ clipRule "evenodd"
                            , d "M10 18C14.4183 18 18 14.4183 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 14.4183 5.58172 18 10 18ZM8 7C7.44772 7 7 7.44772 7 8V12C7 12.5523 7.44772 13 8 13H12C12.5523 13 13 12.5523 13 12V8C13 7.44772 12.5523 7 12 7H8Z"
                            , fill "#fff"
                            , fillRule "evenodd"
                            ]
                            []
                        ]
                    ]

              else
                text ""
            , button
                [ class "flex items-center justify-center p-2 mx-2 bg-gray-500 opacity-75 rounded-full"
                , onClick Swap
                ]
                [ svg
                    [ Svg.Attributes.class "h-6 w-6 text-white"
                    , fill "currentColor"
                    , viewBox "0 0 24 24"
                    ]
                    [ path
                        [ d "M6 18.7V21a1 1 0 0 1-2 0v-5a1 1 0 0 1 1-1h5a1 1 0 1 1 0 2H7.1A7 7 0 0 0 19 12a1 1 0 1 1 2 0 9 9 0 0 1-15 6.7zM18 5.3V3a1 1 0 0 1 2 0v5a1 1 0 0 1-1 1h-5a1 1 0 0 1 0-2h2.9A7 7 0 0 0 5 12a1 1 0 1 1-2 0 9 9 0 0 1 15-6.7z"
                        ]
                        []
                    ]
                ]
            , button
                [ class
                    ("flex items-center justify-center p-2 mx-2 rounded-full "
                        ++ (if not (streamActive model Hidden) then
                                "bg-gray-500 opacity-75"

                            else
                                "bg-blue-500"
                           )
                    )
                , onClick ToggleAudio
                ]
                [ svg
                    [ Svg.Attributes.class "h-6 w-6 text-white"
                    , fill "currentColor"
                    , viewBox "0 0 20 20"
                    ]
                    [ path
                        [ clipRule "evenodd"
                        , d "M7 4a3 3 0 016 0v4a3 3 0 11-6 0V4zm4 10.93A7.001 7.001 0 0017 8a1 1 0 10-2 0A5 5 0 015 8a1 1 0 00-2 0 7.001 7.001 0 006 6.93V17H6a1 1 0 100 2h8a1 1 0 100-2h-3v-2.07z"
                        , fillRule "evenodd"
                        ]
                        []
                    ]
                ]
            , if not <| streamActive model Secondary then
                button
                    [ class "flex items-center justify-center p-2 mx-2 bg-gray-500 rounded-full opacity-75"
                    , onClick <| Start <| getMedia model Secondary
                    ]
                    [ svg
                        [ Svg.Attributes.class "h-6 w-6 text-white"
                        , fill "currentColor"
                        , viewBox "0 0 24 24"
                        ]
                        [ path
                            [ d "M16 8.38l4.55-2.27A1 1 0 0 1 22 7v10a1 1 0 0 1-1.45.9L16 15.61V17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v1.38zm0 2.24v2.76l4 2V8.62l-4 2zM14 17V7H4v10h10z"
                            ]
                            []
                        ]
                    ]

              else
                text ""
            , if not <| streamActive model Primary then
                button
                    [ class "flex items-center justify-center p-2 mx-2 bg-gray-500 rounded-full opacity-75"
                    , onClick <| Start <| getMedia model Primary
                    ]
                    [ svg
                        [ Svg.Attributes.class "h-6 w-6 text-white"
                        , fill "currentColor"
                        , viewBox "0 0 24 24"
                        ]
                        [ path
                            [ d "M13 17h-2v2h2v-2zm2 0v2h2a1 1 0 0 1 0 2H7a1 1 0 0 1 0-2h2v-2H4a2 2 0 0 1-2-2V5c0-1.1.9-2 2-2h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-5zM4 5v10h16V5H4z"
                            ]
                            []
                        ]
                    ]

              else
                text ""
            , div
                [ class "w-56 h-40 absolute right-0 bottom-0"
                , id "secondary"
                ]
                [ if streamActive model Secondary then
                    button
                        [ class "flex items-center justify-center z-10 p-2 m-2 bg-blue-500 rounded-full absolute bottom-0 right-0"
                        , onClick <| Stop <| getMedia model Secondary
                        ]
                        [ svg
                            [ Svg.Attributes.class "h-6 w-6 text-white"
                            , fill "none"
                            , viewBox "0 0 20 20"
                            ]
                            [ path
                                [ clipRule "evenodd"
                                , d "M10 18C14.4183 18 18 14.4183 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 14.4183 5.58172 18 10 18ZM8 7C7.44772 7 7 7.44772 7 8V12C7 12.5523 7.44772 13 8 13H12C12.5523 13 13 12.5523 13 12V8C13 7.44772 12.5523 7 12 7H8Z"
                                , fill "#fff"
                                , fillRule "evenodd"
                                ]
                                []
                            ]
                        ]

                  else
                    text ""
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ connected Connected
        , started Started
        , stopped Stopped
        , swapped Swapped
        ]



-- OUTBOUND PORTS


port mounted : Flags -> Cmd msg


port swap : Encode.Value -> Cmd msg


port start : Encode.Value -> Cmd msg


port stop : Encode.Value -> Cmd msg



-- INBOUND PORTS


port connected : (Bool -> msg) -> Sub msg


port started : (Encode.Value -> msg) -> Sub msg


port stopped : (Encode.Value -> msg) -> Sub msg


port swapped : (Encode.Value -> msg) -> Sub msg
