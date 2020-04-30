module Z : Kahn.S = struct

  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

  let new_channel () =
    Unix.pipe()

  let run f = 
    f ()

  let bind f g =
    (fun () -> 
      let r = f () in 
        g r ()
    )
  let return v =
    (fun () -> v)

  let put value output =
    (fun () ->
      let data = Marshal.to_bytes value [] in
      ignore (Unix.write output data 0 (Bytes.length data))
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

  let doco l = 
    (fun () ->
      let rec sub_routine l =
        match l with 
        | [] -> ()
        | p :: r -> 
            begin
              let pid = Unix.fork () in 
                if pid = 0 then (
                  p ();
                  exit 0 ()
                )
                else if pid = -1 then (
                  exit 0 ()
                ) 
                else (
                  sub_routine r;
                  Unix.wait () |> ignore
                )
            end
      in sub_routine l
    )
end