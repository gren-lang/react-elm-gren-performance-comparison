port module Todo exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import String
import Platform



main : Platform.Program () Model Msg
main =
  Browser.element
    { init = \_ -> init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }


port focus : String -> Cmd msg



-- MODEL


type alias Model =
    { entries : List Entry
    , field : String
    , uid : Int
    , visibility : String
    }


type alias Entry =
    { description : String
    , completed : Bool
    , editing : Bool
    , id : Int
    }


emptyModel : Model
emptyModel =
  { entries = []
  , visibility = "All"
  , field = ""
  , uid = 0
  }


newEntry : String -> Int -> Entry
newEntry desc id =
  { description = desc
  , completed = False
  , editing = False
  , id = id
  }


init : ( Model, Cmd Msg )
init =
  ( emptyModel
  , Cmd.none
  )



-- UPDATE


type Msg
    = NoOp
    | UpdateField String
    | EditingEntry Int Bool
    | UpdateEntry Int String
    | Add
    | Delete Int
    | DeleteComplete
    | Check Int Bool
    | CheckAll Bool
    | ChangeVisibility String


-- How we update our Model on a given Msg?
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model
      , Cmd.none
      )

    Add ->
      ({ model
        | uid = model.uid + 1
        , field = ""
        , entries =
            if String.isEmpty model.field then
              model.entries
            else
              model.entries ++ [newEntry model.field model.uid]
      }
      , Cmd.none
      )

    UpdateField str ->
      ( { model | field = str }
      , Cmd.none
      )

    EditingEntry id isEditing ->
      let
        updateEntry t =
          if t.id == id then { t | editing = isEditing } else t
      in
      ( { model | entries = List.map updateEntry model.entries }
      , focus ("#todo-" ++ String.fromInt id)
      )

    UpdateEntry id task ->
      let
        updateEntry t =
          if t.id == id then { t | description = task } else t
      in
      ( { model | entries = List.map updateEntry model.entries }
      , Cmd.none
      )

    Delete id ->
      ( { model | entries = List.filter (\t -> t.id /= id) model.entries }
      , Cmd.none
      )

    DeleteComplete ->
      ( { model | entries = List.filter (not << .completed) model.entries }
      , Cmd.none
      )

    Check id isCompleted ->
      let
        updateEntry t =
          if t.id == id then { t | completed = isCompleted } else t
      in
      ( { model | entries = List.map updateEntry model.entries }
      , Cmd.none
      )

    CheckAll isCompleted ->
      let
        updateEntry t =
          { t | completed = isCompleted }
      in
      ( { model | entries = List.map updateEntry model.entries }
      , Cmd.none
      )

    ChangeVisibility visibility ->
      ( { model | visibility = visibility }
      , Cmd.none
      )



-- VIEW


view : Model -> Html Msg
view model =
  div
    [ class "todomvc-wrapper"
    , style "visibility" "hidden"
    ]
    [ section
        [ class "todoapp" ]
        [ viewInput model.field
        , viewEntries model.visibility model.entries
        , viewControls model.visibility model.entries
        ]
    , infoFooter
    ]


viewInput : String -> Html Msg
viewInput task =
  header
    [ class "header" ]
    [ h1 [] [ text "todos" ]
    , input
        [ class "new-todo"
        , placeholder "What needs to be done?"
        , autofocus True
        , value task
        , name "newTodo"
        , onInput UpdateField
        , onEnter Add
        ]
        []
    ]


onEnter : Msg -> Attribute Msg
onEnter msg =
  let
    tagger code =
      if code == 13 then msg else NoOp
  in
    on "keydown" (Json.map tagger keyCode)



-- VIEW ALL ENTRIES


viewEntries : String -> List Entry -> Html Msg
viewEntries visibility entries =
  let
    isVisible todo =
      case visibility of
        "Completed" -> todo.completed
        "Active" -> not todo.completed
        _ -> True

    allCompleted =
      List.all .completed entries

    cssVisibility =
      if List.isEmpty entries then "hidden" else "visible"
  in
    section
      [ class "main"
      , style "visibility" cssVisibility
      ]
      [ input
          [ class "toggle-all"
          , type_ "checkbox"
          , name "toggle"
          , checked allCompleted
          , onClick (CheckAll (not allCompleted))
          ]
          []
      , label
          [ for "toggle-all" ]
          [ text "Mark all as complete" ]
      , ul [ class "todo-list" ] <|
          List.map viewEntry (List.filter isVisible entries)
      ]



-- VIEW INDIVIDUAL ENTRIES


viewEntry : Entry -> Html Msg
viewEntry todo =
  li
    [ classList [ ("completed", todo.completed), ("editing", todo.editing) ] ]
    [ div
        [ class "view" ]
        [ input
            [ class "toggle"
            , type_ "checkbox"
            , checked todo.completed
            , onClick (Check todo.id (not todo.completed))
            ]
            []
        , label
            [ onDoubleClick (EditingEntry todo.id True) ]
            [ text todo.description ]
        , button
            [ class "destroy"
            , onClick (Delete todo.id)
            ]
            []
        ]
    , input
        [ class "edit"
        , value todo.description
        , name "title"
        , id ("todo-" ++ String.fromInt todo.id)
        , onInput (UpdateEntry todo.id)
        , onBlur (EditingEntry todo.id False)
        , onEnter (EditingEntry todo.id False)
        ]
        []
    ]



-- VIEW CONTROLS AND FOOTER


viewControls : String -> List Entry -> Html Msg
viewControls visibility entries =
  let
    entriesCompleted =
      List.length (List.filter .completed entries)

    entriesLeft =
      List.length entries - entriesCompleted
  in
    footer
      [ class "footer"
      , hidden (List.isEmpty entries)
      ]
      [ viewControlsCount entriesLeft
      , viewControlsFilters visibility
      , viewControlsClear entriesCompleted
      ]


viewControlsCount : Int -> Html Msg
viewControlsCount entriesLeft =
  let
    item_ =
      if entriesLeft == 1 then " item" else " items"
  in
    span
      [ class "todo-count" ]
      [ strong [] [ text (String.fromInt entriesLeft) ]
      , text (item_ ++ " left")
      ]


viewControlsFilters : String -> Html Msg
viewControlsFilters visibility =
  ul
    [ class "filters" ]
    [ visibilitySwap "#/" "All" visibility
    , text " "
    , visibilitySwap "#/active" "Active" visibility
    , text " "
    , visibilitySwap "#/completed" "Completed" visibility
    ]


visibilitySwap : String -> String -> String -> Html Msg
visibilitySwap uri visibility actualVisibility =
  li
    [ onClick (ChangeVisibility visibility) ]
    [ a [ href uri, classList [("selected", visibility == actualVisibility)] ]
        [ text visibility ]
    ]


viewControlsClear : Int -> Html Msg
viewControlsClear entriesCompleted =
  button
    [ class "clear-completed"
    , hidden (entriesCompleted == 0)
    , onClick DeleteComplete
    ]
    [ text ("Clear completed (" ++ String.fromInt entriesCompleted ++ ")")
    ]


infoFooter : Html msg
infoFooter =
  footer [ class "info" ]
    [ p [] [ text "Double-click to edit a todo" ]
    , p []
        [ text "Written by "
        , a [ href "https://github.com/evancz" ] [ text "Evan Czaplicki" ]
        ]
    , p []
        [ text "Part of "
        , a [ href "http://todomvc.com" ] [ text "TodoMVC" ]
        ]
    ]
