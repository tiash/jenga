
open Core.Std

let return = Dep.return
let ( *>>= ) = Dep.bind
let ( *>>| ) = Dep.map

let putenv = Dep.Reflect_putenv

let from_alias x = Dep.Reflect_alias x *>>| Path.Set.to_list
let from_path x = Dep.Reflect_path x

let reachable ~keep ?stop =
  let stop =
    match stop with
    | Some f -> f
    | None -> (fun x -> not (keep x))
  in
  let rec collect ~acc_trips ~acc_targets = function
    | [] -> return acc_trips
    | path::paths ->
      let skip() = collect ~acc_trips ~acc_targets paths in
      if List.mem acc_targets path
      then skip()
      else
        match stop path with
        | true -> skip()
        | false ->
          from_path path *>>= function
          | None -> skip()
          | Some trip ->
            let acc_trips =
              if keep path
              then trip::acc_trips
              else acc_trips
            in
            collect
              ~acc_trips
              ~acc_targets:(trip.Reflected.Trip.targets @ acc_targets)
              (trip.Reflected.Trip.deps @ paths)
  in
  fun roots ->
    collect ~acc_trips:[] ~acc_targets:[] roots

let path = from_path
let alias = from_alias
