module Example (K : Kahn.S) = struct
  module K = K
  module Lib = Kahn.Lib(K)
  open Lib

  type mode = Normal | Server | Client

  let parse_arg() =
    let mode = ref Normal in
    let port = ref 1024 in
    let ipaddr = ref "127.0.0.1" in
    let spec =
      [ "-server",Arg.Unit (fun () -> mode := Server), "run as a server";
        "-client",Arg.Unit (fun () -> mode := Client), "run as a client";
        "-ipaddr", Arg.Set_string ipaddr, "default 127.0.0.1 " ;
        "-port", Arg.Set_int port, "(default 1024)"]
    in
    let usage =
    ("Usage: "^Sys.argv.(0)^" [options] \n"^
     "Options:")
  in
  Arg.parse spec 
    (fun s -> if s <> "" then (Arg.usage spec usage; exit 1)) usage;
    (!mode, !ipaddr, !port)


  let integers (qo : int K.out_port) : unit K.process =
    let rec loop n =
      (K.put n qo) >>= (fun () -> loop (n + 1))
    in
    loop 2

  let output (qi : int K.in_port) : unit K.process =
    let rec loop () =
      (K.get qi) >>= (fun v -> Format.printf "%d@." v; loop ())
    in
    loop ()


(* There are three modes: 
  . Normal: to run example in one machine
  . Client/Server to run example in two machines *)
  let main : unit K.process =
    delay parse_arg () >>= fun (mode,ip, p) -> 
    match mode with 
      | Normal -> 
        (delay K.new_channel ()) >>=
        (fun (q_in, q_out) -> K.doco [ integers q_out ; output q_in ; ])
      |  Client -> delay K.set_port p >>= fun () ->
        (delay K.connect_by_name ip) >>=
        (fun (q_in, q_out) -> integers q_out )
      | Server -> 
        (delay K.new_channel ()) >>=
        (fun (q_in, q_out) -> output q_in )
end


(* 
module E = Example(Sequential.Seq) 
module E = Example(Unix_pipes.Z)
module E = Example(Network.N) 
module E = Example(Network2window.N2W)
*)


module E = Example(Kahn.Th)


let () = E.K.run E.main
