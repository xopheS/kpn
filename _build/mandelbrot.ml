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
	
	type point = { x : int; y : int; c : color }
		
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
	

	
	let eval_point ((x, y) : int * int) : point = 
		
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
		{ x = x; y = y; c = new_color }
	
	
	let eval_canvas ((x_st, y_st) : int * int) (cw : int) (ch : int) (qo : point K.out_port) : unit K.process =
		
		let max_x : int = x_st + cw in
		let max_y : int = y_st + ch in
				
		let rec compute ((x, y) : int * int) : unit K.process =
			(K.put (eval_point (x, y)) qo) >>=
				(fun () ->
					if x < max_x then compute (x + 1, y)
					else if y < max_y then compute (x_st, y + 1) 
					else K.return ()
				)
		in	
		compute (x_st, y_st)
		
	
	let plot_all (qi : point K.in_port) : unit K.process =
		let rec lget () =
			(K.get qi) >>= (fun (p : point) -> 
					(set_color (p.c); plot p.x p.y; lget ()))
		in
		lget ()	


	let main : unit K.process = 
		open_graph " 1300x1000";
		set_window_title "Mandelbrot";
		
		(delay K.new_channel ()) >>=
		(fun (qi, qo) -> K.doco [eval_canvas (650, 0) 650 1000 qo;
					eval_canvas (0, 0) 650 1000 qo;
					 plot_all qi; ])


end





module E = Example(Sequential.Seq)

let () = E.K.run E.main
















