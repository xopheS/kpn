module Vector = struct 

  type point = float array

  let zeros (n : int): point = Array.make n (0.)

  let l2_distance (x : point) (y : point): float =  
    sqrt (Array.fold_left( +. ) 0. (Array.map2 (fun x y -> (x -. y)**2.) x y))

  let vectorized_binary_op f x y= 
    Array.map2 f x y

  let satisfies predicate x: bool = 
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


  let parallel_map ?(n_p = !number_of_proc) f a =
    Array.concat (par_map (fun x -> Array.map f x) (split_workload a n_p))


  let parallel_group_by ?(n_p = !number_of_proc) f a possible_values =
    let s_partition (x : 'a) (l: 'a list) (b: ('a * 'a)): 'a list = if (f x b) then (snd b)::l else l 
    in
    let outter = min n_p (Array.length possible_values) in
    let inner = (max n_p (Array.length possible_values)) / outter in
    parallel_map ~n_p:outter (fun x -> Array.fold_left (s_partition x) [] a) possible_values
   (* let group_by f l =
            let rec grouping acc = function
      | [] -> acc
      | hd::tl ->
        let l1,l2 = List.fold_left s_partition [] List.map (f (fst hd)) tl innumber_of_proc
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


  let classify (points : point array) (means : point array) distance_function : point list array =
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
     (fun x y -> x = (fst y))
     (parallel_map (fun x -> ((find_closest x), x)) points) 
     means
    
    
  let update points means = 
    let find_average p = 
      let n = float_of_int (List.length p) in 
      let d = Array.length (List.hd p) in
      Array.map (fun x -> x /. n) 
      (List.fold_left (vectorized_binary_op (+.)) (zeros d) p) 
    in
    parallel_map find_average points

  let stop_cnd old_means new_means epsilon =
    satisfies (fun x -> x < epsilon) 
    (parallel_map (fun x -> l2_distance (fst x) (snd x)) 
    (vectorized_binary_op (fun x y -> (x, y)) old_means new_means))



  let rec exec points means epsilon number_of_processes =
    number_of_proc := number_of_proc;
    let p = classify points means l2_distance in
    let nm = update p means in 
    if (stop_cnd means nm epsilon) then 
      nm
    else 
      exec points nm 


end

module Run_K_means (K: Kahn.S) = struct 

  open K_means

  let k = ref 0 
  let dimension = ref 0 
  let data_size = ref 0
  let number_of_processes = ref 10

  let path_name = ref ""
  let output_file = ref "K_means_output.txt"

  let plot = ref True

  let usage = 
    "Usage: " ^ Sys.argv.(0) ^ " [options] <filename>" ^
    "\nOptions:"

  let options =
    [ "-k", Arg.Set_int k,
      " number of clusters k in the algorithm";
      "-d", Arg.Int (fun i -> d := Some i),
      " dimension of data examples (must be consistent with the data)";
      "-p", Arg.Set_int number_of_processes,
      " number of parallel processes used in the computation (default 10)";
      "-o", Arg.Set_string output_file,
      " name of the output file (containing cluster centers)";
      "-plot", Arg.Set plot,
      " plot the result's accuracy"; ]

  let parse_cmd () =
    Arg.parse (Arg.align options)
      (fun str -> if str <> "" then
        match !data_file with 
        | None -> data_file := Some str
        | _ -> Format.eprintf 
            "%s: At most one data file can be given.@." Sys.argv.(0); exit 1)
      usage

  let import_data path separator nbr_of_features size =
    let reg_separator = Str.regexp separator in
    let value_array = Array.make_matrix size nbr_of_features 0. in
    let i = ref 0 in
    try
      let ic = open_in file_name in
      (* Skip the first line, columns headers *)
      let _ = input_line ic in
      try
        while true; do
          (* Create a list of values from a line *)
          let line_list = Str.split reg_separator (input_line ic) in
          List.iteri
          (fun j elem -> value_array.(!i).(j) <- float_of_string elem)
          line_list;
          i := !i + 1
        done;
        value_array
      with 
        | End_of_file -> close_in ic; value_array
      with
        | e -> raise e;;

  let get_hyper_parameters 

  

    
end 
module E = K_means(Kahn.Th)

let () = E.K.run E.main