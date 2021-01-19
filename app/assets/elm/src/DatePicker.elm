port module DatePicker exposing (main)

import Browser
import DurationDatePicker exposing (Settings, defaultSettings)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick, preventDefaultOn)
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Time exposing (Month(..), Posix, Zone, posixToMillis)
import Time.Extra as Time exposing (Interval(..))


type Msg
    = OpenPicker
    | UpdatePicker ( DurationDatePicker.DatePicker, Maybe ( Posix, Posix ) )
    | AdjustTimeZone Zone
    | Tick Posix


type alias Model =
    { currentTime : Posix
    , zone : Zone
    , pickedStartTime : Maybe Posix
    , pickedEndTime : Maybe Posix
    , picker : DurationDatePicker.DatePicker
    }


encodeFlags : Maybe Posix -> Maybe Posix -> Encode.Value
encodeFlags start end =
    let
        s =
            Maybe.withDefault (Time.millisToPosix 0) start

        e =
            Maybe.withDefault (Time.millisToPosix 0) end
    in
    Encode.object
        [ ( "start", posixToMillis s |> Encode.int )
        , ( "end", posixToMillis e |> Encode.int )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenPicker ->
            ( { model
                | picker =
                    DurationDatePicker.openPicker
                        model.zone
                        model.currentTime
                        model.pickedStartTime
                        model.pickedEndTime
                        model.picker
              }
            , Cmd.none
            )

        UpdatePicker ( newPicker, maybeRuntime ) ->
            let
                ( startTime, endTime ) =
                    Maybe.map
                        (\( start, end ) ->
                            ( Just start, Just end )
                        )
                        maybeRuntime
                        |> Maybe.withDefault ( model.pickedStartTime, model.pickedEndTime )
            in
            ( { model
                | picker = newPicker
                , pickedStartTime = startTime
                , pickedEndTime = endTime
              }
            , picked <| encodeFlags startTime endTime
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Cmd.none )

        Tick newTime ->
            ( { model | currentTime = newTime }, Cmd.none )


isDateBeforeToday : Posix -> Posix -> Bool
isDateBeforeToday today datetime =
    Time.posixToMillis today > Time.posixToMillis datetime


userDefinedDatePickerSettings : Model -> Settings Msg
userDefinedDatePickerSettings { zone, currentTime } =
    let
        defaults =
            defaultSettings zone UpdatePicker
    in
    { defaults
        | dateTimeProcessor =
            { isDayDisabled =
                \clientZone datetime ->
                    isDateBeforeToday (Time.floor Day clientZone currentTime) datetime
            , allowedTimesOfDay =
                \clientZone datetime ->
                    { endHour = 23
                    , endMinute = 59
                    , startHour = 0
                    , startMinute = 0
                    }
            }
        , focusedDate = Just currentTime
        , dateStringFn = posixToDateString
        , timeStringFn = posixToTimeString
    }


onClickNoDefault : msg -> Html.Attribute msg
onClickNoDefault msg =
    preventDefaultOn "click" (Decode.map alwaysPreventDefault (Decode.succeed msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


view : Model -> Html Msg
view model =
    div [ class "" ]
        [ div []
            [ div [ class "flex items-center justify-between my-2" ]
                [ button
                    [ class "flex justify-center px-4 py-2 mx-auto text-sm font-medium leading-5 text-white transition duration-150 ease-in-out bg-red-500 border border-transparent rounded-full sm:mx-0 hover:bg-red-400 focus:outline-none focus:border-red-700 focus:shadow-outline-red active:bg-red-700"
                    , onClickNoDefault OpenPicker
                    ]
                    [ text "Change" ]
                , Maybe.map2
                    (\start end ->
                        text
                            (posixToDateString model.zone start
                                ++ " "
                                ++ posixToTimeString model.zone start
                                ++ " - "
                                ++ posixToDateString model.zone end
                                ++ " "
                                ++ posixToTimeString model.zone end
                            )
                    )
                    model.pickedStartTime
                    model.pickedEndTime
                    |> Maybe.withDefault (text "No date selected yet!")
                ]
            , DurationDatePicker.view
                (userDefinedDatePickerSettings model)
                model.picker
            ]
        ]


type alias Flags =
    { start : Int
    , end : Int
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { currentTime = Time.millisToPosix 0
      , zone = Time.utc
      , pickedStartTime = Just <| Time.millisToPosix flags.start
      , pickedEndTime = Just <| Time.millisToPosix flags.end
      , picker = DurationDatePicker.init
      }
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ DurationDatePicker.subscriptions
            (userDefinedDatePickerSettings model)
            UpdatePicker
            model.picker
        , Time.every 1000 Tick
        ]


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- VIEW UTILITIES - these are not required for the package to work, they are used here simply to format the selected dates


addLeadingZero : Int -> String
addLeadingZero value =
    let
        string =
            String.fromInt value
    in
    if String.length string == 1 then
        "0" ++ string

    else
        string


monthToNmbString : Month -> String
monthToNmbString month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


posixToDateString : Zone -> Posix -> String
posixToDateString zone date =
    addLeadingZero (Time.toDay zone date)
        ++ "."
        ++ monthToNmbString (Time.toMonth zone date)
        ++ "."
        ++ addLeadingZero (Time.toYear zone date)


posixToTimeString : Zone -> Posix -> String
posixToTimeString zone datetime =
    addLeadingZero (Time.toHour zone datetime)
        ++ ":"
        ++ addLeadingZero (Time.toMinute zone datetime)
        ++ ":"
        ++ addLeadingZero (Time.toSecond zone datetime)


port picked : Encode.Value -> Cmd msg
