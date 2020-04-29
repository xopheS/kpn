module Vector = struct 

  type point = float array

  let zeros (n : int): point = Array.make n 0.

  let l2_distance (x : point) (y : point): float =  
    sqrt (Array.fold_left( +. ) 0. (Array.map2 (fun x y -> (x -. y)**2.) x y))

  let vectorized_binary_op f (x : point) (y : point): point = 
    Array.map2 f x y

  let satisfies predicate (x : point): bool = 
    Array.for_all predicate x
    
  
end





module K_means (K : Kahn.S) = struct
  module K = K
  module Lib = Kahn.Lib(K)
  open Lib 
  open Vector


  let number_of_proc = ref 0;;
 
  let split_workload (a : 'a array) (r : int) : 'a array list = 
    let n = Array.length a in
    let m = n / r + 1 in 
    let l = n mod r in 
    let it = min r n in
    let rec split a k acc s = 
      match k with 
      | it -> List.rev acc
      | k -> if (k < l) then split a (k+1) ((Array.sub a (k*s) m) :: acc) m else split a (k+1) ((Array.sub a (k*s) (m-1)) :: acc) (m-1)
    in 
    split a 0 [] m


  let parallel_map ?(n_p = !number_of_proc) f (a : 'a array) : 'a array =
    Array.concat (par_map (fun x -> Array.map f x) (split_workload a !number_of_proc))


  let parallel_group_by ?(n_p = !number_of_proc) f a possible_values: 'a list array =
    let s_partition l b = if (fst b) then (snd b)::l else l 
    in
    let outter = min n_p (Array.length possible_values) in
    let inner = (max n_p (Array.length possible_values)) / outter in
    parallel_map ~n_p:outter (fun x -> Array.fold_left s_partition [] (parallel_map ~n_p:outter (f x) a)) possible_values
   (* let group_by f l =
            let rec grouping acc = function
      | [] -> acc
      | hd::tl ->
        let l1,l2 = List.fold_left s_partition [] List.map (f (fst hd)) tl in
        grouping (((snd hd)::l1) :: acc) l2
      in *
      grouping [] l
    in 
    *)

    

  
  let rec shuffle_and_initialize_means (k : int) (points : point array) : point array =

    let shuffle_in_place =
      Random.self_init ();
      let n = Array.length points in
      for i = 0 to n-2 do
        let k = Random.int (n-i) in
        let tmp = points.(i) in
        points.(i) <- points.(i+k);
        points.(i+k) <- tmp 
      done
    in

    (* let rec distinct_random_sequence upperbound number_of_points list_of_indices: int list =
      match number_of_points with 
        | 0 -> list_of_indices
        | number_of_points ->
          let r =  Random.int upperbound in 
          if (List.mem r list_of_indices) then distinct_random_sequence upperbound number_of_points list_of_indices
          else distinct_random_sequence upperbound number_of_points-1 r::list_of_indices
    in  

    let l = distinct_random_sequence (Array.length points) k [] in 
      parrallel_map (fun i -> Array.copy points.(i)) l *)


      shuffle_in_place;
      Array.sub points 0 k


  let classify (points : point array) (means : point array) distance_function : point array =
    (* coded in imperative style otherwise too heavy on memory *)
    let find_closest x : point =
      let n = Array.length means in 
      let closest = ref (means.(0)) in 
      let minDistance = ref (distance_function means.(0) x)in
      for i = 1 to n do
        let tmp = ref (distance_function x means.(i)) in
        if tmp < minDistance then begin 
          closest := means.(i);
          minDistance := !tmp
        end;
      done;
      !closest 
    in 
    parallel_group_by
     (fun x y -> ((x = (fst y)), (snd y))) 
     (parallel_map (fun x -> ((find_closest x), x)) points) 
     means
    
    
  let update points means = 
    let find_average p = 
      let n = Array.length p in
      let d = Array.length p.(0) in
      Array.map (fun x -> x /. n ) (List.fold_left (vectorized_binary_op (+.)) (zeros d) p) 
    in
    parrallel_map find_average points

  let stop_cnd old_means new_means epsilon =
    satisfies (fun x -> x < epsilon) 
    (parrallel_map (fun x -> l2_distance (fst x) (snd x)) (vectorized_binary_op (fun x y -> (x, y)) old_means new_means))


  let main : unit K.process =


    let exec points means =
      let p = classify points means in
      let nm = update p means in 
      if (converged means nm) then 
        nm
      else 
       exec points nm 
    in 
    let a = Array.make_matrix 20 3 in 
    exec a (initialize_means 2 a)


end


module E = K_means(Unix_pipes.Z)

let () = E.K.run E.main