(* Tic Tac Toe Game *)

module K = Network.N 
module Lib = Kahn.Lib(K)
open Lib
open Format
open Graphics

(* Configuration *)
let parse_arg() =
    let length_window = ref 1000. in
    let width_window = ref 620. in 
    let length = ref 600 in
    let width = ref 600 in
    let spec =
      [ "-length_window", Arg.Set_float length_window, "set the length of the game area";
        "-width_window", Arg.Set_float width_window, "set the width of the game area";
        "-length", Arg.Set_int length, "set the length of the game board";
        "-width", Arg.Set_int width, "set the width of the game board"]
    in
    let usage =
    ("Usage: "^Sys.argv.(0)^" [options] \n"^
     "Options:")
  in
  Arg.parse spec 
    (fun s -> if s <> "" then (Arg.usage spec usage; exit 1)) usage;
    (!length_window, !width_window, !length, !width)


(* ---------------------------------------------------------------------------------------- *)
(* Graphics *)
let init_graph length width =
    Graphics.open_graph
      (Printf.sprintf " %dx%d" (int_of_float length) (int_of_float width));
    Graphics.auto_synchronize false;
    Graphics.set_font "-*-fixed-medium-r-semicondensed--50-*-*-*-*-*-iso8859-1"

let draw_board length width board =
  Graphics.clear_graph;
  Graphics.synchronize;
  Graphics.moveto width (length/2);
  Graphics.set_color Graphics.black;
  Graphics.draw_string "Game On!";
  Graphics.moveto width (length/3);
  Graphics.set_color Graphics.black;
  Graphics.draw_string "(check terminal)";
  Graphics.synchronize;
  Graphics.set_line_width 10;
  Graphics.set_color Graphics.black;
  Graphics.draw_segments [|
    (width / 3, 0, width/3, length);
    (2* width / 3, 0, 2*width/3, length);
    (0, length / 3, width, length/3);
    (0, 2*length / 3, width, 2*length/3)|];
  Array.iteri (
    fun pos v -> 
      let cx = (pos mod 3)*width/3 + width/6 in 
      let cy = 5*length/6 - (pos/3)*length/3 in 
      let deltax , deltay = width/8 , length/8 in 
      match v with 
        | "O" -> Graphics.set_color Graphics.red; Graphics.draw_circle cx cy (width/8)
        | "X" -> Graphics.set_color Graphics.blue; 
                 Graphics.draw_segments [|(cx-deltax, cy-deltay, cx+deltax,cy+deltay);
                                          (cx-deltax, cy+deltay, cx+deltax,cy-deltay)|]
        | _ -> ()
  ) board;
  Graphics.synchronize ()

(* ---------------------------------------------------------------------------------------- *)
(* Game controls *)

let make_click length width =
  let status = Graphics.wait_next_event [Graphics.Button_up] in
  let x ,y = status.mouse_x , status.mouse_y in 
  if ((0<=x && x<=width) && (0<=y && y<=length)) then ((2-(y/(length/3)))*3 + (x/(width/3)))
  else -1

(* ---------------------------------------------------------------------------------------- *)
(* Types definitions *)
exception Weird

type player = P1 | P2  
type state = Win of player | Draw | Continue
type token = MYM | FYI | STS | ERR

let create_msg token msg =
  match token with 
    | MYM -> "MYM"^msg (* make your move *)
    | FYI -> "FYI"^msg (* sends updated board *)
    | STS -> "STS"^msg (* gives state of game *)
    | ERR -> "ERR"^msg (* wrong move *)

let empty_board = [| " "; " "; " ";
                     " "; " " ; " " ;
                     " "; " "; " "|]

(* helper function for message creation *)
let board_to_string board = 
  Array.fold_left (fun s x -> s^x) "" board
let explode s =
  List.init (String.length s) (fun i -> String.sub s i 1)


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

(* brute force check winner  *)
let check_winner board = 
    let token = 
      match board with
        | [|x1; x2; x3; _; _; _; _; _; _|] when x1 = x2 && x2 = x3 && x1 <> " " -> x1
        | [|_; _; _; x1; x2; x3; _; _; _|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
        | [|_; _; _; _; _; _; x1; x2; x3|] when x1 = x2 && x2 = x3 && x1 <> " " -> x1
        | [|x1; _; _; x2; _; _; x3; _; _|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
        | [|_;x1; _; _;x2; _; _; x3; _|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
        | [|_; _; x1; _; _; x2; _; _; x3|] when x1 = x2 && x2 = x3 && x1 <> " " -> x1
        | [|x1; _; _; _; x2; _; _; _; x3|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
        | [|_; _; x1; _; x2; _; x3; _; _|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
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

(* Debug *)
let display_text msg = printf "%! %s" msg
let display board msg= 
    printf msg;
    printf "\n";
    printf " %s | %s | %s \n" (Array.get board 0) (Array.get board 1) (Array.get board 2);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 3) (Array.get board 4) (Array.get board 5);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 6) (Array.get board 7) (Array.get board 8)

(* Client host <->  Client *)
let server_main receiver sender lw ww l w =
  let rec play_server (curr_board) =
    display_text "Turn: Player 1\n";
    draw_board l w curr_board;
    
    let rec waiting_server ()= 
      let move = make_click l w in 
      let (cb, b) = update_board curr_board move P1 in
      match b with 
        | false -> display_text "Wrong move - P1\n"; draw_board l w curr_board; waiting_server ()
        | true -> cb
    in 
    curr_board = waiting_server ();

    display_text "Player 1 moved. Turn: Player 2\n";
    draw_board l w curr_board;

    match check_winner curr_board  with
      | Win P1 -> begin 
                    display_text "Winner is Player 1!\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () -> 
                    let msg = create_msg STS "Winner is player 1" in 
                    K.put msg sender )
                  end 
      | Win P2 -> begin 
                    display_text "Winner is Player 2\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "Winner is player 2" in 
                    K.put msg sender )
                  end 
      | Draw -> begin 
                    display_text "Draw!\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "Draw" in 
                    K.put msg sender )
                end 
      | _ ->  begin 
        display_text "Continue case\n";
        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->
        let rec waiting_client () =
          let msg = create_msg MYM "Make your move\n" in 
          K.put msg sender >>= fun () -> (
          K.get receiver >>= fun move -> 
          let (cb, b) = update_board curr_board move P2 in
          match b with 
            | false -> begin 
                        let msg = create_msg ERR "Wrong move\n" in 
                        K.put msg sender >>= waiting_client 
                      end
            | true -> delay (fun () -> cb) ()
          )
        in  
        waiting_client () >>= (fun curr_board ->
        display_text "Player 2 moved. Turn: Player 1\n";
        draw_board l w curr_board;
        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->
        match check_winner curr_board with
          | Win P1 -> begin display_text "Winner is Player 1\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "Winner is player 1" in 
                    K.put msg sender 
                  end 
          | Win P2 -> begin display_text "Winner is Player 2\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "Winner is player 2" in 
                    K.put msg sender
                  end 
          | Draw -> begin display_text "Draw!\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "Draw!" in 
                    K.put msg sender 
                  end 
          | _ -> play_server (curr_board)
          )
          )
        )
      end
  in delay (init_graph lw) ww >>= fun () -> play_server empty_board


let client_main receiver sender lw ww l w= 
    let rec play_client (curr_board) = 
      K.get receiver >>= (fun message -> 
      let ml = explode message in  
      match ml with
        | "M"::"Y"::"M"::s -> begin display_text "Make your move ---- CLIENT\n"; draw_board l w curr_board; 
                                    K.put (make_click l w) sender >>= (fun () -> play_client curr_board)
                              end 
        | "F"::"Y"::"I"::b -> display_text "Board received ---- CLIENT\n"; draw_board l w (Array.of_list b); play_client(Array.of_list b)
        | "S"::"T"::"S"::s -> display_text "End game ---- CLIENT\n"; draw_board l w curr_board; K.return ()
        | "E"::"R"::"R"::s -> display_text "Wrong move -P2\n"; draw_board l w curr_board; play_client curr_board
        | _ -> raise Weird
      )
    in delay (init_graph lw) ww >>= fun () -> play_client empty_board

(* ---------------------------------------------------------------------------------------- *)
(* Launch program *)
let main = 
  delay parse_arg() >>= fun (lw, ww, l, w) ->
  delay K.new_channel () >>= 
  fun (sock_inp1, sock_out1) -> K.return (K.new_channel()) >>=
  fun (sock_inp2, sock_out2) -> 
    K.doco[ server_main sock_inp2 sock_out1 lw ww l w ; 
            client_main sock_inp1 sock_out2 lw ww l w] >>=
    (fun () -> delay (Unix.sleep) 1) 

let () = K.run main