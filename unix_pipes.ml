module I : Kahn.S =
struct
  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

let new_channel() =
  Unix.pipe()

let run f () = 
  f()

let bind f g () =
  let returned_value = f() in 
  g returned_value ()

let return v =
  (fun () -> v)

let put v outp =
  (fun () ->
    let data = Marshal.to_bytes v [] in
    ignore (Unix.write outp data 0 (Bytes.length data))
  )

let get inp =
  (fun () ->
    let header = Bytes.create Marshal.header_size in
    Unix.read inp header 0 Marshal.header_size |> ignore ;
    let sz = Marshal.data_size header 0 in

    let data = Bytes.create sz in
    Unix.read inp data 0 sz |> ignore ;
    Marshal.from_bytes (Bytes.cat header data) 0

  )