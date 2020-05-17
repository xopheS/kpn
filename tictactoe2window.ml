(* --------------------------------------------------------- *)
(* Tic Tac Toe game running for two computers                *)
(* works only with Networ2window.N2W  module                 *)
(*                                                           *)
(* --------------------------------------------------------- *)

module K = Network2window.N2W
module Lib = Kahn.Lib(K)

open Lib
open Format
open Graphics

(* Configuration *)
type mode = Server | Client

let parse_arg() =
    let mode = ref Server in
    let length_window = ref 1000. in
    let width_window = ref 620. in 
    let length = ref 600 in
    let width = ref 600 in
    let port = ref 1024 in
    let ipaddr = ref "127.0.0.1" in
    let spec =
      [ "-ipaddr", Arg.Set_string ipaddr, "set the server name" ;
        "-client",Arg.Unit (fun () -> mode := Client), "run as a client";
        "-port", Arg.Set_int port, "n (default 1024)";
        "-length_window", Arg.Set_float length_window, "set the length of the game area";
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
    (!ipaddr, !mode, !port, !length_window, !width_window, !length, !width)


(* ---------------------------------------------------------------------------------------- *)
(* Graphics *)
let draw_empty_board length width = 
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
    (0, 2*length / 3, width, 2*length/3)|]

let init_graph length_window width_window  =
    Graphics.open_graph
      (Printf.sprintf " %dx%d" (int_of_float length_window) (int_of_float width_window));
    Graphics.auto_synchronize false;
    Graphics.set_font "-*-fixed-medium-r-semicondensed--50-*-*-*-*-*-iso8859-1"

let draw_board length width board =
  draw_empty_board length width;
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
  let status = Graphics.wait_next_event [Graphics.Poll] in
  (*ignore (Graphics.wait_next_event [Graphics.Button_up]);*)
  let x ,y = status.mouse_x , status.mouse_y in 
  if status.button && ((0<=x && x<=width) && (0<=y && y<=length)) then string_of_int(((2-(y/(length/3)))*3 + (x/(width/3))))
  else "-1"

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
let list_to_string ls =
   List.fold_left (fun s x -> s^x) "" ls
  
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
        | [|_; x1; _; _; x2; _; _; x3; _|] when x1 = x2 && x2 = x3 && x1 <> " "-> x1
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
let display_text msg = printf "%s" msg; printf "%!"
let display board msg= 
    printf msg;
    printf "\n";
    printf " %s | %s | %s \n" (Array.get board 0) (Array.get board 1) (Array.get board 2);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 3) (Array.get board 4) (Array.get board 5);
    printf "---+---+---- \n";
    printf " %s | %s | %s \n" (Array.get board 6) (Array.get board 7) (Array.get board 8)

(* Client host <->  Client *)
let server_main p lw ww l w = 

  let rec play_server (curr_board, receiver, sender) =
    draw_board l w curr_board;
    
    let rec waiting_server ()= 
      let move = make_click l w in 
      let (cb, b) = update_board curr_board (int_of_string move) P1 in
      match b with 
        | false -> draw_board l w curr_board; waiting_server ()
        | true -> cb
    in 

    curr_board = waiting_server ();
    draw_board l w curr_board;

    match check_winner curr_board  with
      | Win P1 -> begin 
                    display_text "====* Winner is Player 1!!! *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () -> 
                    let msg = create_msg STS "====* Winner is Player 1!!! *====\n" in 
                    K.put msg sender )
                  end 
      | Win P2 -> begin 
                    display_text "====* Winner is Player 2!!! *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "====* Winner is Player 2!!! *====\n" in 
                    K.put msg sender )
                  end 
      | Draw -> begin 
                    display_text "====*          DRAW         *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg FYI (board_to_string curr_board) in
                    K.put msg sender >>= (fun () ->
                    let msg = create_msg STS "====*          DRAW         *====\n" in 
                    K.put msg sender )
                end 
      | Continue ->  begin 
        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->
        let rec waiting_client () =
          let msg = create_msg MYM "Make your move\n" in 
          K.put msg sender >>= fun () -> (
          K.get receiver >>= fun move -> 
          let (cb, b) = update_board curr_board (int_of_string move) P2 in
          match b with 
            | false -> begin 
                        let msg = create_msg ERR "Wrong move -P2\n" in 
                        K.put msg sender >>= waiting_client 
                      end
            | true -> delay (fun () -> cb) ()
          )
        in  
        waiting_client () >>= (fun curr_board -> 
        draw_board l w curr_board;

        let msg = create_msg FYI (board_to_string curr_board) in
        K.put msg sender >>= (fun () ->

        match check_winner curr_board with
          | Win P1 -> begin display_text "====* Winner is Player 1!!! *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "====* Winner is Player 1!!! *====\n" in 
                    K.put msg sender 
                  end 
          | Win P2 -> begin display_text "====* Winner is Player 2!!! *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "====* Winner is Player 2!!! *====\n" in 
                    K.put msg sender
                  end 
          | Draw -> begin display_text "====*          DRAW         *====\n";
                    draw_board l w curr_board;
                    let msg = create_msg STS "====*          DRAW         *====\n" in 
                    K.put msg sender 
                  end 
          | Continue -> play_server (curr_board, receiver, sender)
          )
          )
        )
      end
  in 
  delay K.set_port p >>= fun() -> delay K.new_channel () >>= fun (receiver, sender) -> 
  delay (init_graph lw) ww >>= fun () -> play_server (empty_board, receiver, sender) >>=
  fun () -> delay (K.close_channel receiver) sender
  

let client_main ip p lw ww l w =  
    let rec play_client (curr_board, receiver, sender) = 
      K.get receiver >>= (fun message -> 
      let ml = explode message in  
      match ml with
        | "M"::"Y"::"M"::s -> begin draw_board l w curr_board; 
                                    K.put (make_click l w) sender >>= (fun () -> play_client (curr_board, receiver, sender))
                              end 
        | "F"::"Y"::"I"::b -> begin
                                draw_board l w (Array.of_list b); 
                                play_client(Array.of_list b, receiver, sender) 
                              end
        | "S"::"T"::"S"::s -> display_text (list_to_string s); draw_board l w curr_board; K.return()
        | "E"::"R"::"R"::s -> begin 
                                draw_board l w curr_board; 
                                play_client (curr_board, receiver, sender)
                              end 
        | _ -> raise Weird (* If the code runs well you should never have this message *)
      )
    in 
    delay K.set_port p >>= fun () -> delay K.connect_by_name (ip) >>= fun (receiver, sender) -> 
    delay (init_graph lw) ww >>= fun () -> play_client (empty_board, receiver, sender)
(* ---------------------------------------------------------------------------------------- *)
(* Launch program *)

let main = 
  delay parse_arg() >>= fun (ip, mode, p, lw, ww, l, w) ->
    match mode with
      | Server -> server_main p lw ww l w
      | Client -> client_main ip p lw ww l w

let () = K.run main