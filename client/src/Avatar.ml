open Prelude
open Types

let avatarUrl (email : string) (name : string option) : string =
  (* Digest.string is Bucklescript's MD5 *)
  let digestedEmail = Digest.to_hex (Digest.string email) in
  let fallback (name : string option) =
    match name with
    | None | Some "" ->
        (* 'retro' is a fallback style:
         * https://en.gravatar.com/site/implement/images/ *)
        "retro"
    | Some name ->
        let initials =
          String.split_on_char ' ' name
          |> List.map (fun s -> String.make 1 s.[0])
          |> String.concat "+"
        in
        (* TODO: we can set bg/fg color, font size/color/weight, make it
         * circular: https://ui-avatars.com/
         * Note that since we're using this with gravatar, we want the
         * nested-dir style format, not the query param format *)
        "https://ui-avatars.com/api" ^ "/" ^ initials
  in
  (* TODO: add a s= param to set the size in pixels *)
  "https://www.gravatar.com/avatar/"
  ^ digestedEmail
  ^ "?d="
  ^ Js_global.encodeURI (fallback name)


let avatarDiv (avatar : avatar) : msg Html.html =
  let name : string option = avatar.fullName in
  let email : string = avatar.email in
  let username : string = avatar.username in
  let avActiveTimestamp : float = avatar.activeTimestamp in
  let threeMinsAgo : float = Js.Date.now () -. 180000.00 in
  let active : bool = threeMinsAgo < avActiveTimestamp in
  Html.img
    [ Html.classList [("avatar", true); ("inactive", active)]
    ; Html.src (avatarUrl email name)
    ; Vdom.prop "alt" username ]
    []


let avatarsView (avatars : avatarsList) : msg Html.html =
  let renderAvatar (a : avatar) = avatarDiv a in
  let avatars = List.map renderAvatar avatars in
  Html.div [Html.class' "avatars"] avatars


let allAvatarsView (avatars : avatarsList) : msg Html.html =
  let avatars = List.map avatarDiv avatars in
  Html.div
    [Html.class' "all-avatars"]
    [Html.div [Html.class' "avatars-wrapper"] avatars]