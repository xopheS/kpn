module K_means (K : Kahn.S) (D : int) = struct
  module K = K
  module Lib = Kahn.Lib(K)
  open Lib 

  type point = float array
  
  let rec initializeMeans (k : int) (points : point array)  : point array =

    (* auxiliary functions given no libraries exist for my needs ... *)

    let rec distinct_random_sequence upperbound number_of_points l: int list =
      if number_of_points = 0 then l
      else begin
        let r =  Random.int upperbound in 
        if l.exists (fun x () -> l = r) then distinct_random_sequence upperbound number_of_points l
        else distinct_random_sequence upperbound number_of_points-1 r::l
      end
    in
    let rec init a l i =
      match l with
      | [] -> a
      | h :: t -> 
          a.(i) = points.(h);
          init a t i+1
    in 
    let l = distinct_random_sequence (length points) [] in 
      init (make k points.(0)) l k


  let find_closest (points : point array) (means : point array) : unit K.process =
    let rec loop () =
      (K.get qi) >>= (fun v -> Format.printf "%d@." v; loop ())
    in
    loop ()

  let main : unit K.process =
    (delay K.new_channel ()) >>=
    (fun (q_in, q_out) -> K.doco [ integers q_out ; output q_in ; ])

end


module E = K_means(Unix_pipes.Z)

let () = E.K.run E.main