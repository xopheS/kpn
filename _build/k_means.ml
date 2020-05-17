module Vector = struct 

  type point = float array

  let zeros (n : int): point = Array.make n (0.)

  let l2_distance (x : point) (y : point): float =  
    sqrt (Array.fold_left( +. ) 0. (Array.map2 (fun x y -> (x -. y)**2.) x y))

  let vectorized_binary_op f x y= 
    Array.map2 f x y

  let satisfies predicate x: bool = 
    Array.for_all predicate x

  let string_of_vector vect =
    vect |> Array.map string_of_float |> Array.to_list |> 
    String.concat ", " |> Format.sprintf "(%s)"
    
  
end





module K_means (K : Kahn.S) = struct
  module K = K
  module Lib = Kahn.Lib(K)
  open Lib 
  open Vector

  type label = int

  let number_of_proc = ref 0
 
  let split_workload (a : 'a array) (r : int) : 'a array list = 
    let n = Array.length a in
    let m = n / r + 1 in 
    let l = n mod r in 
    let it = min r n in
    let rec split a k acc s = 
      if (k < it) then (
        if (k < l) then split a (k+1) ((Array.sub a (k*s) m) :: acc) m else split a (k+1) ((Array.sub a (k*s) (m-1)) :: acc) (m-1)
      )
      else List.rev acc
    in 
    split a 0 [] m


  let parallel_map ?(n_p = !number_of_proc) f a =
    Array.concat (par_map (fun x -> Array.map f x) (split_workload a n_p))


  let parallel_group_by ?(n_p = !number_of_proc) f a possible_values =
    let s_partition x l b: 'a list = if (f x b) then (snd b)::l else l 
    in
    parallel_map (fun x -> Array.fold_left (s_partition x) [] a) possible_values
    
  let shuffle_in_place points =
    Random.self_init ();
    let n = Array.length points in
    for i = 0 to n-2 do
      let k = Random.int (n-i) in
      let tmp = points.(i) in
      points.(i) <- points.(i+k);
      points.(i+k) <- tmp 
    done
  
  let rec initialize_means (k : int) (points : (point * label) array) : point array =
    parallel_map (fun x -> fst x) (Array.sub points 0 k)


  let classify ?(distance_function = l2_distance) (points : (point*label) array) (means : point array)  =
    (* coded in imperative style otherwise too heavy on memory *)
    let find_closest (x : (point*label)) : point =
      let n = (Array.length means) - 1  in 
      let closest = ref (means.(0)) in 
      let minDistance = ref (distance_function means.(0) (fst x))in
      for i = 1 to n do
        let tmp = ref (distance_function (fst x) means.(i)) in
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
   
   
    
    
  let update (points: (point*label) list array) = 
    let find_average p = 
      let n = float_of_int (List.length p) in 
      let d = Array.length (fst (List.hd p)) in
      Array.map (fun x -> x /. n) 
      (List.fold_left 
      (fun x y -> vectorized_binary_op (+.) x (fst y)) 
      (zeros d) 
      p) 
    in
    parallel_map find_average points

  let stop_cnd old_means new_means epsilon =
    satisfies (fun x -> x < epsilon) 
    (parallel_map (fun x -> l2_distance (fst x) (snd x)) 
    (vectorized_binary_op (fun x y -> (x, y)) old_means new_means))




end

module Iris_K_means (K: Kahn.S) = struct 

  module K = K
  module Lib = Kahn.Lib(K)
  module K_means = K_means(K)
  open K_means

  let k = ref 3 
  let number_of_processes = ref 10
  let epsilon = ref 0.001
  let training_perc = ref 0.9
  let labels = [|1; 0;-1|]
  let show = ref true
  let x_axis = ref 2
  let y_axis = ref 1 

  let preprocess_data path = 
    let import_data path separator: float array array =
      let reg_separator = Str.regexp separator in
      let value_list = ref [] in
      try
        let ic = open_in path in
        (* Skip the first line, columns headers *)
        let _ = input_line ic in
        try
          while true; do
            (* Create a list of values from a line *)
            let line_list = Str.split_delim reg_separator (input_line ic) in
            let tmp = Array.of_list (List.map float_of_string line_list) in
            value_list := tmp::(!value_list);
          done;
            Array.of_list (!value_list)
        with 
          | End_of_file -> close_in ic; Array.of_list (!value_list)
      with
        | e -> raise e
    in 
    let get_values_labels (data: float array array): (float array * int) array =
      let d = (Array.length (data.(0))) - 1 in
      parallel_map (fun x -> ((Array.sub x 0 d), int_of_float x.(d))) data
    in  
    let seperate_to_training_and_test (data:(float array * int) array) : ((float array * int) array * (float array * int) array)  =
      let n = Array.length data in 
      let l = int_of_float ((float_of_int n) *. !training_perc) in
      shuffle_in_place data; 
      (Array.sub data 0 l, Array.sub data l (n-l))
    in
    seperate_to_training_and_test (get_values_labels (import_data path  ",")) 

  let test acc points = 
    let partition_by_label l = 
      Array.fold_left (max) 0 (parallel_map (fun label -> List.length (fst (List.partition (fun x -> (snd x) = label) l))) labels)
    in
    let p = parallel_map (partition_by_label) points in
    let s = float_of_int (Array.fold_left (+) 0 p) in 
    let q = float_of_int (Array.fold_left (fun x y -> x + (List.length y)) 0 points) in 
    (s /. q) :: acc


  let exec training_data test_data = 
    let rec aux means acc_training acc_test = 
      let p_tr = classify training_data means in
      let p_te = classify test_data means in
      let nm = update p_tr in 
      if (stop_cnd means nm !epsilon) then 
        nm, (List.rev acc_training), (List.rev acc_test), p_tr
      else 
        aux nm (test acc_training p_tr) (test acc_test p_te)
    in 
    aux (initialize_means !k training_data) [] []

  let show_points points centers =
    let width = float_of_int @@ Graphics.size_x () in
    let height = float_of_int @@ Graphics.size_y () in
    let get_min (x_min, x_max, y_min, y_max) point =
      let x_min = min x_min (fst point).(!x_axis) in
      let x_max = max x_max (fst point).(!x_axis) in
      let y_min = min y_min (fst point).(!y_axis) in
      let y_max = max y_max (fst point).(!y_axis) in
      x_min, x_max, y_min, y_max
    in
    let arr = 
      parallel_map 
      (fun x -> 
        let p = (fst (List.hd x)) in 
        List.fold_left get_min 
        (p.(!x_axis), p.(!x_axis), p.(!y_axis), p.(!y_axis)) 
        x
      ) 
      points
    in 
    let x_min, x_max, y_min, y_max =
      Array.fold_left 
      (fun (x_min, x_max, y_min, y_max) (x_min', x_max', y_min', y_max') -> 
      let x_min = min x_min x_min' in
      let x_max = max x_max x_max' in
      let y_min = min y_min y_min' in
      let y_max = max y_max y_max' in
      x_min, x_max, y_min, y_max) 
      arr.(0)
      arr
    in
    let x_margin = (x_max -. x_min) /. 15. in
    let y_margin = (y_max -. y_min) /. 15. in
    let x_min = x_min -. x_margin in
    let x_max = x_max +. x_margin in
    let y_min = y_min -. y_margin in
    let y_max = y_max +. y_margin in
    let plt_point point =
      let x_int = int_of_float @@ ((fst point).(!x_axis)-.x_min) /. (x_max-.x_min) *. width in
      let y_int = int_of_float @@ ((fst point).(!y_axis)-.y_min) /. (y_max-.y_min) *. height in
      Graphics.fill_circle x_int y_int 5
    in
    let plt_center point =
      let x_int = int_of_float @@ (point.(!x_axis)-.x_min) /. (x_max-.x_min) *. width in
      let y_int = int_of_float @@ (point.(!y_axis)-.y_min) /. (y_max-.y_min) *. height in
      Graphics.fill_circle x_int y_int 10
    in
    List.iter (plt_point) points.(0);
    Graphics.set_color Graphics.red;
    List.iter (plt_point) points.(1);
    Graphics.set_color Graphics.green;
    List.iter (plt_point) points.(2);
    Graphics.set_color Graphics.blue;
    Array.iter (plt_center) centers

  let plot training test = 
    let rec print_numbers oc = function 
      | [] -> ()
      | [e] -> Printf.fprintf oc "%f" e; ()
      | e::tl -> Printf.fprintf oc "%f, " e; print_numbers oc tl
    in
    let tr = open_out "training_accuracy.txt" in
    let te = open_out "test_accuracy.txt" in
    print_numbers tr training;
    print_numbers te test;
    close_out tr;
    close_out te;
    ignore (Sys.command "python plot.py")
    

  let main : unit K.process =
    let run () =  
      let path = "iris.data" in
      number_of_processes := int_of_string Sys.argv.(1); 
      K_means.number_of_proc := !number_of_processes;
      let training, test = preprocess_data path in 
      let means, training_accuracy, test_accuracy, points_classified = exec training test in
      plot training_accuracy test_accuracy;
      Graphics.open_graph ""; 
      show_points points_classified means;
      ignore (Graphics.read_key ())
    in
    Lib.delay run ()
    
end   



module E = Iris_K_means(Kahn.Th)
let () = E.K.run(E.main)