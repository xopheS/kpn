(* ---------------------------------------------------------         *)
(* socket implementation of Khan running in two computers            *)
(* To run the code in one machine with 2 terminals uncomment/comment *)
(* these lines "(*Uncomment for LOCAL *)" and in the cmd make sure   *)
(* to have the port number for the client 1 more than the port       *)
(* number for the server i.e. -port 1025                             *)
(* ---------------------------------------------------------         *)

open Unix
exception Superweird

module N2W : Kahn.S = struct  

  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

  let port = ref 1024
  let set_port portnb = Format.printf "Set port %d" (portnb); port := portnb

  let new_channel () = 
    let host = Unix.inet_addr_any in 
    Format.printf "%! Server's IP address %s:%i@\n@?\n" (Unix.string_of_inet_addr host) !port;
    let addr = ADDR_INET (host, !port) in
    let out_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in 
    let () = Unix.setsockopt out_socket Unix.SO_REUSEADDR true in

    bind out_socket addr; 
    Format.printf "%! Listening for Clients..\n";
    listen out_socket 1; 

    let (out_socket, addr2) = accept out_socket in
    let client_name = match addr2 with 
      | ADDR_INET (a,p) -> a
      | _ -> raise Superweird
    in
    Format.printf "%! Got Client IP address %s:%i@\n@?\n" (Unix.string_of_inet_addr client_name) !port;
    (*port := !port + 1;*) (* Uncomment for LOCAL *)

    let client_addr = Unix.ADDR_INET (client_name, !port) in 
    port := !port + 1; (* Comment for LOCAL *)
    let in_socket = socket (domain_of_sockaddr client_addr) SOCK_STREAM 0 in 
    connect in_socket client_addr;
    Format.printf "%! Connection established.";
    Format.printf "%!\n";
    (in_socket, out_socket)

  let connect_by_name host_ip =
    Format.printf "%! Server's IP address %s:%i@\n@?\n" (host_ip) !port;
    let localhost = Unix.inet_addr_any in
    let addr = ADDR_INET (localhost, !port) in
    let out_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in 
    let in_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in 

    bind out_socket addr;
    Format.printf "%! Listening for Host \n";
    listen out_socket 1;

    let host = Unix.inet_addr_of_string host_ip in
    let host_addr = Unix.ADDR_INET (host, !port) in (* Comment for LOCAL *)
    (*let host_addr = Unix.ADDR_INET (host, !port - 1) in*) (* Uncomment for LOCAL *)
    connect in_socket host_addr;
    let (out_socket, _) = accept out_socket in
    Format.printf "%! Connection established.";
    Format.printf "%!\n";
    (in_socket, out_socket) 

  let close_channel in_sock out_sock = 
    shutdown in_sock SHUTDOWN_ALL;
    shutdown out_sock SHUTDOWN_ALL

  let put value output = 
    (fun () -> let data = Marshal.to_bytes value [] in
    ignore( Unix.send output data 0 (Bytes.length data) []))

  let get input = 
    (fun () -> let header = Bytes.create Marshal.header_size in
              Unix.recv input header 0 Marshal.header_size [] |> ignore ;
              let d_size = Marshal.data_size header 0 in
              let data = Bytes.create d_size in
              Unix.recv input data 0 d_size [] |> ignore ;
              (Marshal.from_bytes (Bytes.cat header data) 0))

  let return value = (fun () -> value)

  let bind p f = (fun () -> f (p()) ()) 

  let doco l = 
    (fun() -> 
      let rec sub = function 
      | [] -> ()
      | x :: th -> begin 
                  let thread = Thread.create x () in               
                  sub th; Thread.join thread 
                  end 
    in sub l)

  let run f = f ()

end

