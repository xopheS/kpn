open Unix

module N : Kahn.S =
struct
  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

  let new_channel () = assert false

  let put v out = assert false

  let get inp = assert false 

  let return v = (fun () -> v)

  let bind p1 f = assert false 

  let doco l = assert false

  let run f = f ()


end