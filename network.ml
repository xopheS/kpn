(* This file is a quick implementation of the kahn network 
 * especially used for the example.ml *)

open Unix

module N : Kahn.S = 
struct  
  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

  let port = ref 1024

  let new_channel() = 
    (* Create a STREAM socket with IPv4/IPv6 address *)
    let host = Unix.inet_addr_loopback in
    (* let host = Unix.inet6_addr_loopback in *)
    let addr = ADDR_INET (host, !port) in
    port := !port + 1;
    let in_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in
    let out_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in
    
    (* Connect/Bind/Listen input and the output sockets *)
    bind out_socket addr ;
    listen out_socket 100 ;
    connect in_socket addr ;

    let out_socket, sockaddr = accept out_socket in
    (in_socket, out_socket)
  
  let put value output = 
          (fun () -> let data = Marshal.to_bytes value [] in
          ignore( Unix.send output data 0 (Bytes.length data) []))

  let get input = 
          (fun () ->    let header = Bytes.create Marshal.header_size in
                        Unix.recv input header 0 Marshal.header_size [] |> ignore ;
                        let d_size = Marshal.data_size header 0 in
                        let data = Bytes.create d_size in
                        Unix.recv input data 0 d_size [] |> ignore ;
                        (Marshal.from_bytes (Bytes.cat header data) 0)
                     )

  let return value = (fun () -> value)

  let bind p f = (fun () -> f (p()) ()) 

  let delay f x = bind (return ()) (fun () -> return (f x))

  let doco l = 
          ( fun() -> let rec sub = function 
                  | [] -> ()
                  | x :: th -> 
                        begin 
                          let thread = Thread.create x () in               
                          sub th; Thread.join thread 
                        end 
           in sub l)

  let run f = f ()

end

