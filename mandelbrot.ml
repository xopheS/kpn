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
	
	
	(** GLOBAL VARIABLES **)
	let width : int ref = ref 1300
	let height : int ref = ref 1000
	let n_iter : int ref = ref 255 
	let origin : complex ref = ref (-0.5 , 0.)
	let zm : float ref = ref 2.	
	

	(** MANDELBROT SEQUENCE STEP **)
	let step (z : complex) (c : complex) : complex =
		(re z ** 2. -. im z ** 2. +. re c) , (2. *. re z *. im z +. im c)
		
	
		 
	(** CHANGE PIXEL COORDINATES TO COMPLEX NUMBER **)
	let center (v : float) (dim : float) (st : float) : float =
			v -. dim /. 2. -. st 

	let normalize (v : float) (min_val : float) (max_val : float) (dim : float) : float =
			(v +. dim /. 2.) *. (max_val -. min_val) /. dim +. min_val
		

	let scale ((x, y) : int * int) : complex =
		
		(** center around (x_st, y_st) and normalize according to zoom scale **)

		let x_cart = center (float_of_int x) (float_of_int !width) (re !origin) in
		let r = normalize x_cart ((re !origin) -. !zm) ((re !origin) +. !zm) (float_of_int !width) in

		let y_cart = center (float_of_int y) (float_of_int !height) (im !origin) in
		let i = normalize y_cart ((im !origin) -. !zm) ((im !origin) +. !zm) (float_of_int !height) in

		r , i


	(** COLOR FUNCTION OF ITERATION **)	
	let red (v : int) : int =
		(**if v = n_iter then 0 else 255**)
		v
	
	let green (v : int ) : int = 
		(**if v = n_iter then 0 else 255**)
		v

	let blue (v : int) : int =	
		(**if v = n_iter then 0 else 255**)
		v
	

	
	let eval_point ((x, y) : int * int) : unit = 
		
		let c : complex = scale (x, y) in
	
		let rec eval_rec (z : complex) (iter : int) : int = 

			if squared_modulus z > 4. || iter = !n_iter then
				iter

			else
				eval_rec (step z c) (iter + 1)
		in
		
		let i = eval_rec (0. , 0.) 0 in
		
		(** Format.printf "(%f , %f, %i)\n" (re c) (im c) i; **)
		let new_color = rgb (red i) (green i) (blue i) in
		set_color new_color;
		plot x y
	 
	
	
	let divide_canvas (width : int) (height : int) (n : int) : int * int =
		(** M_REQUIRE **)
		height / n , width / n

	
	let eval_canvas ((x_st, y_st) : int * int) (cw : int) (ch : int) : unit =
		
		let max_x : int = x_st + cw - 1 in
		let max_y : int = y_st + ch - 1 in
		
		let rec compute_row ((x, y) : int * int) : unit =
			eval_point (x, y);
			if x <= max_x then compute_row (x + 1, y)
		in
		
		let rec compute_col (y : int) : unit =
			compute_row (x_st, y);
			if y <= max_y then compute_col (y + 1)		
		in

		compute_col (y_st)
		
	
	let main : unit = 
		open_graph " 1300x1000";
		set_window_title "Mandelbrot";
		(**for i = 1300 downto 1 do
			for j = 1000 downto 1 do
				eval_point (i, j)
			done;
		done;**)
		eval_canvas (650, 500) !width !height;
		let v = read_line () in
		()


end








module E = Example(Kahn.Th)

let () = E.main
















