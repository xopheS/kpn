open Graphics

module Example (K : Kahn.S) = struct
	
	module K = K
	module Lib = Kahn.Lib(K)
	open Lib
	
	
	(** TYPE COMPLEX WITH SOME OPERATIONS **)
	type complex = float * float
	
	let re ((x , _) : complex) : float = x
	let im ((_ , y) : complex) : float = y
	
	let squared_modulus (z : complex) : float = re z ** 2. +. im z ** 2.
	

	(** MANDELBROT SEQUENCE STEP **)
	let step (z : complex) (c : complex) : complex =
		(re z ** 2. -. im z ** 2. +. re c) , (2. *. re z *. im z +. im c)
		
	
		 
	(** CHANGE PIXEL COORDINATES TO COMPLEX NUMBER **)
	
	let center (v : float) (dim : float) (st : float) : float =
			v -. dim /. 2. -. st 

	let normalize (v : float) (min_val : float) (max_val : float) (dim : float) : float =
			(v +. dim /. 2.) *. (max_val -. min_val) /. dim +. min_val
		


	let scale (x : int) (y : int) (x_st : float) (y_st : float) (width : int) (height : int) (zm : float) : complex =
		
		(** center around (x_st, y_st) and normalize according to zoom scale **)

		let x_cart = center (float_of_int x) (float_of_int width) x_st in
		let r = normalize x_cart (x_st -. zm) (x_st +. zm) (float_of_int width) in

		let y_cart = center (float_of_int y) (float_of_int height) y_st in
		let i = normalize y_cart (y_st -. zm) (y_st +. zm) (float_of_int height) in

		r , i


	(** COLOR FUNCTION OF ITERATION **)	

	let red (v : int) (n_iter : int) : int =
		(**if v = n_iter then 0 else 255**)
		v
	
	let green (v : int ) (n_iter : int) : int = 
		(**if v = n_iter then 0 else 255**)
		v

	let blue (v : int) (n_iter : int) : int =	
		(**if v = n_iter then 0 else 255**)
		v
	

	
	let eval_point (x : int) (y : int) (x_st : float) (y_st : float) (width : int) (height : int) (zm : float) (n_iter : int) : unit = 
		
		let c : complex = scale x y x_st y_st width height zm in
	
		let rec eval_rec (z : complex) (iter : int) : int = 

			if squared_modulus z > 4. || iter = n_iter then
				iter

			else
				eval_rec (step z c) (iter + 1)
		in
		
		let i = eval_rec (0. , 0.) 0 in
		
		Format.printf "(%f , %f, %i)\n" (re c) (im c) i;
		let new_color = rgb (red i n_iter) (green i n_iter) (blue i n_iter) in
		set_color new_color;
		plot x y
	 
		
	let main : unit = 
		open_graph " 1300x1000";
		set_window_title "Mandelbrot";
		for i = 1300 downto 1 do
			for j = 1000 downto 1 do
				eval_point i j (0.) (0.) 1300 1000 1. 255; 
			done;
		done;
		let v = read_line () in
		()


end








module E = Example(Kahn.Th)

let () = E.main
















