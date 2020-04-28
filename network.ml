(* This file is a quick implementation of the kahn network 
 * especially used for the example.ml *)

open Unix

module N : Kahn.S = 
struct  
  type 'a process = unit -> 'a
  type 'a in_port = Unix.file_descr
  type 'a out_port = Unix.file_descr

  let port = 1024

  let new_channel() = 
    (* Create a STREAM socket with IPv4/IPv6 address *)
    let host = Unix.inet_addr_loopback in
    (* let host = Unix.inet6_addr_loopback in *)
    let addr = ADDR_INET (host, port) in
    let in_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in
    let out_socket = socket (domain_of_sockaddr addr) SOCK_STREAM 0 in
    
    (* Connect/Bind/Listen input and the output sockets *)
    bind out_socket addr ;
    listen out_socket 1 ;
    connect in_socket addr ;

    let out_socket, sockaddr = accept out_socket in
    (in_socket, out_socket)
  
  let put v outp = assert false;

  let get inp = assert false;

  let return v = (fun () -> v);

  let bind p1 p2 = assert false; 

  let doco l = assert false;

  let run f = f ();

end



