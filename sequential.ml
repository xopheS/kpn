module Seq : Kahn.S = struct


	type action =
		| Atom of (unit -> action)
		| Fork of action * action
		| Stop
	
	type 'a process = ('a -> action) -> action
	
	(** PORT FUNCTIONS AND TYPES **)
	type 'a in_port = 'a Queue.t
	type 'a out_port = 'a Queue.t
	
	
	let new_channel () = 
		let c = Queue.create () in
		c , c

	let rec put v q : unit process = 
		fun (c : unit -> action) -> 
				Queue.push v q;
				Atom c
		 
 	let rec get q : 'a process = 
		fun (c : 'a -> action) -> 
			try
				let v = Queue.pop q in
				Atom (fun () -> c v)
			with Queue.Empty ->
				Atom (fun () -> get q c)

		
	(** ACTION FUNCTIONS **)
	let convert ?(f = fun (c : 'a) -> Stop) (p : 'a process) : action =
			p f

	let rec printa (a : action) : unit = match a with
		| Fork (a1 , a2)  -> 
				Format.printf "Fork (";
				printa a1;
				Format.printf " , ";
				printa a2;
				Format.printf ")"
		| Atom a1 -> Format.printf "Atom ( p )"
		| Stop -> Format.printf "Stop"


	(** RUN FUNCTIONS **)
	let return (v : 'a) : 'a process = 
		fun (c : 'a -> action) -> 
				Atom (fun () -> c v)

	let bind (p1 : 'a process) (p2 : 'a -> 'b process) : 'b process =
		fun c1 -> p1 (fun c2 -> p2 c2 c1)


	let doco (l : unit process list) : unit process = fun (c : unit -> action) ->
		
		let rec tree (l : unit process list) : action = match l with
			| [] -> c ()
			| x :: xs -> 
				Fork (convert x , tree xs)
		in
		tree l
						
	
	let run (p : 'a process) =
		(** CREATE REF TO STORE RESULT **)
		let a = ref None in

		(** INITIATE A PIPELINE OF ACTIONS **)
		let pipeline : action Queue.t = Queue.create () in

		(** CONVERT AND EXECUTE THE PROCESS WITH CONTINUATION THE STORAGE IN a **)
		let act = convert ~f:(fun (x : 'a) -> a := Some x ; Stop) p in
		Queue.push act pipeline;
		
		let rec execute (q : action Queue.t) =
			if Queue.is_empty q then
				()
			else	
				let x = Queue.pop q in
				match x with
					| Atom a ->
						Format.printf "ATOM\n";
						let na = a () in
						Queue.push na q;
						execute q
					| Fork (a1 , a2) ->
						Format.printf "FORK\n";
						Queue.push a1 q;
						Queue.push a2 q;
						execute q
					| Stop -> Format.printf "STOP\n"; execute q 

		in

		execute pipeline;

		match !a with
			| None -> assert false
			| Some v -> v
	
	

end










