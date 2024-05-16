/**
* Name: runningtraildraft
* Based on the internal empty template. 
* Author: Khanhtran
* Tags: 
*/


model runningtraildraft

global {
	matrix<bool> a <- matrix<bool>([false, false, true]);
	bool d <- true;
	matrix<int> c;
	
	matrix<int> b <- 1 as_matrix({3, 1});
	matrix<bool> accepted_waste <- matrix([[true, false, true], 
										[true, true, false], 
										[false, true, true]]);
	int t;
	
	string u <- "khan5";
	
	init {
		t <- nil;
		if t = nil {
			write "NUll";
		}
		t <- 1;
		write t;
		write "Last: " + int(last(u));
		write 8 mod 3;
		
		
		write "Casting boolean:" + int(d);
		write accepted_waste[0, 1];
		write "Matrix b = " + b;
		write "Casting a to int" + matrix<int>(a);
		c <- matrix<int>(a)*b;
		write sum(c);	
	}
}

/* Insert your model definition here */


experiment draft_run type: gui {
	
}
