open Tc
open Prelude
open Types

(* Dark *)
module B = Blank

type viewState = ViewUtils.viewState

let fontAwesome = ViewUtils.fontAwesome

type fnExecutionStatus =
  | Unsafe
  | IncompleteArgs
  | Ready
  | Executing
  | Replayable
  | NoPermission

let fnExecutionStatus
    (vs : viewState) (fn : function_) (id : id) (args : id list) =
  let isComplete id =
    match Analysis.getLiveValue' vs.analysisStore id with
    | None ->
        false
    | Some (DError _) ->
        false
    | Some DIncomplete ->
        false
    | Some _ ->
        true
  in
  let paramsComplete = List.all ~f:isComplete args in
  let resultHasValue = isComplete id in
  let name = fn.fnName in
  if vs.permission <> Some ReadWrite
  then NoPermission
  else if name = "Password::check" || name = "Password::hash"
  then Unsafe
  else if not paramsComplete
  then IncompleteArgs
  else if List.member ~value:id vs.executingFunctions
  then Executing
  else if resultHasValue
  then Replayable
  else Ready


let executionClass status =
  match status with
  | Unsafe ->
      "execution-button-unsafe"
  | IncompleteArgs ->
      "execution-button-unavailable"
  | Ready ->
      "execution-button-needed"
  | Executing ->
      "execution-button-needed is-executing"
  | Replayable ->
      "execution-button-repeat"
  | NoPermission ->
      "execution-button-unavailable"


let executionTitle status =
  match status with
  | Unsafe ->
      "Cannot run interactively for security reasons"
  | IncompleteArgs ->
      "Cannot run: some parameters are incomplete"
  | Ready ->
      "Click to execute function"
  | Executing ->
      "Function is executing"
  | Replayable ->
      "Click to execute function again"
  | NoPermission ->
      "You do not have permission to execute this function"


let executionError status =
  match status with
  | Unsafe ->
      "Cannot run interactively for security reasons"
  | IncompleteArgs ->
      "Cannot run: some parameters are incomplete"
  | Ready ->
      "Click Play to execute function"
  | Executing ->
      "Function is executing"
  | Replayable ->
      "Click to execute function again"
  | NoPermission ->
      "You do not have permission to execute this function"


let executionIcon status =
  match status with
  | Unsafe | NoPermission ->
      "times"
  | IncompleteArgs | Ready | Executing ->
      "play"
  | Replayable ->
      "redo"


let executionEvents status tlid id name =
  match status with
  | Unsafe | Executing | IncompleteArgs | NoPermission ->
      []
  | Ready | Replayable ->
      [ ViewUtils.eventNoPropagation
          ~key:("efb-" ^ showTLID tlid ^ "-" ^ showID id ^ "-" ^ name)
          "click"
          (fun _ -> ExecuteFunctionButton (tlid, id, name))
      ; ViewUtils.nothingMouseEvent "mouseup"
      ; ViewUtils.nothingMouseEvent "mousedown"
      ; ViewUtils.nothingMouseEvent "dblclick" ]


let fnExecutionButton
    (vs : viewState) (fn : function_) (id : id) (args : id list) =
  let name = fn.fnName in
  let status = fnExecutionStatus vs fn id args in
  if fn.fnPreviewExecutionSafe
  then Vdom.noNode
  else
    let class_ = executionClass status in
    let title = executionTitle status in
    let icon = executionIcon status in
    let events = executionEvents status vs.tlid id name in
    Html.div
      ([Html.class' ("execution-button " ^ class_); Html.title title] @ events)
      [fontAwesome icon]