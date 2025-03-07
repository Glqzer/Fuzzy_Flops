(*
  FPSE Assignment 2

  Name                  : David Wang
  List of Collaborators :

  Please make a good faith effort at listing people you discussed any problems with here, as per the course academic integrity policy.  CAs/Prof need not be listed!

	------------
	INSTRUCTIONS
	------------

	You will check the validity of a Towers game solution.

	Towers is a simple puzzle game. To see the rules and play the game, go to the following url:

		https://www.chiark.greenend.org.uk/~sgtatham/puzzles/js/towers.html

	Here is a description taken from that site:

	Your task is to build a tower on every square, in such a way that:
	* Each row contains every possible height of tower once
	* Each column contains every possible height of tower once
	* Each numeric clue describes the number of towers that can be seen if you look into the square from that direction, assuming that shorter towers are hidden behind taller ones. For example, in a 5×5 grid, a clue marked ‘5’ indicates that the five tower heights must appear in increasing order (otherwise you would not be able to see all five towers), whereas a clue marked ‘1’ indicates that the tallest tower (the one marked 5) must come first.

	Since this assignment is an exercise to become familiar with functional programming, we are going to give appropriate auxiliary functions which will decompose the problem into smaller pieces.  You should be able to compose these short functions to accomplish the ultimate goal of verifying whether a completely-filled grid is a solution based on the clues around the edges.  We will only be verifying the "easy" games which don't leave out any of the clues around the grid edges.
		
	We encourage you to the List combinators, pipelining, etc. when possible and whenever it improves the readability of the solution.  All but the last function are directly code-able with the List combinators and no `rec`.

	As always, you should feel free to write your own helper functions as needed.

	If you are unsure on what the requirements of the functions are, look at the test cases we provide.

	-------
	OUTLINE
	-------

	Here is the method we will use to verify the solution:
	1. Assert that the grid is well-formed, namely:
		* the grid is square
		* it is at least 1x1 in size (no 0x0 degenerates are allowed)
		* each row and column contains exactly the numbers if should
	2. Check that the clues are satisfied:
		* verify that from the left, each row satisfies the clues
		* rotate the grid and repeat
*)

open Core

(* Disables "unused variable" warning from dune while you're still solving these! *)
[@@@ocaml.warning "-27"]

(*
let unimplemented () =
	failwith "unimplemented"
*)

(*
	We can represent the tower board itself as a list of lists of ints.  

	See the example boards in `test/towers_tests.ml`.
*)

(*
	---------------
	WELL-FORMEDNESS
	---------------

	Implement the following functions to check that the grid is well-formed.
*)

(*
	Check that the grid is square, i.e. each list is the same length and there are the same number of lists as there are elements in any of the lists.

	Return one of
		Ok <dimension of the grid>
		Error "not square"
*)
let square_size (grid: int list list) : (int, string) result =
	let len = List.length grid in
	if List.for_all grid ~f:(fun ls -> List.length ls = len) then Ok(len) else Error("not square");;


let int_compare a b : bool =
		compare a b = 0;;

(*
	Given a list of integers of length `n`, return true if and only if the list has exactly one occurrence of each number 1..n in it.	 
*)
let elements_span_range (l : int list) : bool = 
	let n = List.length l in
	let compLs = List.init n ~f:(fun i -> i + 1) in
	let sorted_lst = List.sort ~compare:(compare) l in
	List.equal int_compare sorted_lst compLs;;

(*
	Helper function for transpose
*)
let rec transpose_helper (grid : int list list) (aux : int list list) = 
	match grid with 
	| [] -> List.rev aux
	| [] :: _ -> List.rev aux
	| _ -> 
			let first = List.map grid ~f:(fun a -> match a with
			| x :: xs -> x
			| [] -> failwith "Empty Row") in

			let rest = List.map grid ~f:(fun a -> match a with
			| x :: xs -> xs
			| [] -> failwith "Empty Row") in

			transpose_helper rest (first :: aux);;


(*
	Transpose the grid. Recall that you may assume the grid is square.
*)
let transpose (grid : int list list) : int list list =
	transpose_helper grid [];;


(* Check to see if a towers grid is well-formed, namely
	1) it is square as per above,
	2) it is at least 1x1 in size (no 0x0 degenerates are allowed)
	2) each row and column spans the range as per above *)
(*
	Return true if and only if the grid is square, is at least 1x1, and each row and column spans the range as per above. 
*)
let is_well_formed_grid (grid : int list list) : bool = match square_size grid with 
	| Ok(0) -> false
	| Error a -> false
	| Ok b -> if List.for_all grid ~f:(fun ls -> elements_span_range ls) then
		let rotated = transpose grid in
		List.for_all rotated ~f:(fun ls -> elements_span_range ls) else false;;

(*
	-------------
	CLUE-CHECKING
	-------------

	The remaining auxiliary functions should only be called on well-formed grids, or rows from well-formed grids. The behavior is undefined otherwise, and you don't need to worry about other cases.	 

	Implement these functions to help check for a valid solution.
*)

(*
	Helper function for towers_seen_helper
*)
let rec towers_seen_helper (row : int list) (count : int) (last : int): int = match row with
	| [] -> count
	| a :: xs -> if last < a then towers_seen_helper xs (count + 1) a
	else towers_seen_helper xs count last;;

(*
	The lowest level of the validity check for towers requires finding the number of new maxima going down a given list. Implement the function `number_towers_seen` to find the number of items in the list that are larger than all items to their left.
*)
let number_towers_seen (row : int list) : int =  
	towers_seen_helper row 0 0;;

(* 
	Helper function for verify left clues
*)
let rec left_clues_helper (grid : int list list) (aux : int list) : int list = 
	match grid with 
	| [] -> List.rev aux
	| a :: xs -> let seen = number_towers_seen a in 
		left_clues_helper xs (seen :: aux);;

(*
	There are many reasonable ways to apply the above function to each row and column around the grid.	 

	We will do it by only checking the "left side grid" clues.

	Given a well-formed grid and a list of clues corresponding to the rows in the grid, return true if and only if the clues are correct on the grid from the left for each row.
*)
let verify_left_clues (grid : int list list) (edge_clues : int list) : bool = 
	let aux = left_clues_helper grid [] in
	List.equal int_compare aux edge_clues;;
	
(* 
	Helper function to reflect the grid
*)
let rec reflect_helper (grid : int list list) (aux : int list list) =
	match grid with
	| [] -> List.rev aux
	| a :: xs -> reflect_helper xs ((List.rev a) :: aux);;

(*
	To check the clues on all four edges, we will rotate the grid counter-clockwise and call the above function at each rotation.

	We will rotate counter-clockwise by first reflecting the grid across a vertical axis and then transposing.
*)
let reflect_across_vertical_axis (grid : int list list) : int list list =
	reflect_helper grid [];;


(*
	Now compose the two functions to rotate the grid counter-clockwise.
*)
let rotate_ccw (grid : int list list) : int list list = 
	transpose (reflect_across_vertical_axis grid);;

(* 
	Verification helper
*)
let rec verification_helper (grid : int list list) (four_edge_clues : int list list) : bool =
	match four_edge_clues with
	| [] -> true
	| a :: xs -> if verify_left_clues grid a then 
		let rotated = rotate_ccw grid in
		verification_helper rotated xs
		else false;;

(*
	-------------------------
	VERIFYING ENTIRE SOLUTION 
	-------------------------

	Finally, write a function `is_towers_solution` which, given a grid and clues all around the grid, verifies that the solution is correct with respect to the clues: the grid is well-formed as per above, and the clues are all satisfied by the solution.

	The clues are a list of lists, and the first element of the list is the edge clues for the original board orientation. The subsequent lists correspond to clues for success counter-clockwise rotations of the grid.

	If the grid is ill-formed or the clues are not all satisfied, return false.
*)
let is_towers_solution  (grid : int list list) (four_edge_clues : int list list) : bool = 
	if is_well_formed_grid grid then
		verification_helper grid four_edge_clues
	else false