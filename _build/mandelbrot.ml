open Graphics

module Example (K : Kahn.S) = struct
	
	module K = K
	module Lib = Kahn.Lib(K)
	open Lib
	
	(** AUXILIARY FUNCTIONS **)
	(** Range function **)
	let (--) (first : int) (last : int) = 
    		let rec aux n acc =
      			if n < first then acc else aux (n - 1) (n :: acc)
    		in 
		aux last []


	(** TYPE COMPLEX WITH SOME OPERATIONS **)
	type complex = float * float
	
	let re ((x , _) : complex) : float = x
	let im ((_ , y) : complex) : float = y
	
	let squared_modulus (z : complex) : float = re z ** 2. +. im z ** 2.
	
	
	(** GLOBAL VARIABLES **)
	let width : int ref = ref 1300
	let height : int ref = ref 1000
	let n_iter : int ref = ref 255
	let np : int ref = ref 1

	let xo : float ref = ref (-0.5)
	let yo : float ref = ref 0.
	
	let zm : float ref = ref 2.
	let w : int ref = ref 1300
	
	let user_inputs = [("-w", Arg.Set_int width, "Width");
			   ("-h", Arg.Set_int height, "Height");
			   ("-p", Arg.Set_int np, "Number of processes (must divide width)");
			   ("-n", Arg.Set_int n_iter, "Number of iterations");
			   ("-xo", Arg.Set_float xo, "Real value of origin");
			   ("-yo", Arg.Set_float yo, "Imaginary value of origin");
			   ("-z", Arg.Set_float zm, "Scale value, half length of axis");]	
		
	exception Invalid_Argument of string

	let require (predicate : bool) (msg : string) : unit =
		if not predicate then
			raise (Invalid_Argument msg)

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

		let x_cart = center (float_of_int x) (float_of_int !width) !xo in
		let r = normalize x_cart (!xo -. !zm) (!xo +. !zm) (float_of_int !width) in

		let y_cart = center (float_of_int y) (float_of_int !height) !yo in
		let i = normalize y_cart (!yo -. !zm) (!yo +. !zm) (float_of_int !height) in

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
	
	
	let eval_canvas (x_st : int) (qo : point K.out_port) : unit K.process =
		
		let max_x : int = x_st + !w in
				
		let rec compute ((x, y) : int * int) : unit K.process =
			(K.put (eval_point (x, y)) qo) >>=
				(fun () ->
					if x < max_x then compute (x + 1, y)
					else if y < !height then compute (x_st, y + 1) 
					else K.return ()
				)
		in	
		compute (x_st, 0)
		
	
	let plot_all (qi : point K.in_port) : unit K.process =
		let rec lget () =
			(K.get qi) >>= (fun (p : point) -> 
					(set_color (p.c); plot p.x p.y; lget ()))
		in
		lget ()	
	
	
	let configurations () : unit =
		(** parse command line arguments **)
		Arg.parse (Arg.align user_inputs) (fun _ -> ()) "";
		
		(** check validity **)
		require (!width mod !np == 0) "Number of processes must divide width";
		require (!zm > 0.) "Zoom must have a positive value";
		w := !width / !np;
		
		(** open graph **)
		open_graph (
			String.concat "" [" "; (string_of_int !width); "x"; (string_of_int !height)]
		);
		set_window_title "Mandelbrot"
		


	let main : unit K.process = 
		configurations ();

		(delay K.new_channel ()) >>=
		(fun (qi, qo) -> K.doco (
		List.append (List.map (fun i -> eval_canvas (i * !w) qo) (0--(!np-1)))
			    [plot_all qi]))



end





module E = Example(Kahn.Th)

let () = E.K.run E.main
















