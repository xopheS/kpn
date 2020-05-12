(* Tic Tac Toe Game *)

module K = Network.N 
module Lib = Kahn.Lib(K)
open Lib
open Format

(* configuration *)
(* Types definitions *)
(* Game controls *)
(* Graphics *)

(* Server - Client *)
type player = P1 | P2  
type state = Win of player | Draw | Continue
exception Wrong_move
exception Weird

let empty_board = [| " "; " "; " ";
              " "; " " ; " " ;
              " "; " "; " "|]

let update_board board move player = 
    let token = match player with 
                | P1 -> "X"
                | P2 -> "O"
    in 
    if (move < 0 || move > 8) then (board, false)
    else begin 
      let board_curr_value = Array.get board move in 
      match board_curr_value with 
      | " " -> Array.set board move token; (board, true)
      | _ -> (board, false)
    end

let is_full board = 
  Array.fold_left (fun b x -> match x with
                              | " " -> false
                              | _ -> b) true board 

let check_winner board = 
    let token = 
      match board with
        | [|x1; x2; x3; _; _; _; _; _; _|] when x1 = x2 && x2 = x3 -> x1
        | [|_; _; _; x1; x2; x3; _; _; _|] when x1 = x2 && x2 = x3 -> x1
        | [|_; _; _; _; _; _; x1; x2; x3|] when x1 = x2 && x2 = x3 -> x1
        | [|x1; _; _; x2; _; _; x3; _; _|] when x1 = x2 && x2 = x3 -> x1
        | [|_;x1; _; _;x2; _; _; x3; _|] when x1 = x2 && x2 = x3 -> x1
        | [|_; _; x1; _; _; x2; _; _; x3|] when x1 = x2 && x2 = x3 -> x1
        | [|x1; _; _; _; x2; _; _; _; x3|] when x1 = x2 && x2 = x3 -> x1
        | [|_; _; x1; _; x2; _; x3; _; _|] when x1 = x2 && x2 = x3 -> x1
        | _ -> " "
    in 
    
    if is_full board then 
      match token with 
        | "X" -> Win P1
        | "O" -> Win P2
        | _ ->  Draw
    else 
      match token with 
        | "X" -> Win P1
        | "O" -> Win P2
        |  _  -> Continue

let display board msg= 
    printf msg;
    printf "\n";
    printf " %s | %s | %s \n" (Array.get board 0) (Array.get board 1) (Array.get board 2);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 3) (Array.get board 4) (Array.get board 5);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 6) (Array.get board 7) (Array.get board 8);


type token = MYM | FYI | STS | ERR
let create_msg token msg =
  match token with 
    | MYM -> "MYM"^msg
    | FYI -> "FYI"^msg
    | STS -> "STS"^msg
    | ERR -> "ERR"^msg

let board_to_string board = 
  Array.fold_left (fun s x -> s^x) "" board

let string_to_board s = 
  Array.init (String.length s) (fun i -> String.sub s i 1)
let explode s =
  List.init (String.length s) (fun i -> String.sub s i 1)
(*   Server :
1. makes a move (if a move is invalid then still waits for a good one) 
2. when a good move he updates the board
3. checks if there is a winner/draw. if yes sends a msg to client and quit 
4. sends the board to client as an FYI message 
5. waits for the client to make the move like step 1
6. repeat step 3 
*)

let server_main receiver sender =
  let rec play_server (curr_board) =
    display curr_board "Play ----- SERVER";
    let b1, b2 = false, false in 
    let rec waiting_server ()= 
      let move = read_int () in
      let (cb, b) = update_board curr_board move P1 in
      match b with 
        | false -> waiting_server ()
        | true -> cb
    in 
    curr_board = waiting_server ();
    display curr_board "P1 moved --- SERVER ";
    match check_winner curr_board  with
      | Win P1 -> begin 
                    display curr_board "Winner is P1 ---- SERVER";
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () -> 
                    let msg = create_msg STS "Winner is player 1" in 
                    K.put msg sender )
                  end 
      | Win P2 -> begin 
                    display curr_board "Winner is P2 ------ SERVER";
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "Winner is player 2" in 
                    K.put msg sender )
                  end 
      | Draw -> begin 
                    display curr_board "Draw ---- SERVER";
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "There is a tie" in 
                    K.put msg sender )
                end 
      | _ ->  begin
        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->
        let rec waiting_client () =
          let msg = create_msg MYM "Make your move" in 
          K.put msg sender >>= fun () -> (
          K.get receiver >>= fun move -> 
          let (cb, b) = update_board curr_board move P2 in
          match b with 
            | false -> begin 
                        let msg = create_msg ERR "Wrong move" in 
                        K.put msg sender >>= waiting_client
                      end
            | true -> delay (fun () -> cb) ()
          )
        in  
        waiting_client () >>= (fun curr_board ->
        display curr_board "P2 moved ---- SERVER";
        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->
        match check_winner curr_board with
          | Win P1 -> begin display curr_board "Winner: p1 ----- SERVER";
                    let msg = create_msg STS "Winner is player 1" in 
                    K.put msg sender 
                  end 
          | Win P2 -> begin display curr_board "Winner: p2 ----- SERVER";
                    let msg = create_msg STS "Winner is player 2" in 
                    K.put msg sender 
                  end 
          | Draw -> begin display curr_board "Draw ------- SERVER";
                    let msg = create_msg STS "There is a tie" in 
                    K.put msg sender 
                  end 
          | _ -> play_server (curr_board)
          )
          )
        )
      end
  in play_server empty_board

(*   Client = 
1. receives a message from the client
2. and acts accordingly (displays the board or sends a move)
*)

let client_main receiver sender = 
    let rec play_client (curr_board) = 
      K.get receiver >>= (fun message -> 
      let l = explode message in  
      match l with
        | "M"::"Y"::"M"::s -> display curr_board "Make your move ---- CLIENT"; K.put (read_int ()) sender >>= (fun () -> play_client curr_board)
        | "F"::"Y"::"I"::b -> display (Array.of_list b) "Player 2 moved ---- CLIENT"; play_client(Array.of_list b)
        | "S"::"T"::"S"::s -> display curr_board "End game ---- CLIENT"; K.return () (* display board *)
        | "E"::"R"::"R"::s -> display curr_board "Wrong move ---- CLIENT"; play_client curr_board(* display board *)
        | _ -> raise Weird
      )
    in play_client empty_board

(* Launch program *)
let main = 
  delay K.new_channel () >>= 
  fun (sock_inp1, sock_out1) -> K.return (K.new_channel()) >>=
  fun (sock_inp2, sock_out2) -> 
    K.doco[ server_main sock_inp2 sock_out1; client_main sock_inp1 sock_out2]

let () = K.run main