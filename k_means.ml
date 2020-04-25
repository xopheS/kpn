module K_means (K : Kahn.S) = struct
  module K = K
  module Lib = Kahn.Lib(K)
  open Lib 

  type point = float array

  let number_of_proc := 0;;

  let parrallel_map f l: a' list =
    let rec take k tail head  = 
      match k with
        | 0 -> (head, tail)
        | k -> 
          match tail with
            | [] -> (head, tail)
            | y::ys -> take k-1 ys head @ [y]
    in
    let rec aux f l acc =
      let (x, y) = take number_of_proc l [] in
        match y with 
        | [] -> acc @ (par_map f x)
        | y::ys -> aux f y (acc @ (par_map f x))
    in 
    aux f l []


  let l2_distance (x: point) (y: point) : float = 
    let d = Array.create_float (Array.length x) in 
    sqrt (Array.fold_left( +. ) 0 (Array.map (fun _ -> (x -. y)**2) d))
  
  let rec initialize_means (k : int) (points : point array) : point list =

    let rec distinct_random_sequence upperbound number_of_points list_of_indices: int list =
      match number_of_points with 
        | 0 -> list_of_indices
        | number_of_points ->
          let r =  Random.int upperbound in 
          if (List.mem r list_of_indices) then distinct_random_sequence upperbound number_of_points list_of_indices
          else distinct_random_sequence upperbound number_of_points-1 r::list_of_indices
    in  

    let l = distinct_random_sequence (Array.length points) k [] in 
      parrallel_map (fun i -> Array.copy points.(i)) l 


  let classify (points : point array) (means : point list) distance_function : point array =
    (* coded in imperative style otherwise too heavy on memory *)
    let find_closest x : point =
      let n = Array.length means in 
      let closest := ref means.(0)
      let minDistance := ref (distance_function means.(0) x) 
      for i = 1 to n do
        let tmp := ref (distance_function x means.(i))
        if tmp < minDistance then begin 
          closest := means.(i);
          minDistance := !tmp;
        end
      done
      closest 
    in 

    let group_by f l =
      let rec grouping acc = function
      | [] -> acc
      | hd::tl ->
        let l1,l2 = List.partition (f (fst hd)) tl in
        grouping (acc @ [((snd hd)::l1))]) l2
      in 
      grouping [] l
    in 

    group_by (fun x y -> fst x = fst y) (parrallel_map (fun x -> ((find_closest x), x)) (Array.to_list points))
    
  let update points means = 
    let vectorize f a b=
      let n = Array.length a in 
      let c = Array.copy a in
      for i = 0 to n do 
        c.(i) <- (f a.(i) b.(i));
      done
    c
    in

    let find_average p = 
      let n = Array.length p in
      List.map (fun x -> x /. n ) (List.fold_left (vectorize +.) p) 
    in

    parrallel_map find_average points

  let converged old_means new_means epsilon =
    (parrallel_map (fun x -> (l2_distance (fst x) (snd x)) < epsilon) (List.combine old_means new_means))


  let main : unit K.process =
    let K_means points means =
      let p = classify points means in
      let nm = update p means in 
      if (converged means nm) then 
        nm
      else 
       K_means points nm 
    in 


end


module E = K_means(Unix_pipes.Z)

let () = E.K.run E.main