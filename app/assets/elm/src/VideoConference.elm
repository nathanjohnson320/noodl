port module VideoConference exposing (main)

import Browser
import Html exposing (Html, button, div, option, select, text)
import Html.Attributes exposing (class, id, style, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import KeynoteHost exposing (Device, EncodingConfig(..), Media, Stream(..), StreamPosition(..), deviceDecoder, encodeMedia, mediaDecoder)
import List.Extra as List
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


type Role
    = Host
    | Audience


type alias Devices =
    { microphones : List Device
    , cameras : List Device
    }


devicesDecoder : Decode.Decoder Devices
devicesDecoder =
    Decode.map2 Devices
        (Decode.field "microphones" <| Decode.list deviceDecoder)
        (Decode.field "cameras" <| Decode.list deviceDecoder)


type alias Flags =
    { environment : String
    , appId : String
    , channel : String
    , token : String
    , uid : Int
    , role : String
    , devices : Devices
    }


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map7 Flags
        (Decode.field "environment" Decode.string)
        (Decode.field "appId" Decode.string)
        (Decode.field "channel" Decode.string)
        (Decode.field "token" Decode.string)
        (Decode.field "uid" Decode.int)
        (Decode.field "role" Decode.string)
        (Decode.field "devices" devicesDecoder)


type alias Model =
    { environment : String
    , appId : String
    , channel : String
    , token : String
    , uid : Int
    , role : Role
    , connected : Bool
    , mediaStreams : List Media
    , devices : Devices
    , selectedMicrophone : Device
    , selectedCamera : Device
    , videoEncoding : EncodingConfig
    , audioEncoding : EncodingConfig
    }



-- UPDATE


type Msg
    = Connected Bool
    | Subscribed Encode.Value
    | Unsubscribed Encode.Value
    | Stopped Encode.Value
    | Started Encode.Value
    | ToggleAudio
    | ChangeAudioDevice String
    | ChangeVideoDevice String
    | AddedPresenter Encode.Value
    | StartScreen
    | StartCamera
    | StopVideo Media


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                                (\mediaStream ->
                                    not
                                        (mediaStream.user
                                            == media.user
                                            && mediaStream.mediaType
                                            == media.mediaType
                                        )
                                )
                                model.mediaStreams
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ToggleAudio ->
            let
                cmd =
                    case streamActive model Audio of
                        Just media ->
                            stop <|
                                encodeMedia media

                        Nothing ->
                            start <|
                                encodeMedia
                                    { user = model.uid
                                    , mediaType = Audio
                                    , position = Primary
                                    , encodingConfig = model.audioEncoding
                                    , device =
                                        model.selectedMicrophone
                                    }
            in
            ( model
            , cmd
            )

        Started mediaJson ->
            case Decode.decodeValue mediaDecoder mediaJson of
                Ok media ->
                    ( { model | mediaStreams = media :: model.mediaStreams }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Stopped mediaJson ->
            case Decode.decodeValue mediaDecoder mediaJson of
                Ok media ->
                    let
                        filteredStreams =
                            List.filter
                                (\mediaStream ->
                                    not (mediaStream.user == media.user && mediaStream.mediaType == media.mediaType)
                                )
                                model.mediaStreams
                    in
                    ( { model
                        | mediaStreams =
                            filteredStreams
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ChangeAudioDevice id ->
            let
                cmd =
                    case streamActive model Audio of
                        Nothing ->
                            Cmd.none

                        Just _ ->
                            changeDevice <|
                                encodeMedia
                                    { user = model.uid
                                    , mediaType = Audio
                                    , position = Primary
                                    , encodingConfig = model.videoEncoding
                                    , device =
                                        device
                                    }

                device =
                    case List.find (\d -> d.deviceId == id) model.devices.microphones of
                        Just microphone ->
                            microphone

                        Nothing ->
                            { deviceId = ""
                            , label = "Microphone"
                            }
            in
            ( { model | selectedMicrophone = device }, cmd )

        ChangeVideoDevice id ->
            let
                cmd =
                    case streamActive model Camera of
                        Nothing ->
                            Cmd.none

                        Just _ ->
                            changeDevice <|
                                encodeMedia
                                    { user = model.uid
                                    , mediaType = Camera
                                    , position = Primary
                                    , encodingConfig = model.videoEncoding
                                    , device =
                                        device
                                    }

                device =
                    case List.find (\d -> d.deviceId == id) model.devices.cameras of
                        Just camera ->
                            camera

                        Nothing ->
                            { deviceId = ""
                            , label = "Camera"
                            }
            in
            ( { model | selectedCamera = device }, cmd )

        StartScreen ->
            ( model
            , start <|
                encodeMedia
                    { user = model.uid
                    , mediaType = Screen
                    , position = Primary
                    , encodingConfig = model.videoEncoding
                    , device =
                        model.selectedCamera
                    }
            )

        StartCamera ->
            ( model
            , start <|
                encodeMedia
                    { user = model.uid
                    , mediaType = Camera
                    , position = Primary
                    , encodingConfig = model.videoEncoding
                    , device =
                        model.selectedCamera
                    }
            )

        StopVideo media ->
            ( model, stop <| encodeMedia media )

        AddedPresenter flagsJson ->
            case Decode.decodeValue flagsDecoder flagsJson of
                Ok flags ->
                    init flags

                Err e ->
                    ( model, Cmd.none )



-- VIEW


active : Model -> Stream -> Bool
active model stream =
    case streamActive model stream of
        Just _ ->
            True

        Nothing ->
            False


streamActive : Model -> Stream -> Maybe Media
streamActive model stream =
    List.find (\s -> s.user == model.uid && stream == s.mediaType) model.mediaStreams


view : Model -> Html Msg
view model =
    div
        [ class "relative flex w-full bg-black"
        , id "session-video"
        , style "height" "100%"
        ]
        [ div [ class "flex flex-wrap w-full", id "videos-container" ]
            []
        , if model.role == Host then
            div [ class "absolute bottom-0 z-20 flex justify-center w-full py-2" ]
                [ select
                    [ class "block form-select w-32 py-2 px-3 py-0 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none transition duration-150 ease-in-out sm:text-sm sm:leading-5"
                    , onInput ChangeAudioDevice
                    ]
                    (option [ value "" ]
                        [ text "Microphone" ]
                        :: List.map
                            (\device ->
                                option [ value device.deviceId ]
                                    [ text device.label ]
                            )
                            model.devices.microphones
                    )
                , button
                    [ class
                        ("flex items-center justify-center p-2 mx-2 rounded-full "
                            ++ (case streamActive model Audio of
                                    Nothing ->
                                        "bg-gray-500 opacity-75"

                                    Just _ ->
                                        "bg-blue-500"
                               )
                        )
                    , onClick ToggleAudio
                    ]
                    [ svg [ Svg.Attributes.class "h-6 w-6 text-white", fill "currentColor", viewBox "0 0 20 20" ]
                        [ path
                            [ clipRule "evenodd"
                            , d "M7 4a3 3 0 016 0v4a3 3 0 11-6 0V4zm4 10.93A7.001 7.001 0 0017 8a1 1 0 10-2 0A5 5 0 015 8a1 1 0 00-2 0 7.001 7.001 0 006 6.93V17H6a1 1 0 100 2h8a1 1 0 100-2h-3v-2.07z"
                            , fillRule "evenodd"
                            ]
                            []
                        ]
                    ]
                , case streamActive model Camera of
                    Just camera ->
                        button
                            [ class "flex items-center justify-center p-2 mx-2 bg-blue-500 rounded-full"
                            , onClick <| StopVideo camera
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

                    Nothing ->
                        text ""
                , case streamActive model Screen of
                    Just screen ->
                        button
                            [ class "flex items-center justify-center p-2 mx-2 bg-blue-500 rounded-full"
                            , onClick <| StopVideo screen
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

                    Nothing ->
                        text ""
                , if not (active model Screen || active model Camera) then
                    button
                        [ class "flex items-center justify-center p-2 mx-2 bg-gray-500 rounded-full opacity-75"
                        , onClick StartScreen
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
                , if not (active model Screen || active model Camera) then
                    button
                        [ class "flex items-center justify-center p-2 mx-2 bg-gray-500 rounded-full opacity-75"
                        , onClick StartCamera
                        ]
                        [ svg
                            [ Svg.Attributes.class "h-6 w-6 text-white"
                            , fill "currentColor"
                            , viewBox "0 0 24 24"
                            ]
                            [ path [ d "M16 8.38l4.55-2.27A1 1 0 0 1 22 7v10a1 1 0 0 1-1.45.9L16 15.61V17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v1.38zm0 2.24v2.76l4 2V8.62l-4 2zM14 17V7H4v10h10z" ]
                                []
                            ]
                        ]

                  else
                    text ""
                , select
                    [ class "block form-select w-32 py-2 px-3 py-0 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none transition duration-150 ease-in-out sm:text-sm sm:leading-5"
                    , onInput ChangeVideoDevice
                    ]
                    (option [ value "" ]
                        [ text "Camera" ]
                        :: List.map
                            (\device ->
                                option [ value device.deviceId ]
                                    [ text device.label ]
                            )
                            model.devices.cameras
                    )
                ]

          else
            text ""
        ]



-- MAIN


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { environment = flags.environment
      , appId = flags.appId
      , channel = flags.channel
      , token = flags.token
      , connected = False
      , mediaStreams = []
      , audioEncoding = High
      , videoEncoding = High
      , uid = flags.uid
      , role =
            case flags.role of
                "host" ->
                    Host

                _ ->
                    Audience
      , devices = flags.devices
      , selectedMicrophone = { deviceId = "", label = "Microphone" }
      , selectedCamera = { deviceId = "", label = "Camera" }
      }
    , mounted flags
    )


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ connected Connected
        , subscribed Subscribed
        , unsubscribed Unsubscribed
        , started Started
        , stopped Stopped
        , addedPresenter AddedPresenter
        ]



-- OUTBOUND PORTS


port mounted : Flags -> Cmd msg


port start : Encode.Value -> Cmd msg


port changeDevice : Encode.Value -> Cmd msg


port stop : Encode.Value -> Cmd msg



-- INBOUND PORTS


port connected : (Bool -> msg) -> Sub msg


port subscribed : (Encode.Value -> msg) -> Sub msg


port unsubscribed : (Encode.Value -> msg) -> Sub msg


port started : (Encode.Value -> msg) -> Sub msg


port stopped : (Encode.Value -> msg) -> Sub msg


port addedPresenter : (Encode.Value -> msg) -> Sub msg
