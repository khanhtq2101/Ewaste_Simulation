/**
* Name: waste sorting
* Author: Jonathan Cohen
* Description: Simulation to model the Theory of Planned Behavior in relation of waste sorting.
* Tags: TPB, Waste, Urban
*/


model waste_sorting

global {
	// SET A STARTING SEED, in case of getting the same simulation
	//float seed <- rnd(0.0,1000.0);				
	
	///////////////////////////////////////////////
	//    URBAN SITUATIONS: PLACE HOLD FOR SHAPEFILES
	////////////////////////////////////////7
	file shape_file_residential 	<- file("E:/Social-Industrial Symbiosis - SIMTech/progress/week 9/getting data/HDBExistingBuilding_demo/HDBExistingBuilding_demo.shp");	
	//file shape_file_residential 	<- file("../includes/HDBExistingBuilding_demo_100unit_2res/HDBExistingBuilding_demo.shp");
	file shape_file_productive 		<- file("../includes/Low_Dens/office_demo.shp");	
	file shape_file_bin 			<- file("E:/Social-Industrial Symbiosis - SIMTech/progress/week 9/getting data/E-wasteCollectionPoints_demo/E-wasteCollectionPoints_demo.shp");	
	//file shape_file_bin				<- file("../includes/Low_Dens/E-wasteCollectionPoints_demo.shp");	
	geometry shape 					<- envelope(shape_file_bin) + 100;	
	
	
	
	//////////////////////////
	/// Behavioural spaces
	//////////////////////////	
	// quartiles of behaviour are specified here. This is based on empirical data
	// V. bad: 0 -> 24
	int l1  <- 29;  			
		
	// Bad: 30 -> 54
	int l2a <- l1 + 1;
	int l2b <- 54;   			// 25 -> 44
	
	// Good: 55 -> 74
	int l3a <- l2b + 1; 		
	int l3b <- 74;				// 45 -> 64
	
	// V.Good: 75 -> 100
	int l4  <- l3b + 1;
	
	
	// Initial conditions
	int collect_freq 			<-	12;  						// Collection frequency -> it affects bin.used
	int space_mean				<- 	50;							// Defines the perception of space at home - MEAN
	int space_sd				<- 	5;							// Defines the perception of space at home - SD
	bool clean_on				<- 	true;						// Enables cleaning of bins, if false there is no cleaning
	string q_breaks_string 		<- 	"4 lines";					// A place holder to include other methods to calculate behavior
	bool work_tpb 				<-	false;						// Sorting of waste only happen at home, but can happen at work - to extend
	float scale_dist 			<- 	1.0;  						// Variable to aduste the scale, can be useful in other contexts
	int beh_update   			<-  15 	update: beh_update;		// How often does the behavior is updated	
	
	// World properties
	// Determine whether the resident works from home or not
	// Change this to adjust the proportion of people who work from home
    float early_start_proba 	<- 0.01;		// State the prob of starting in the first period
    float home_office_proba 	<- 0.05; 		// State the prob of staying at home
    float work_normal_proba   	<- 0.95;  		// State the prob of working normal hours 
    
    int start_info_org 	<- 50;					// Define how much information is in the org bin
	int start_info_mix	<- 50;					// Define how much information is in the residual bin
	int start_info_pak	<- 50;					// Define how much information is in the residual bin
	
	
		
		
	// This variables are the constants based on the fitted model on TPB
	// This coefficients and SEs come from a companion study that fitted a SEM to extract path coefficients
	// Behaviour
	int 		beh_cont_b 		<-	40			; 		// Behavior constant beta
	int 		beh_cont_se 	<-	2			;		// Behavior constant se
	float		int_2_beh_b		<-	0.24		;		// Intention -> Behavior beta
	float		int_2_beh_se	<-	0.08		;		// Intention -> Behavior se
	float		pbc_2_beh_b		<-	0.118		;		// Intention -> Behavior beta
	float		pbc_2_beh_se	<-	0.048		;		// Intention -> Behavior se
	float		know_2_beh_b	<-	0.174		;		// Knowledde -> Behavior beta
	float		know_2_beh_se	<-	0.047		;		// Knowledde -> Behavior se
	float		dist_2_beh_b	<-	-0.213		;		// Distance	 -> Behavior beta 
	float		dist_2_beh_se	<-	0.073		;		// Distance	 -> Behavior se
	float		pant_2_beh_b	<-	7.84		;		// Pant		 -> Behavior se
	float		pant_2_beh_se	<-	2.89		;		// Pant		 -> Behavior se

	// Intention
	int 		int_cont_b 		<-	40			;		// Intention constant beta 
	int 		int_cont_se 	<-	2			;		// Intention constant se
	float 		sn_2_int_b 		<-	0.132		;		// Soc norm   -> Intention beta
	float 		sn_2_int_se		<-	0.050		;		// Soc norm   -> Intention se		
	float 		att_2_int_b 	<-	0.226		;		// Attitude   -> Intention beta
	float 		att_2_int_se 	<-	0.083		;		// Attitude   -> Intention se
	float 		pbc_2_int_b		<-	0.183		;		// PBC 		  -> Intention beta
	float 		pbc_2_int_se	<-	0.043		;		// PBC 		  -> Intention se	
	float 		know_2_int_b 	<-	0.235		;		// Knowledge  -> Intention beta	
	float 		know_2_int_se 	<-	0.057		;		// Knowledge  -> Intention se		
	
	// Attitude
	int 		att_b 			<-	80			;		// Attitude   -> Intention beta
	int 		att_se 			<-	10			;		// Attitude   -> Intention se		
	
	// Knowledge
	int 		know_b 			<-	70			;		// Knowledge constant beta
	int 		know_se 		<-	2			;		// Knowledge constant se
	float 		info_b 			<-	0.10		;		// Information -> knowledge beta
	float 		info_se 		<-	0.01		;		// Information -> knowledge se
	
	// Social norm
	float 		wgt_org_comm 	<-	0.2			;		// Weight of bin community -> ORG
	float 		wgt_mix_comm 	<-	0.2			;		// Weight of bin community -> MIX
	float 		wgt_pak_comm 	<-	0.8			;		// Weight of bin community -> PAK
	float 		sn_b 			<- 	10.0		;		// Social norm constant beta
	float 		sn_se 			<- 	0.5			;		// Social norm constant se
	float 		friend_b 		<- 	0.25		;		// Friend 	-> SN beta
	float 		friend_se 		<- 	0.02		;		// Friend 	-> SN se
	float 		media_b 		<-	0.10		;		// Media 	-> SN beta
	float 		media_se 		<-	0.01		;		// Media	-> SN se
	float 		colleg_b 		<-	0.22		;		// College	-> SN beta
	float 		colleg_se 		<-	0.02		;		// College	-> SN se
	float 		roomies_b 		<-	0.10		;		// Roomies	-> SN beta
	float 		roomies_se 		<-	0.01		;		// Roomies	-> SN se
	float 		waste_b 		<-	0.20		;		// Waste	-> SN beta
	float 		waste_se 		<-	0.02		;		// Waste	-> SN se
	
	// PBC
	float 		pbc_b 			<-	-6.05		;		// PBC constant beta
	float 		pbc_se 			<-	2.52		;		// PBC constant se
	float 		hygen_b 		<-	-0.10		;		// hygenic 	-> PBC beta
	float 		hygen_se 		<-	0.02		;		// hygenic 	-> PBC se
	float 		time_b 			<-	0.59		;		// time	  	-> PBC beta
	float 		time_se 		<-	0.03		;		// time		-> PBC se
	float 		pleasant_b 		<-	0.10		;		// plesant	-> PBC beta
	float 		pleasant_se 	<-	0.02		;		// plesant	-> PBC se
	float 		space_b 		<-	0.24		;		// space 	-> PBC beta
	float 		space_se 		<-	0.02		;		// space	-> PBC se
		
	// Set of variables to scale the model variation
	float beh_fine_tune 	<- 1.0;
	float dist_fine_tune 	<- 0.8;
	float int_fine_tune 	<- 1.0;
	float sn_fine_tune 		<- 1.0;
    float att_fine_tune 	<- 1.0;
	float pbc_fine_tune 	<- 0.4;
	float pbc_fine_hygenic 	<- 0.5;	
	float know_fine_tune 	<- 1.2;	
    
    
    // Set of global variables neede to calculate the KPIs
    float global_kpi_org;
	float global_kpi_mix;
	float global_kpi_pak;
	float global_kpi_avg;
	
	///////////////////////////////////////////////////////
	//////      Waste amounts per capita
	////////////////////////////////////////////////
	int org_day		<- 115;		// 115 grms per day
	int mix_day 	<- 430;		// 430 grms per day
	int pak_day 	<- 178;		// 178 grms per day		
	int org_day_sd	<- 20; 		// 115 grms per day
	int mix_day_sd 	<- 70; 		// 430 grms per day
	int pak_day_sd 	<- 30; 		// 178 grms per day		
	
	int global_org_info <-start_info_org min:0 max:100;
	int global_mix_info <-start_info_mix min:0 max:100;
	int global_pak_info <-start_info_pak min:0 max:100;
	
	////// Miss sorting waste
	////////////////////////////////////
	float thold_wrong_pak <- 0.3;
	float thold_wrong_org <- 0.5;
	
	
	
	///////////////////////////////////
	////// Process of creating agents
	///////////////////////////////////
	init {

		create scheduler;		
		create collector;		
		create prod_build 	from: shape_file_productive returns:  productive_list {}
		
		// Bins are created from shapefile
		create bin 			from: shape_file_bin returns:  bin_list with: [
			id:int(read ("id")), 
			type:string(read("TYP"))
			] {
				if (type="MIX") { color <- #red;} 
				else if (type="ORG"){ color<- #green; }
				else {color <-#violet;}
				
				
			}
			
			
			
		// The creation of residential buildings triggers the creation of people and their households.
		// Important to notice that this comes from data written in the shapefile!
			
		create resi_build 	from: shape_file_residential returns:  residence_list with: [			
			tot_pop:int(read('tot_pop')),
			hholds:int(read('h_units'))] {
							
				
				//create resident number: 1 returns: resident_list {
				create resident number: self.tot_pop returns: resident_list {	

					home_place 	<- myself;
					work_place 	<- one_of(productive_list);
					my_work 	<-any_location_in(work_place);
					
					work_place.q_people <- work_place.q_people+ 1;
					
					location <- any_location_in(home_place);
					my_place <- location;
										
					// Set the distance to different bins
					near_bin_org <- bin where (each.type = "ORG")		closest_to(self);			
					float dist_bin_org <- self distance_to near_bin_org		with_precision(1);
					
					near_bin_mix <- bin where (each.type = "MIX")		closest_to(self);			
					float dist_bin_mix <- self distance_to near_bin_mix		with_precision(1);
					
					near_bin_pak <- bin where (each.type = "PAK")		closest_to(self);			
					float dist_bin_pak <- self distance_to near_bin_pak		with_precision(1);
									
					
					
					// Percentage of people doing home office
					home_office	<- flip(home_office_proba) ? true:false;
					
					// Percentage of people that start out of their homes
					// This is fixed but can be dynamically assigned in the model
					head_work	<- flip(early_start_proba) ? true:false;
					
										
					// Load initial values of waste
					budget_org <- int(gauss(org_day, org_day_sd));
					budget_mix <- int(gauss(mix_day, mix_day_sd));
					budget_pak <- int(gauss(pak_day, pak_day_sd));
					
					//behaviour <- gauss(80,10);					
					mean_dist <- (0.5*dist_bin_org +0.1*dist_bin_mix  + 0.3* dist_bin_pak) with_precision(2);	
					mean_dist <- scale_dist*mean_dist;
					
					}
					
					
			
				// The agent building create households based on the varible hholds in the shapefile
				create house_hold number: self.hholds returns: hhold_list {
				
					int tot_hholds <- myself.hholds;					
					// I need to find a better solution for this last line
					max_people <- int((myself.tot_pop /myself.hholds)) + rnd(0,1); // + rnd(0,1);	
					address <- myself;
					
					address.list_of_homes <+ self;
					// Defines the perception of space at home
					
					space_bin 	<- int(gauss(space_mean,space_sd));									
					}

			int roomies_id <- 0;
			
			// Set residents to the hholds
			ask resident where (each.home_place = hhold_list[roomies_id].address 
				and each.h_unit = nil 
				and length(hhold_list) > roomies_id ) {					
				
				if (length(hhold_list) > roomies_id) {
					h_unit <- hhold_list[roomies_id];		
					h_unit.roomies <+ self;									
					h_unit.filling_peep  <- h_unit.filling_peep  + 1 ;	
					roomies_id <- h_unit.max_people > h_unit.filling_peep ? roomies_id : roomies_id + 1;					
					}
					
				if (length(hhold_list) = roomies_id) {
					h_unit <- one_of(hhold_list);
					h_unit.roomies <+ self;
					h_unit.filling_peep  <- h_unit.filling_peep  + 1 ;	
					}	
			
			} 

		} // closing of residential building creation
		
		// Make some random friends - and set my socials
		ask resident {
			// This is the list of how many friends they have
			int rand_friends <- rnd(1,10);	
			space		<-	h_unit.space_bin;	
			int n_friends <- 0;
			
			loop while: (rand_friends >= n_friends) {
				friend_list <+ one_of((resident - self) where (each.h_unit != self.h_unit));
				n_friends <- n_friends + 1;								
				}
				
			friend_list <- remove_duplicates (friend_list);
			
			// Define a list of residents shring bins
			my_org_comm <- (resident - self)  where (each.near_bin_org = self.near_bin_org);
			my_mix_comm <- (resident - self)  where (each.near_bin_mix = self.near_bin_mix);
			my_pak_comm <- (resident - self)  where (each.near_bin_pak = self.near_bin_pak);			
			
			roomies_list 	<- (resident - self)  where (each.h_unit = self.h_unit);		
			colleg_list 	<- (resident - self)  where (each.work_place = self.work_place);	
		
		}
		// Define waste types and create them
		ask bin {
			if (type = 'ORG') {				
				pop <- length(resident  where (each.near_bin_org = self));			
			}
			
			else if (type = 'MIX') {				
				pop <- length(resident  where (each.near_bin_mix = self));
			}
						
			else {					
				pop <- length(resident  where (each.near_bin_pak = self));				
			}
			
			
		}
		
	} // Close initialize
	

	
	
	
	// This following set of variables are inteded to be used during the simulation
	// These variables change the amont information in the bins
	action increase_org_info {
		ask bin {
			info_org <- info_org + 5;
		}
	}
	
	action decrease_org_info {
		ask bin {
			info_org <- info_org - 5;
		}
	}
	
	action increase_mix_info {
		ask bin {
			info_mix <- info_mix + 5;
		}
	}
	
	action decrease_mix_info {
		ask bin {
			info_mix <- info_mix - 5;
		}
	}
	
	action increase_pak_info {
		ask bin {
			info_pak <- info_pak + 5;
		}
	}
	
	action decrease_pak_info {
		ask bin {
			info_pak <- info_pak - 5;
		}
	}
	
	action increase_hhold_bin_space {
		ask house_hold {
			space_bin <- space_bin + 2;
		}
	}
	
	action decrease_hhold_bin_space {
		ask house_hold {
			space_bin <- space_bin - 2;
		}
	}
	

	// Finally, we define a set of variables to be called at the end of the simulation
	// These variables are the KPIs of interest in the study
	float 	global_kpi_beh;
	float 	global_kpi_beh_max;
    float 	global_kpi_beh_min;
	int 	global_kpi_count_beh_1;
    int 	global_kpi_count_beh_2;
    int 	global_kpi_count_beh_3;
    int 	global_kpi_count_beh_4;
	
	
	
	// This global reflex collects information and will reset the system
	reflex stop_simulation when: every(1095 #cycle) and cycle>0 { //1095 steps = 1 year
        //do pause ;
        
        write "Cycle: " + cycle;

        ask collector {
        		
        	write "Prod-org (Kg): " 		+ from_prod_org 	with_precision(2);
        	write "Prod-mix (Kg): " 		+ from_prod_mix 	with_precision(2);
        	write "Prod-pak (Kg): " 		+ from_prod_pak 	with_precision(2);
        	write "Prod-total (Kg): " 		+ from_prod_total 	with_precision(2);      
	        
	       	write "Res-org (Kg): " 		+ (from_res_org) 	with_precision(2);
	        write "Res-mix (Kg): " 		+ (from_res_mix) 	with_precision(2);        
	        write "Res-pak (Kg): " 		+ (from_res_pak) 	with_precision(2);	           
	        write "Res-total (Kg): " 	+ (from_res_total) 	with_precision(2);
	        
	        
	        write "Total organic (Kg): " 	+ (from_res_org + from_prod_org) with_precision(2);
	        write "Total residual (Kg): " 	+ (from_prod_mix + from_res_mix) with_precision(2);        
	        write "Total recyclable (Kg): " 	+ (from_prod_pak+ from_res_pak)  with_precision(2);
	        
	        
	       	write "Total waste (Ton): " 	+ ((from_prod_total + from_res_total)/1000) 					with_precision(2);
	        write "Percentage of residential (%): " +  ((from_res_total / (from_res_total + from_prod_total))*100) 	with_precision(2);
	        

	        write "Total waste (Kg/pc): "  		+ ((from_prod_total + from_res_total)/length(resident) )	with_precision(2);
	        write "Total organic (Kg/pc):" 		+ ((from_res_org + from_prod_org)/length(resident)) 			with_precision(2);
	        write "Total residual (Kg/pc): "	+ ((from_prod_mix + from_res_mix)/length(resident)) 			with_precision(2);       
	        write "Total recyclable (Kg/pc): " 	+ ((from_prod_pak+ from_res_pak)/length(resident)) 				with_precision(2);
        
        
        	// kPIS
        	write "Org in org: " +  (res_org_IN_org/(res_org_IN_org + res_org_IN_mix + res_org_IN_pak))*100;
        	write "Mix in mix: " +  (res_mix_IN_mix/(res_mix_IN_mix + res_mix_IN_pak + res_mix_IN_org))*100;
        	write "Pak in pak: " +  (res_pak_IN_pak/(res_pak_IN_pak + res_pak_IN_mix + res_pak_IN_org))*100;
        	
        	write "Average: " +    (((res_org_IN_org/(res_org_IN_org + res_org_IN_mix + res_org_IN_pak)) +  
        							(res_mix_IN_mix/(res_mix_IN_mix + res_mix_IN_pak + res_mix_IN_org)) +
        							(res_pak_IN_pak/(res_pak_IN_pak + res_pak_IN_mix + res_pak_IN_org)))/3)*100;
        							
        							
        	// The variables below are used to calculate KPIs
        	// KPI ORG -> Calculates the percentage of properly sorted organics						
        	global_kpi_org <- (res_org_IN_org/(res_org_IN_org + res_org_IN_mix + res_org_IN_pak))*100 with_precision(2);
        	
        	// KPI MIX -> Calculates the percentage of properly sorted residuals
        	global_kpi_mix <- (res_mix_IN_mix/(res_mix_IN_mix + res_mix_IN_pak + res_mix_IN_org))*100 with_precision(2);
        	
        	// KPI PAK -> Calculates the percentage of properly sorted recyclables
        	global_kpi_pak <- (res_pak_IN_pak/(res_pak_IN_pak + res_pak_IN_mix + res_pak_IN_org))*100 with_precision(2);
        	
        	// KPI ORG -> Calculates the Average of the KPIs
        	global_kpi_avg <-  (((res_org_IN_org/(res_org_IN_org + res_org_IN_mix + res_org_IN_pak)) +  
        							(res_mix_IN_mix/(res_mix_IN_mix + res_mix_IN_pak + res_mix_IN_org)) +
        							(res_pak_IN_pak/(res_pak_IN_pak + res_pak_IN_mix + res_pak_IN_org)))/3)*100 with_precision(2);
	
			
			// After the year, and the values of the variables are transfered, 
			// The bins are returned to 0
    		from_res_total 			<-0.0;
			from_res_org 			<-0.0;
			from_res_mix 			<-0.0;
			from_res_pak 			<-0.0;
			res_org_IN_org 			<-0.0;
			res_mix_IN_org 			<-0.0;
			res_pak_IN_org 			<-0.0;
			res_org_IN_mix 			<-0.0;
			res_mix_IN_mix 			<-0.0;
			res_pak_IN_mix 			<-0.0;
			res_org_IN_pak 			<-0.0;
			res_mix_IN_pak 			<-0.0;
			res_pak_IN_pak 			<-0.0;			
			KPI_org 				<-0.0;
			KPI_mix 				<-0.0;
			KPI_pak 				<-0.0;
			KPI_avg 				<-0.0;

        }
        global_kpi_beh 			<- 	resident mean_of each.behaviour with_precision(2);
        global_kpi_beh_min 		<- 	resident min_of 	each.behaviour with_precision(2);      
        global_kpi_beh_max 		<- 	resident max_of 	each.behaviour with_precision(2);
        global_kpi_count_beh_1 	<-	resident count(each.beh_level = 1);
        global_kpi_count_beh_2 	<-	resident count(each.beh_level = 2);
        global_kpi_count_beh_3 	<-	resident count(each.beh_level = 3);
        global_kpi_count_beh_4 	<-	resident count(each.beh_level = 4);
        
    } 
    
    
    // This KPIs are used to track variables used in the monitor
    // The decision to move these in the global, was to increase performance
    float KPI_org_t;
	float KPI_mix_t;
	float KPI_pak_t;		
	float KPI_avg_t;
	
	reflex instant_kpis when: every(3 #cycle) and cycle>=3 {
		try{KPI_org_t <-(((bin where (each.type='ORG') sum_of(each.org))
								/(bin where (each.type='ORG') sum_of(each.current_cap)))*100) with_precision(2);}
								
		try{KPI_mix_t <-(((bin where (each.type='MIX') sum_of(each.mix))
								/(bin where (each.type='MIX') sum_of(each.current_cap)))*100) with_precision(2);}
								
		try{KPI_pak_t <-(((bin where (each.type='PAK') sum_of(each.pak))
								/(bin where (each.type='PAK') sum_of(each.current_cap)))*100) with_precision(2);}
																
								
		try{KPI_avg_t <-((KPI_org_t + KPI_mix_t + KPI_pak_t )/3) with_precision(2);}
		
	}
			
	
} // close global

// This specie is created to define the sequence of how agents are executed, 
// this line of code is important to do the counting of waste properly.
species scheduler schedules: house_hold+ shuffle(resident)  + collector  + bin; 


// The definition of productive buildings
// The model is prepared to track information about waste that residents dispose of 
// 
species prod_build schedules: []{
	rgb color <- #grey;
	
	float mix_cc;
	float org_cc;
	float pak_cc;
	
	float org_in_mix;	
	float mix_in_mix;	
	float pak_in_mix;
	
	float org_in_org;	
	float mix_in_org;	
	float pak_in_org;
	
	float org_in_pak;	
	float mix_in_pak;	
	float pak_in_pak;
	
	
	// Variables needed to initialize simulation	
	int q_people;
	// End- initialization variables
	
	aspect base {
		// In case of using a shapefile
		draw shape color: #grey ;
	}
}


species house_hold schedules: []{ // 
	
	// Variables needed to initialize simulation
	list<resident> roomies;
	resi_build address;
	int max_people;
	int filling_peep;
	// End- initialization variables	
	
	//variables to track three types of waste
	float mix_max <- rnd(1.0,1.5);// In Kg
	float mix_cc;
	int mix_tick <-0;
	bool hh_mix_full <- mix_cc = 0 ? false : true;
	float org_in_mix;	
	float mix_in_mix;	
	float pak_in_mix;
	
	float org_max <- rnd(1.0,1.5);// In Kg
	float org_cc;
	int org_tick <-0;
	bool hh_org_full  <- org_cc = 0 ? false : true;
	float org_in_org;	
	float mix_in_org;	
	float pak_in_org;
	

	float pak_max <-rnd(1.0,2.0); // In Kg
	float pak_cc;
	int pak_tick <-0;
	bool hh_pak_full  <- pak_cc = 0 ? false : true;
	float org_in_pak;	
	float mix_in_pak;	
	float pak_in_pak;
	
	int space_bin min:0 max: 100;
	
	// The following reflexes that degreade waste
	reflex org_decompose when: (org_tick !=0) {
		org_tick <- org_tick + 1;		
	}
	
	reflex mix_decompose when: (mix_tick !=0) {
		mix_tick <- mix_tick + 1;		
	}
	
	reflex pak_decompose when: (pak_tick !=0) {
		pak_tick <- pak_tick + 1;		
	}
	
}

/// The residential buildings agent holds the hholds and is taken from the shapefile
species resi_build schedules: []{
	rgb color <- #black;	
	
	// Variables needed to initialize simulation
	int tot_pop;
	int hholds;
	list<house_hold> list_of_homes;
	// End- initialization variables
	
	
	aspect base {
		// In case of using a shapefile
		draw shape color: color ;
	}
	
	
	
}



species bin  schedules: [] {//
	rgb color;	
	
	// Variables needed to initialize simulation
	int id;
	string type;
	float current_cap;
	int used;

	float org;
	float mix;
	float pak;

	int info_org <- global_org_info min:0 max:100;
	int info_mix <- global_mix_info min:0 max:100;
	int info_pak <- global_pak_info min:0 max:100;
	
	int pop;
		
	aspect base {
		// In case of using a shapefile
		draw square(4) color: color ;
		
	}
	
	
}


species collector  schedules: [] {  //
	float from_prod_org;
	float from_prod_mix;
	float from_prod_pak;
	
	float from_prod_total;

	
	reflex restart when: (cycle>1) and every(3# cycle){
		
		// In kgrams
		from_prod_org <- from_prod_org + (prod_build sum_of(each.org_cc)) with_precision(2);
		from_prod_mix <- from_prod_mix + (prod_build sum_of(each.mix_cc)) with_precision(2);
		from_prod_pak <- from_prod_pak + (prod_build sum_of(each.pak_cc)) with_precision(2);
		
		// In grams
		from_prod_total <- (from_prod_pak + from_prod_org + from_prod_mix);
		
		
		ask prod_build {
		
			org_cc <- 0.0;
			mix_cc <- 0.0;
			pak_cc <- 0.0;			
			
		}
		
		
		
	}
	
	float from_res_total;
	float from_res_org;
	float from_res_mix;
	float from_res_pak;
	float res_org_IN_org;
	float res_mix_IN_org;
	float res_pak_IN_org;
	float res_org_IN_mix;
	float res_mix_IN_mix;
	float res_pak_IN_mix;
	float res_org_IN_pak;
	float res_mix_IN_pak;
	float res_pak_IN_pak;
	
	float KPI_org;
	float KPI_mix;
	float KPI_pak;
	
	float KPI_avg;



	// Tracking the waste disposal in each type of bin, every time they are collected 
	reflex clean_frequent when: ((cycle>1) and every(collect_freq# cycle) and clean_on) or 
								every(1094 #cycle) {
		
		// In grams, total amount of waste from each type of bin
		from_res_org <- from_res_org + (bin where (each.type='ORG') sum_of(each.current_cap)) with_precision(2);
		from_res_mix <- from_res_mix + (bin where (each.type='MIX') sum_of(each.current_cap)) with_precision(2);
		from_res_pak <- from_res_pak + (bin where (each.type='PAK') sum_of(each.current_cap)) with_precision(2);
		
		
		// In grams, total amoutn of waste
		from_res_total <- from_res_org + from_res_mix + from_res_pak;
		
		// Tracking each type of waste in each type of bin
		// org
		res_org_IN_org <- res_org_IN_org + (bin where (each.type='ORG') sum_of(each.org)) with_precision(2);
		res_mix_IN_org <- res_mix_IN_org + (bin where (each.type='ORG') sum_of(each.mix)) with_precision(2);
		res_pak_IN_org <- res_pak_IN_org + (bin where (each.type='ORG') sum_of(each.pak)) with_precision(2);
				
			
		// mix
		res_org_IN_mix <- res_org_IN_mix + (bin where (each.type='MIX') sum_of(each.org)) with_precision(2);
		res_mix_IN_mix <- res_mix_IN_mix + (bin where (each.type='MIX') sum_of(each.mix)) with_precision(2);
		res_pak_IN_mix <- res_pak_IN_mix + (bin where (each.type='MIX') sum_of(each.pak)) with_precision(2);

			
		// pak
		res_org_IN_pak <- res_org_IN_pak + (bin where (each.type='PAK') sum_of(each.org)) with_precision(2);
		res_mix_IN_pak <- res_mix_IN_pak + (bin where (each.type='PAK') sum_of(each.mix)) with_precision(2);
		res_pak_IN_pak <- res_pak_IN_pak + (bin where (each.type='PAK') sum_of(each.pak)) with_precision(2);
			
		// Percentage of corrected sorting	
		try{KPI_org <- ((res_org_IN_org/from_res_org)*100) with_precision(2);}
		try{KPI_mix <- ((res_mix_IN_mix/from_res_mix)*100) with_precision(2);}	
		try{KPI_pak <- ((res_pak_IN_pak/from_res_pak)*100) with_precision(2);}
		
		try{KPI_avg <- (KPI_pak + KPI_mix + KPI_org)/3 with_precision(2);}


		// reset the bin 	
		ask bin {
			used 		<- 	0;
			org 		<- 	0.0;
			mix 		<- 	0.0;
			pak 		<- 	0.0;
			current_cap <-	0.0;				
		}
		
		
	}
	
	
	// what is the purpose of the action empty_n_clean?
	// Only called in the beginning
	action empty_n_clean {
		from_res_org <- from_res_org + bin where (each.type='ORG') sum_of(each.current_cap)  with_precision(2);
		from_res_mix <- from_res_mix + bin where (each.type='MIX') sum_of(each.current_cap)  with_precision(2);
		from_res_pak <- from_res_pak + bin where (each.type='PAK') sum_of(each.current_cap)  with_precision(2);
		
		from_res_total <- (from_res_org + from_res_mix + from_res_pak); //*0.001
			
		// org
		res_org_IN_org <- from_res_org + bin where (each.type='ORG') sum_of(each.org)  with_precision(2);
		res_mix_IN_org <- from_res_mix + bin where (each.type='ORG') sum_of(each.mix)  with_precision(2);
		res_pak_IN_org <- from_res_pak + bin where (each.type='ORG') sum_of(each.pak)  with_precision(2);
			
		// org
		res_org_IN_mix <- from_res_org + bin where (each.type='MIX') sum_of(each.org)  with_precision(2);
		res_mix_IN_mix <- from_res_mix + bin where (each.type='MIX') sum_of(each.mix)  with_precision(2);
		res_pak_IN_mix <- from_res_pak + bin where (each.type='MIX') sum_of(each.pak)  with_precision(2);
			
		// org
		res_org_IN_pak <- from_res_org + bin where (each.type='PAK') sum_of(each.org)  with_precision(2);
		res_mix_IN_pak <- from_res_mix + bin where (each.type='PAK') sum_of(each.mix)  with_precision(2);
		res_pak_IN_pak <- from_res_pak + bin where (each.type='PAK') sum_of(each.pak)  with_precision(2);
			
		ask bin {
			used 		<- 	0;
			org 		<- 	0.0;
			mix 		<- 	0.0;
			pak 		<- 	0.0;
			current_cap <-	0.0;				
		}		
		
	}
	
}


species resident schedules: [] { //
	rgb color <- #orange;
	
	point my_place;
	resi_build home_place;
	point my_work;
	prod_build work_place;		
	house_hold h_unit;

	bin near_bin_org;
	bin near_bin_mix;
	bin near_bin_pak;	
	
	list<resident> my_org_comm;		
	list<resident> my_mix_comm;		
	list<resident> my_pak_comm;	

	list<resident> friend_list;		
	list<resident> roomies_list;
	list<resident> colleg_list;			
	
	bool home_office;	
	bool head_work 	<- false;
	bool at_work 	<- false;
	bool work_done <- at_work? true:false;
	int q_consume; //what is q_consume used for?
	
	
	// restart after one day
	reflex restart when: (cycle>1) and every(3# cycle){

		head_work				<- flip(early_start_proba) ? true:false;
		at_work 				<- false;
		work_done 				<- at_work? true:false;
		home_office				<- flip(home_office_proba) ? true:false;

		q_consume <- 0 ;
		do reset_waste_budget;		
		
	}	

	action decide_commute {
		
		if (flip(work_normal_proba) and not(home_office)) {
		
			if (not(at_work)) {				
				head_work 	<- true;
				at_work 	<- false;						
			} 
			
			else {			
				at_work 	<- true;
				head_work 	<- false;				
			} 
		
		}		
		
	}
	
	// The following action triggers the commute in the resident.
	// This is mainly based on the decide_commute
	// In the function the agent is transported into the non-resindetial place, and spends one step there.
	action commute {

		if(head_work and not(work_done)) {
			location 	<- my_work;
			at_work 	<- true;
			color 		<- #blue;
			work_done   <- true;
			
		}
		else {			
			location 	<- my_place;
			at_work 	<- false;		
			color 		<- # orange;	
			
		}
		
	}
	
	
		
	//////////////////////////////////////////////////////
	//// GET WASTE
	/////////////////////////////////////
	float set_consumption_org min:0.0 max:1.0;	// percentage of waste generation per time period (in one day)	
	float set_consumption_pak min:0.0 max:1.0;	
	float set_consumption_mix min:0.0 max:1.0;
	
	int budget_org; //total amount of waste generated per day (3 time periods)
	int budget_mix;
	int budget_pak;	
	
	int current_org; //amount of waste generation for the current time period
	int current_mix;
	int current_pak;	
	
	/// This is the main waste generation mechanims.
	// The proportions of waste generation vary along the day
	
	action get_waste {
		// The variable q_consume defines what proportion of waste is generated in each step
		// At the end of the action q_consume get a +1.
		if ( q_consume = 0 ) {
			set_consumption_pak 	<- rnd(0.00,  0.15) with_precision(2);		
			set_consumption_org 	<- rnd(0.10,  0.45) with_precision(2);		
			set_consumption_mix 	<- rnd(0.10,  0.35) with_precision(2);
		}
		
		if ( q_consume = 1 ) {
			set_consumption_pak 	<- rnd(0.00,  0.25) with_precision(2);		
			set_consumption_org 	<- rnd(0.20,  0.35) with_precision(2);		
			set_consumption_mix 	<- rnd(0.00,  0.25) with_precision(2);
		}
		
		// As waste gets generated, transfered from the budget of waste,
		// to the current waste of different types
		
		//////////////////////////// ORG /////////////////////////
		current_org 		<- int(budget_org * set_consumption_org);	
		budget_org 			<- budget_org - current_org;		

		//////////////////////////// MIX /////////////////////////
		current_mix 			<- int(budget_mix * set_consumption_mix); 		
		budget_mix 				<- budget_mix - current_mix;
		
		//////////////////////////// PAK /////////////////////////
		current_pak 			<- int(budget_pak * set_consumption_pak); 		
		budget_pak 				<- budget_pak - current_pak;	
				
		// Q waste is added one, so next time a different amount of waste gets assigned
		q_consume <- q_consume + 1;		
	}
	
	// This action is triggered to 
	// consume the last part of waste not consumed during the preious steps
	action get_d_rest {

		current_org <- budget_org;
		current_pak <- budget_pak;
		current_mix <- budget_mix;	
		
		// After the consumption of all waste is dones, q_consume variable is set to 0
		// q_consume is the trigger that defines the percentage of waste to get during the day
		q_consume <- 0;		
	}
	
	
	//This action is used to generate new waste,
	// This action is casted in the restart reflex which occurs very day
	action reset_waste_budget {
		budget_org <- int(gauss(org_day, org_day_sd));
		budget_mix <- int(gauss(mix_day, mix_day_sd));
		budget_pak <- int(gauss(pak_day, pak_day_sd));
	
		
	}
	

	action gen_waste { 

		
		//When q_consume 	-> 0;1
		if q_consume <=1 {
		

			do get_waste;
		} 
		// When q_consume 	-> 2				
		else {
			do get_d_rest;


		} 
		
		//do consolidate_totals;
	}
	
		
	////////////////////////////////////////////////
	//// Behaviour of waste separation
	///////////////////////////////	
		
	float 	mean_dist min:0.0 max:100.0;	
	float behaviour <- gauss(50,5) min:0.0 max:100.0; // Starting Behaviour value
	
	// The reflex calculates the behavior, based on the coefficient values from the fitted sem
	// Gauss distributions are used for each coefficient
	// Since there is no researchregarding how often we evluate our behaviors, the user can change this frequency
	reflex evaluate_beh when: (cycle>1) and every(beh_update# cycle){

		behaviour <- (gauss(beh_cont_b,beh_cont_se) + 
						gauss(int_2_beh_b,int_2_beh_se) * intention +
					 	gauss(pbc_2_beh_b,pbc_2_beh_se) * pbc +					 	
					 	gauss(know_2_beh_b,know_2_beh_se) * know +					 	
					 	gauss(dist_2_beh_b,dist_2_beh_se) * (mean_dist*dist_fine_tune) + 
					 	gauss(pant_2_beh_b,pant_2_beh_se) * PANT)/beh_fine_tune ;					 	
			}	
			
	///////////////////////
	// Intention
	////////////////////////////

	float 	intention min:0.0 max: 100.0;	
	
	// Intention evaluation follows the same logic used to evaluate behaviour	
		reflex evaluate_int when: every(6# cycle){		
		
		intention <- 	(int(gauss(int_cont_b,int_cont_se)    +
							gauss(sn_2_int_b,sn_2_int_se) * soc_norm  + 
							gauss(att_2_int_b,att_2_int_se) * attitude  +  
							gauss(pbc_2_int_b,pbc_2_int_se) * pbc		+
							gauss(know_2_int_b,know_2_int_se) * know) /int_fine_tune) with_precision(2);
							
		
	}
	
	////////////////////////////////
	///// For simplicity and readability the Constructs have been developed in actions, 
	////  that are called in these reflexes. It would make it easy to parametrize the frequency of update
	
	reflex resolve_pant when: every(3# cycle){
		do panting;		
	}	
	
	reflex evaluate_an when: (cycle>1) and every(10# cycle){
		do social_norm;		
	}
	
	reflex evaluate_att when: (cycle>1) and every(3# cycle){		
		do attitude;		
	}
			
	reflex evaluate_pbc when: (cycle>1) and every(3# cycle){
		do pbc;
	}
	
	reflex evaluate_know when: (cycle>1) and every(3# cycle){
		do knowledge;
	}
	

	////////////////////////////////////////
	//// PANT
	////////////////////////////////////////////
	
	int PANT;
	// Pant is a dummy variable that by itself that makes reference to engging in the return of continers
	// Empiriclly people that pant have a higher waste separtion rate
	action panting  {
		
		if (behaviour <= l1) 						{PANT <- int(flip(0.007*behaviour  + 0.00)		? true: false);}
		if (behaviour >= l2a and behaviour <= l2b) 	{PANT <- int(flip(0.026*behaviour  - 0.58)		? true: false);}
		if (behaviour >= l3a and behaviour <= l3b) 	{PANT <- int(flip(0.003*behaviour  + 0.70)		? true: false);}		
		if (behaviour >= l4) 						{PANT <- int(flip(0.004*behaviour  + 0.60)		? true: false);}
		
		
	
	}
	
	
	/// The constructs have a dynamic component and that make chances occur in a progressive matter.
	// The current values are stored in a temp variable and then the difference between the new and old vlues is calculated
	// The new varible value is the result of half its difference and its curent value.
	
	//////////////////////////////////////////////
	// SOCIAL NORMS
	////////////////////////////
	float soc_norm  			<- 	gauss(50,5) with_precision(2) 	min:0.0		max:100.0;	
	int friends_beh  			min:0 	max:100;
	int roomies_beh 			min:0 	max:100;
	int colleg_beh  			min:0 	max:100;
	float my_waste_community;
	int media_beh 				<- int(gauss(50,2)) 				min:0 		max:100;
	
 
	action social_norm {

		
		// My waste related Community is an averaged value of the behavior of waste bins
		my_waste_community 	<- 	wgt_org_comm*int(my_org_comm mean_of(each.behaviour)) +
		 						wgt_mix_comm*int(my_mix_comm mean_of(each.behaviour)) +
								wgt_pak_comm*int(my_pak_comm mean_of(each.behaviour));		
			
		// ROOMIES
		// Takes averages of the residents that share the same house hold unit
		roomies_beh 		<- int(roomies_list mean_of(each.behaviour));	

		// CO-WORKERS
		// Average of residents that share the non residental space
		colleg_beh 			<- int(colleg_list mean_of(each.behaviour));		

		// FRIENDS
		// The friends behavior is an average of the friends list
		try   { friends_beh 	<- int(friend_list mean_of (each.behaviour));}
		catch { friends_beh 	<-50;}

		float soc_norm_old 	<- soc_norm;
		
		//Adding place holdeers
		soc_norm <- (gauss(10,0.5)	 +
			gauss(friend_b,friend_se) * friends_beh +
			gauss(colleg_b,colleg_se) * colleg_beh + 
			gauss(roomies_b,roomies_se) * roomies_beh +
			gauss(media_b,media_se) * media_beh +
			gauss(waste_b,waste_se) * my_waste_community) /sn_fine_tune;
	
	
					
		float soc_norm_diff <- soc_norm - soc_norm_old;
		
		soc_norm <- soc_norm_old + 0.5 * soc_norm_diff;

		

		
	}
	
	
////////////////////////////////////////////////
//// ATTITUDE
//////////////////////////////
	
	float attitude <- gauss(80,10) min: 0.0 max: 100.0;
	
	// Attitude is the only construct that is not linked with the simulation.
	// This process comes externlly and its is a normal distributed variable based on empirical observations
	action attitude {
		
		float att_old <- attitude;
		
		attitude <- gauss(att_b,att_se) / att_fine_tune;

		float att_diff <- attitude - att_old;
		
		attitude <- att_old + 0.5*att_diff;	
	
	}	
	
	
	
////////////////////////////////////////////////
//// Knowledge
//////////////////////////////
	int avg_bin_info  min: 0 max: 100;
	float know <- gauss(60,2) min:0.0 max:100.0;	
	// This is an extension of the TPB that includes information related variables.
	// Information in bins is an item inside the constructs
	action knowledge {
		
		float know_old <- know;
		
			avg_bin_info <- int((near_bin_org.info_org + 
			near_bin_mix.info_mix + 
			near_bin_pak.info_pak) /3);		
		
		know <- (gauss(know_b,know_se) + 
			gauss(info_b,info_se) * avg_bin_info) / know_fine_tune;


		float know_diff <- know - know_old;
		
		know <- know_old + 0.5*know_diff;		
		
	}
		
		
	
//	//////////////////////////////////////////////
//	// PBC
//	////////////////////////////
	float pbc 		<- gauss(58.46,5.25)  min: 0.0 max: 100.0;		
	int hygenic 	min: 0 max: 100;
	int space 		min: 0 max: 100;		   
	int pleasant 	<- int(gauss(35,3)) 	min: 0 max: 100;
	int time 		<- int(gauss(35,3))		min: 0 max: 100;
	

 // PBC is calculated below. 
 // The models uses the variable hygenic (used) as the item to inside the construct
 // This construct also includes percieved space in waste bins


	action pbc {
		
		hygenic 	<- int(
			(near_bin_org.used / near_bin_org.pop)*100 + 
				(near_bin_mix.used/near_bin_mix.pop)*100 + 
					(near_bin_pak.used/near_bin_pak.pop)*100);
					
		
		float pbc_old <- pbc;
		
		pbc <- (gauss(pbc_b,pbc_se) + 
				   gauss(hygen_b,hygen_se) * (hygenic*pbc_fine_hygenic) + 
				   gauss(time_b,time_se)  * time + 
				   gauss(pleasant_b,pleasant_se)  * pleasant +
				   gauss(space_b,space_se)  * space ) / pbc_fine_tune;
				   
				   
		
		float pbc_diff <- pbc - pbc_old;
		
		pbc <- pbc_old + 0.2*pbc_diff;		
		

	}


	
	////////////////////////////////
	///////BEH MENU
	//////////////////////////
	
	
	string beh_label;
	int beh_level;
	
	int p_mix_in_mix min:0 max:100;
	int p_mix_in_org min:0 max:100;
	int	p_mix_in_pak min:0 max:100;
		
	int	p_org_in_org min:0 max:100;
	int	p_org_in_mix min:0 max:100;
	int	p_org_in_pak min:0 max:100;
		
	int	p_pak_in_pak min:0 max:100;
	int	p_pak_in_mix min:0 max:100;
	int	p_pak_in_org min:0 max:100;
	
	
	action main_beh {
		// Placeholders for more extensive models where behaviour could
		// be broken in 2 or 5 chunks. Here I do it with 4.
		// To be uploded on request. This is part of future studies
		if (q_breaks_string ="4 lines")   {do set_beh_4_lines;}	 

	}

	
	action checks {
		
		// For Mix
		if (p_mix_in_mix+p_mix_in_org) > 100 {
			p_mix_in_org <-0;
			p_mix_in_pak <-0;} 
			
		else if ((p_mix_in_mix+p_mix_in_org) = 100) {
				p_mix_in_pak <-0; } 
								
		else {p_mix_in_pak <- 100 - p_mix_in_mix - p_mix_in_org;}
		
		// For Org		
		if (p_org_in_org+p_org_in_mix) > 100 {
			p_org_in_mix <-0;
			p_org_in_pak <-0;} 
			
		else if ((p_org_in_org+p_org_in_mix) = 100) {
				p_org_in_pak <-0; } 
								
		else {p_org_in_pak <- 100 - p_org_in_mix - p_org_in_org;}
		
		// For Pak	
		if (p_pak_in_pak+p_pak_in_mix) > 100 {
			p_pak_in_mix <-0;
			p_pak_in_org <-0;} 
			
		else if ((p_pak_in_pak+p_pak_in_mix) = 100) {
				p_pak_in_org <-0; } 
								
		else {p_pak_in_org <- 100 - p_pak_in_pak - p_pak_in_mix;}

		
		
	}
	
	
	
	action classify_4 {
		////////////////
		/// Labels
		//////////////////////	
		if (behaviour <= l1) 					 	{beh_label <- "V.BAD";}  	// (behaviour <= 59) 
		if (behaviour >= l2a and behaviour <= l2b) 	{beh_label <- "BAD";} 		// (behaviour >= 60 and behaviour <= 79)
		if (behaviour >= l3a and behaviour <= l3b) 	{beh_label <- "GOOD";}  	// (behaviour >= 80 and behaviour <= 89)
		if (behaviour >= l4)      		            {beh_label <- "V.GOOD";}	// (behaviour >= 90) 
		
		
		////////////////
		/// Levels
		//////////////////////	
		if (behaviour <= l1) 						{beh_level <- 1;}
		if (behaviour >= l2a and behaviour <= l2b) 	{beh_level <- 2;}
		if (behaviour >= l3a and behaviour <= l3b) 	{beh_level <- 3;}		
		if (behaviour >= l4) 						{beh_level <- 4;}
	}
	
		
	action set_beh_4_lines {
	
	
		do classify_4;		

					
		if (beh_level = 1) {
			// Sorting probability
			// OF MIX
			p_mix_in_mix <- int(truncated_gauss(((2.17*behaviour)+0),2.5));  //ok
			p_mix_in_org <- 0;	 		

			// OF ORG
			p_org_in_org <- int(truncated_gauss(((1*behaviour)+0),2.5));       //ok
			p_org_in_mix <- int(truncated_gauss(((-1.34*behaviour)+100),5));	//ok
			
					
			// OF PAK
			p_pak_in_pak <- int(truncated_gauss(((2*behaviour)+0),5));  //ok
			p_pak_in_mix <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok
			

						
			}
			
		if (beh_level = 2) {
			// Sorting probability
			// OF MIX
			p_mix_in_mix <- int(truncated_gauss(((2*behaviour) + 53),5)); //ok
			p_mix_in_org <- 0;			

			// OF ORG
			p_org_in_org <- int(truncated_gauss(((0.8*behaviour)+21),5));   //ok
			p_org_in_mix <-int(truncated_gauss(((-1.2*behaviour)+96),5));	//ok	
	
			// OF PAK
			p_pak_in_pak <- int(truncated_gauss(((0.2*behaviour)+69),5));  //ok
			p_pak_in_mix <- int(truncated_gauss(((-1.2*behaviour)+116),5));	//ok
			

		
		}		

		if (beh_level = 3) {

			// Sorting probability
			// OF MIX
			p_mix_in_mix <- int(truncated_gauss(((0.3*behaviour) + 61),5)); //ok
			p_mix_in_org <- int(truncated_gauss(2,2));			

			// OF ORG
			p_org_in_org <- int(truncated_gauss(((0.8*behaviour)+23),5));  //ok
			p_org_in_mix <- int(truncated_gauss(((-1*behaviour)+85),5));   //ok

			// OF PAK
			p_pak_in_pak <- int(truncated_gauss(((0.3*behaviour)+66),5));  //ok
			p_pak_in_mix <- int(truncated_gauss(((-1.3*behaviour)+118),5));	//ok

			

			}
			
		if (beh_level = 4) {		

			// Sorting probability
			// OF MIX
			p_mix_in_mix <- int(truncated_gauss(((0.8*behaviour) + 20),5)); //ok
			p_mix_in_org <- int(truncated_gauss(1,1	));

			// OF ORG
			p_org_in_org <- int(truncated_gauss(((0.8*behaviour)+20),5));  //ok
			p_org_in_mix <- int(truncated_gauss(((-0.4*behaviour)+40),5)); //ok

			// OF PAK
			p_pak_in_pak <- int(truncated_gauss(((0.6*behaviour)+40),5));  //ok
			p_pak_in_mix <- int(truncated_gauss(((-1*behaviour)+100),5));	//ok

			
		}		
		
		//Check ups
		do checks;
		
		
		
	}
	
	
	
	////////////////////////////////////
	////// Throw of waste 
	////////////////////////////////////////7
	int rnd_num;
	
	action internal_throw {
	
		
		rnd_num <- rnd(100);
		
		if (not(at_work)) {
		
			do internal_throw_home;
		}
		
		// dump at work
		if (at_work) 	  {
		
			//dump with tpb
			if (work_tpb) {
			
			//simple dump - we are not tracking this situation
			} else {
				do throw_prod;
			}
			
			//
		}		
		
		do reset_currents;
		
	}
	
	// After the waste is transfered out to the waste bins
	// the waste generated is set to 0
	action reset_currents {
		
		current_org <-0;
		current_mix <-0;
		current_pak <-0;
		org_dumped <- false;
		mix_dumped <- false;
		pak_dumped <- false;
	}
	

	bool org_dumped <- false;
	bool mix_dumped <- false;
	bool pak_dumped <- false;
	
	// Throw waste inside of their households bins
	action internal_throw_home {		

		////////// Throw organics
		if(flip(p_org_in_org/100) and not(org_dumped)) {
		//if(p_org_in_org >= rnd_num and not(org_dumped)) {

			h_unit.org_cc 			<- h_unit.org_cc + current_org*0.001;
			h_unit.org_in_org		<- h_unit.org_in_org + current_org*0.001;		
			if (h_unit.org_tick = 0) {h_unit.org_tick <- 1;} 
			org_dumped <- true;
		}		
		
		if(flip(p_org_in_mix/100) and not(org_dumped)) {
		//if(p_org_in_mix >= rnd_num  and not(org_dumped)) {

			h_unit.mix_cc 			<- h_unit.mix_cc + current_org*0.001;
			h_unit.org_in_mix		<- h_unit.org_in_mix + current_org*0.001;
			if (h_unit.mix_tick = 0) {h_unit.mix_tick <- 1;} 	
			org_dumped <- true;		
		}

		////////// Throw residuals
		if(flip(p_mix_in_mix/100) and not(mix_dumped)) {			

			h_unit.mix_cc 			<- h_unit.mix_cc + current_mix*0.001;
			h_unit.mix_in_mix		<- h_unit.mix_in_mix + current_mix*0.001;	
			if (h_unit.mix_tick = 0) {h_unit.mix_tick <- 1;} 
			mix_dumped <- true;	
		}
		
		if(flip(p_mix_in_org/100)  and not(mix_dumped)) {	
				
			h_unit.org_cc 			<- h_unit.org_cc + current_mix*0.001;
			h_unit.mix_in_org		<- h_unit.mix_in_org + current_mix*0.001;
			if (h_unit.org_tick = 0) {h_unit.org_tick <- 1;} 	
			mix_dumped <- true;	
		}		
		
		if(flip(p_mix_in_pak/100) and not(mix_dumped)) {	

			h_unit.pak_cc 			<- h_unit.pak_cc + current_mix*0.001;
			h_unit.mix_in_pak		<- h_unit.mix_in_pak + current_mix*0.001;		
			if (h_unit.pak_tick = 0) {h_unit.pak_tick <- 1;} 	
			mix_dumped <- true;	
		}
		
		////////// Throw packages
		if(flip(p_pak_in_pak/100) and not(pak_dumped)) {		

			h_unit.pak_cc 			<- h_unit.pak_cc + current_pak*0.001;
			h_unit.pak_in_pak		<- h_unit.pak_in_pak + current_pak*0.001;		
			if (h_unit.pak_tick = 0) {h_unit.pak_tick <- 1;} 	
			pak_dumped <- true;
		}		
		
		if(flip(p_pak_in_mix/100) and not(pak_dumped)) {
		
			h_unit.mix_cc 			<- h_unit.mix_cc + current_pak*0.001;
			h_unit.pak_in_mix		<- h_unit.pak_in_mix + current_pak*0.001;	
			if (h_unit.mix_tick = 0) {h_unit.mix_tick <- 1;} 	
			pak_dumped <- true;	
		}
		
	// Secure some dump - Process to make sure that some waste is dumped.
	// In case the probabilities all pass and nothing has passed
	if not(org_dumped) {
		
		h_unit.mix_cc 			<- h_unit.mix_cc + current_org*0.001;
		h_unit.org_in_mix		<- h_unit.org_in_mix + current_org*0.001;
		if (h_unit.mix_tick = 0) {h_unit.mix_tick <- 1;} 	
		org_dumped <- true;		
		}
		
	if not(mix_dumped) {
		if flip(0.8) {
		
			h_unit.org_cc 			<- h_unit.org_cc + current_mix*0.001;
			h_unit.mix_in_org		<- h_unit.mix_in_org + current_mix*0.001;
			if (h_unit.org_tick = 0) {h_unit.org_tick <- 1;} 	
			mix_dumped <- true;		
			}
		else {
			
			h_unit.pak_cc 			<- h_unit.pak_cc + current_mix*0.001;
			h_unit.mix_in_pak		<- h_unit.mix_in_pak + current_mix*0.001;		
			if (h_unit.pak_tick = 0) {h_unit.pak_tick <- 1;} 	
			mix_dumped <- true;				
		}
	}
	
	if not(pak_dumped) {
		h_unit.mix_cc 			<- h_unit.mix_cc + current_pak*0.001;
		h_unit.pak_in_mix		<- h_unit.pak_in_mix + current_pak*0.001;	
		if (h_unit.mix_tick = 0) {h_unit.mix_tick <- 1;} 	
		pak_dumped <- true;
	}
	
	
	// make the bins full
	if (h_unit.org_cc >= h_unit.org_max){h_unit.hh_org_full<-true;}
	if (h_unit.mix_cc >= h_unit.mix_max){h_unit.hh_mix_full<-true;}
	if (h_unit.pak_cc >= h_unit.pak_max){h_unit.hh_pak_full<-true;}		
	
	}
	
	///////////////////////7
	/// Move waste out from the household to the bins
	/////////////////////////////////////

	// Since the residents are at not all the time at home, part of waste is thrown in non residetianl bins
	// Theroy suggests that waste sorting at work could follow specific behavior
	// on request this can be changed, and tpb behavior is included in previous versions.	
	action throw_prod {

		////////// Throw organics
		work_place.org_cc 			<- work_place.org_cc + current_org*0.001;	
					
		////////// Throw residuals	
		work_place.mix_cc 			<- work_place.mix_cc + current_mix*0.001;				
		
		////////// Throw packages
		work_place.pak_cc 			<- work_place.pak_cc + current_pak*0.001;	
		
	}
	
	
	// The action of transfering waste out is divided by waste types
	// Since residents can throw waste incorrectly, if the percentage of miss soring is more than 50%
	// This means that waste is not sorted	
	action transfer_org_out {		
		//		Penalty		
		// percentage of miss sorting, if it is more than a threshold
		if (((h_unit.mix_in_org + h_unit.pak_in_org) / (h_unit.org_cc + 0.001)) >= thold_wrong_org) { /// 0.001 secures that the division is not 0
	
			
			near_bin_mix.current_cap <- near_bin_mix.current_cap +  h_unit.org_cc;		
			near_bin_mix.used <- near_bin_mix.used + 3;		
			
			//Continue tracking types
			near_bin_mix.org <- near_bin_mix.org + h_unit.org_in_org;
			near_bin_mix.mix <- near_bin_mix.mix + h_unit.mix_in_org;
			near_bin_mix.pak <- near_bin_mix.pak + h_unit.pak_in_org;
			
		}
		// sorted correctly
		else {				
				
			near_bin_org.current_cap <- near_bin_org.current_cap +  h_unit.org_cc;		
			near_bin_org.used <- near_bin_org.used + 1;
			
			//Continue tracking types
			near_bin_org.org <- near_bin_org.org + h_unit.org_in_org;
			near_bin_org.mix <- near_bin_org.mix + h_unit.mix_in_org;
			near_bin_org.pak <- near_bin_org.pak + h_unit.pak_in_org;
		
		}
	
		h_unit.org_cc 			<- 0.0;
		h_unit.hh_org_full		<- false;
		h_unit.org_tick 		<- 0;	
		
		// reseting after dump
	 	h_unit.org_in_org <-0.0;	
	 	h_unit.mix_in_org <-0.0;	
	 	h_unit.pak_in_org <-0.0;
		
		q_empty_org <- q_empty_org + 1;
		h_unit.org_max <- rnd(1.0,1.5);
	}

	action transfer_mix_out {			
		// simple			
		near_bin_mix.current_cap <- near_bin_mix.current_cap +  h_unit.mix_cc;
		near_bin_mix.used <- near_bin_mix.used + 1;
		
		//Continue tracking types
		near_bin_mix.org <- near_bin_mix.org + h_unit.org_in_mix;
		near_bin_mix.mix <- near_bin_mix.mix + h_unit.mix_in_mix;
		near_bin_mix.pak <- near_bin_mix.pak + h_unit.pak_in_mix;
		
				
		h_unit.mix_cc 			<- 0.0;
		h_unit.hh_mix_full		<- false;
		h_unit.mix_tick 		<- 0;	
		
		// reseting after dump
	 	h_unit.org_in_mix <-0.0;	
	 	h_unit.mix_in_mix <-0.0;	
	 	h_unit.pak_in_mix <-0.0;
		
		q_empty_mix <- q_empty_mix + 1;	
		h_unit.mix_max <- rnd(1.0,1.5);		
	}
		
	action transfer_pak_out {				
		if (((h_unit.mix_in_pak + h_unit.org_in_pak) / h_unit.pak_cc+0.001) >= thold_wrong_pak) {		/// 0.001 secures that the division is not 0	
			
			near_bin_mix.current_cap <- near_bin_mix.current_cap +  h_unit.pak_cc;		
			near_bin_mix.used <- near_bin_mix.used + 3;		
			
			//Continue tracking types
			near_bin_mix.org <- near_bin_mix.org + h_unit.org_in_pak;
			near_bin_mix.mix <- near_bin_mix.mix + h_unit.mix_in_pak;
			near_bin_mix.pak <- near_bin_mix.pak + h_unit.pak_in_pak;
			
		}
		
		else {
			near_bin_pak.current_cap <- near_bin_pak.current_cap +  h_unit.pak_cc;		
			near_bin_pak.used <- near_bin_pak.used + 1;
		
			//Continue tracking types
			near_bin_pak.org <- near_bin_pak.org + h_unit.org_in_pak;
			near_bin_pak.mix <- near_bin_pak.mix + h_unit.mix_in_pak;
			near_bin_pak.pak <- near_bin_pak.pak + h_unit.pak_in_pak;
		
		}
		
		// Penalty
		h_unit.pak_cc 			<- 	0.0;
		h_unit.hh_pak_full		<-	false;
		h_unit.pak_tick 		<-	0;	
			
		// reseting after dump
	 	h_unit.org_in_pak 		<-	0.0;	
	 	h_unit.mix_in_pak 		<-	0.0;	
	 	h_unit.pak_in_pak 		<-	0.0;
	 	
	 	q_empty_pak 			<- 	q_empty_pak + 1;
	 	h_unit.pak_max 			<-	rnd(1.0,2.0);

				
	}
	
	// These metrics help to track how many times the residents go outside to dispose waste
	int q_empty_org;
	int q_empty_mix;
	int q_empty_pak;

	// The following action defines how residesnts dispose of their waste materials
	// The waste transfer to bins is specific for the different bins. 
	// This action occurs is called in the main reflex, and occurs if...
	// The waste bin is full and the waste has been there for some days
	action throw_all_out {				
	////////// ORGANICS
		//organics - general
		if (h_unit.hh_org_full and h_unit.org_cc >0)  { 				
				do transfer_org_out; 			
			}			
			
		// // Disposal when waste degreades
		if (h_unit.org_tick/3) > rnd(4,6) {				
				do transfer_org_out; 				
			}	
			
	//////////////MIX
		// mix - general	
		if (h_unit.hh_mix_full and h_unit.mix_cc >0){				
				do transfer_mix_out; 
			}
		// Disposal when waste degreades	
		if (h_unit.mix_tick/3) > rnd(5,8) {				
				do transfer_mix_out; 
			}			
			
	///////////// PAK
		// General disposal mechanism		
		if (h_unit.hh_pak_full and h_unit.pak_cc >0){				
				do transfer_pak_out;				
			}	
		// Disposal when waste degreades	
		if (h_unit.pak_tick/3) > rnd(5,14) {				
				do transfer_pak_out; 				
			}	
		
	}

	//////////////////////////////////////////
	// Schedule my daily routine
	////////////////////////////////////////////
	
	// This is the main reflex of the resident
	reflex day_activity {
		// Main behaviour
		do main_beh;
		
		/// Commute is the last part of the cycle				
		do commute;		
		
		////// Generate waste			
		do gen_waste;			
		
		// throw internally
		do internal_throw;
		
		// Transfer waste out
		do throw_all_out;
		
		// Decide to commute
	    do decide_commute;	
		
	}	
	
	aspect base {
		draw circle(1) color: color;
	}
	
}



// This is the main experiment that shows how behavior and how is linked to the percentages of miss sorting
experiment waste_sort type: gui {		
	
	user_command "Clean bins" category: "During simulation" color:#green {
		ask collector {do empty_n_clean;}
	}	
	
	parameter "Clean frequently" var: clean_on category:"During simulation";
	parameter "TPB at work" var: work_tpb category:"During simulation";
	
	user_command "Increase org info" category: "During simulation" color:#blue {
		ask world {do increase_org_info;}
	}
	
	user_command "Decrease org info" category: "During simulation" color:#red {
		ask world {do decrease_org_info;}
	}
	
	user_command "Increase mix info" category: "During simulation" color:#blue {
		ask world {do increase_mix_info;}
	}
	
	user_command "Decrease mix info" category: "During simulation" color:#red {
		ask world {do decrease_mix_info;}
	}

	user_command "Increase pak info" category: "During simulation" color:#blue {
		ask world {do increase_pak_info;}
	}
	
	user_command "Decrease pak info" category: "During simulation" color:#red {
		ask world {do decrease_pak_info;}
	}
	
	user_command "Increase Hhold bins size" category: "During simulation" color:#blue {
		ask world {do increase_hhold_bin_space;}
	}	

	user_command "Decrease Hhold bins size" category: "During simulation" color:#red {
		ask world {do decrease_hhold_bin_space;}
	}

	parameter "Collection frequency" 	
		var: collect_freq min: 1 max: 365 step: 1
		category: "During simulation";
		
    
	////// Movement of people
	parameter "Probability of early out" 	
		var: early_start_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		
	parameter "Probability of home-stay" 	
		var: home_office_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		
	parameter "Probability of morning start" 	
		var: work_normal_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		

	
	parameter "Select bins"  var: shape_file_bin extensions: ["shp"] in_workspace: true
		category: "Scenario definition" ;
		
	parameter "Select residential"    var: shape_file_residential extensions: ["shp"] in_workspace: true
		category: "Scenario definition";
		
	parameter "Select productive"   var: shape_file_productive extensions: ["shp"] in_workspace: true
		category: "Scenario definition";	

	parameter "Info in Org"   var: global_org_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
	
	parameter "Info in Mix"   var: global_mix_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
		
	parameter "Info in Pak"   var: global_pak_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
		
	parameter "Space at home mean"   var: space_mean min: 0 max: 100 step: 1
		category: "Scenario definition";	
		
	parameter "Space at home sd"   var: space_sd min: 0 max: 100 step: 1
		category: "Scenario definition";	
		
	parameter "Scale distance"   var: scale_dist min: 0.0 max: 10.0 step: 0.1
		category: "Scenario definition";		
		
				
			
	parameter "beh fine_tune"   var: beh_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";			
	
	parameter "dist fine_tune"   var: dist_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "int fine_tune"   var: int_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
			
	parameter "sn fine_tune"   var: sn_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
					
	parameter "att fine_tune"   var: att_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";			
						
	parameter "pbc fine_tune"   var: pbc_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "know fine_tune"   var: know_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "hygenic fine_tune"   var: pbc_fine_hygenic min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
	
	output {


	display "Waste sorting behaviour category" type:2d {
			
			chart "Behaviour distribution" type:histogram
			 	x_serie_labels: ["Behaviour"]
			 
			series_label_position: onchart
			 {	if (q_breaks_string ="5 types") {
			 	datalist value:
				
				[
					[resident count(each.beh_level = 1)],
					
					[resident count(each.beh_level = 2)],
					
					[resident count(each.beh_level = 3)],
					
					[resident count(each.beh_level = 4)],
					
					[resident count(each.beh_level = 5)]
					]
					   style:bar 
					   legend:["V.Bad","Bad", "Normal", "Good", "V.Good"]
					   color: [#red, #orange, #grey, #green, # blue];				
			}
			if (q_breaks_string ="4 types" or q_breaks_string ="4 lines") {
				datalist value:
				
				[
					[resident count(each.beh_level = 1) ],
					
					[resident count(each.beh_level = 2)],
					
					[resident count(each.beh_level = 3)],
					
					[resident count(each.beh_level = 4)]
					]
					   style:bar 
					   legend:["V.Bad","Bad", "Good", "V.Good"]
					   color: [#red, #orange, #green, # blue];				
			}	
			
			}		
					
		}
		
		display "Waste sorting behaviour value"  type:2d{
			
//			chart "Behaviour distribution" type:histogram
//			 	x_serie_labels: ["Behaviour"]
//			 	series_label_position: xaxis
//			 	{ 
//			 		datalist value:(distribution_of(resident collect each.behaviour,20,0,100) at "values")
//			 		 legend:(distribution_of(resident collect each.behaviour,20,0,100) at "legend"); 				 
//			 }				
			
		}
		


			
	display "Waste type in STREET bins"  type:2d {
			chart "Waste inside of STREET bins" type:histogram
			 	x_serie_labels: ["Organic bin", "Residual bin", "Recyclable bin"]
			 	
			series_label_position: legend
			 {
				datalist value:[
					
					[	(sum(bin where (each.type = "ORG") collect each.org)),
						(sum(bin where (each.type = "MIX") collect each.org)),
						(sum(bin where (each.type = "PAK") collect each.org))],
						
					[	(sum(bin where (each.type = "ORG") collect each.mix)),
						(sum(bin where (each.type = "MIX") collect each.mix)),
						(sum(bin where (each.type = "PAK") collect each.mix))],
						
					[	(sum(bin where (each.type = "ORG") collect each.pak)),
						(sum(bin where (each.type = "MIX") collect each.pak)),
						(sum(bin where (each.type = "PAK") collect each.pak))]

						
					]
					   style:stack 
					   legend:["Organic", "Residual", "Recyclable"]
					   color: [	(#green),(#red), (#blue)];
			}
		
								
		}
		

	display "Waste type collected" type:2d {
			chart "Waste type collected" type:histogram
			 	x_serie_labels: ["Organic bin", "Residual bin", "Recyclable bin"]
			 	
			series_label_position: legend
			 {
				datalist value:[
					
					[	(collector  collect each.res_org_IN_org),
						(collector  collect each.res_mix_IN_org),
						(collector  collect each.res_pak_IN_org)],
						
						[(collector  collect each.res_org_IN_mix),
						(collector  collect each.res_mix_IN_mix),
						(collector  collect each.res_pak_IN_mix)],
						
					[	(collector  collect each.res_org_IN_pak),
						(collector  collect each.res_mix_IN_pak),
						(collector  collect each.res_pak_IN_pak)]

						
					]
					   style:stack 
					   legend:["Organic", "Residual", "Recyclable"]
					   color: [	(#green),(#red), (#blue)];
			}
		
								
		}		

		
	display "Waste type in home bins"  type:2d {
			chart "Waste inside of home bins" type:histogram
			 	x_serie_labels: ["Organic bin", "Residual bin", "Recyclable bin"]
			 	
			series_label_position: legend
			 {
				datalist value:[
					[	(sum(house_hold collect each.org_in_org)),
						(sum(house_hold collect each.mix_in_org)),
						(sum(house_hold collect each.pak_in_org))],
						
					[	(sum(house_hold collect each.mix_in_org)),
						(sum(house_hold collect each.mix_in_mix)),
						(sum(house_hold collect each.mix_in_pak))],
						
					[	(sum(house_hold collect each.pak_in_org)),
						(sum(house_hold collect each.pak_in_mix)),
						(sum(house_hold collect each.pak_in_pak))]
						
					]
					   style:stack 
					   legend:["Organic", "Residual", "Recyclable"]
					   color: [	(#green),(#red), (#blue)];
			}
		
								
		}
		
	
	display "Beh - Behaviour" type:2d {
		chart "Behaviour" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.behaviour 	color: #red marker_shape: marker_empty;		
			data "Avg" 	value: resident mean_of 	each.behaviour 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.behaviour 	color: #blue marker_shape: marker_empty;	
			}
		}	

		
		display "KPIs - instant track" type:2d {
			chart "KPIs" type: series  x_serie_labels: cycle{
				data "kpi org t" 	value: KPI_org_t color: #green;				
				data "kpi mix t" 	value: KPI_mix_t color: #red;				
				data "kpi pak t" 	value: KPI_pak_t color: #blue;				
				data "kpi avg t" 	value: KPI_avg_t color: #black;				
				}
			}		
		
		display city  type:2d {
			species bin aspect:base;			
			species prod_build aspect:base;
			species resi_build aspect:base;
			species resident aspect:base;
			species collector;	
			
		}
		
	}
	
}


// This experiment shows the only the tpb constructs and how behavior evolves
experiment only_tpb type: gui{
	
	user_command "Clean bins" category: "During simulation" color:#green {
		ask collector {do empty_n_clean;}
	}
	
	
	parameter "Clean frequently" var: clean_on category:"During simulation";
	parameter "TPB at work" var: work_tpb category:"During simulation";	
	
	
	user_command "Increase org info" category: "During simulation" color:#blue {
		ask world {do increase_org_info;}
	}
	
	user_command "Decrease org info" category: "During simulation" color:#red {
		ask world {do decrease_org_info;}
	}
	
	user_command "Increase mix info" category: "During simulation" color:#blue {
		ask world {do increase_mix_info;}
	}
	
	user_command "Decrease mix info" category: "During simulation" color:#red {
		ask world {do decrease_mix_info;}
	}

	user_command "Increase pak info" category: "During simulation" color:#blue {
		ask world {do increase_pak_info;}
	}
	
	user_command "Decrease pak info" category: "During simulation" color:#red {
		ask world {do decrease_pak_info;}
	}	
	
	
	user_command "Increase Hhold bins size" category: "During simulation" color:#blue {
		ask world {do increase_hhold_bin_space;}
	}	

	user_command "Decrease Hhold bins size" category: "During simulation" color:#red {
		ask world {do decrease_hhold_bin_space;}
	}	
	
	
	parameter "Collection frequency" 	
		var: collect_freq min: 1 max: 365 step: 1
		category: "During simulation";
		
		
	parameter "Beh update" 	
		var: beh_update min: 1 max: 90 step: 1
		category: "TPB";			
		
    
	////// Movement of people
	parameter "Probability of early out" 	
		var: early_start_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		
	parameter "Probability of home-stay" 	
		var: home_office_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		
	parameter "Probability of morning start" 	
		var: work_normal_proba min: 0.0 max: 1.0 step: 0.01
		category: "Commute";
		
		
	////////////////////// Scenario /////////////////////////
	parameter "Select bins"  var: shape_file_bin extensions: ["shp"] in_workspace: true
		category: "Scenario definition" ;
		
	parameter "Select residential"    var: shape_file_residential extensions: ["shp"] in_workspace: true
		category: "Scenario definition";
		
	parameter "Select productive"   var: shape_file_productive extensions: ["shp"] in_workspace: true
		category: "Scenario definition";		
		
	parameter "Info in Org"   var: global_org_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
	
	parameter "Info in Mix"   var: global_mix_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
		
	parameter "Info in Pak"   var: global_pak_info min: 0 max: 100 step: 5
		category: "Scenario definition";	
		
	parameter "Space at home mean"   var: space_mean min: 0 max: 100 step: 1
		category: "Scenario definition";	
		
	parameter "Space at home sd"   var: space_sd min: 0 max: 100 step: 1
		category: "Scenario definition";	
		
	parameter "Scale distance"   var: scale_dist min: 0.0 max: 10.0 step: 0.1
		category: "Scenario definition";		
		
			
				
	parameter "beh fine_tune"   var: beh_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";			
	
	parameter "dist fine_tune"   var: dist_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "int fine_tune"   var: int_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
			
	parameter "sn fine_tune"   var: sn_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
					
	parameter "att fine_tune"   var: att_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";			
						
	parameter "pbc fine_tune"   var: pbc_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "know fine_tune"   var: know_fine_tune min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	parameter "hygenic fine_tune"   var: pbc_fine_hygenic min: 0.0 max: 10.0 step: 0.01
		category: "Fine tuning";		
		
	
	
	
	output {
		display "Waste sorting behaviour value" type:java2D {
			
			chart "Behaviour distribution" type:histogram
			 	x_serie_labels: ["Behaviour"]
			 	series_label_position: xaxis
			 	{ 
			 		datalist value:(distribution_of(resident collect each.behaviour,20,0,100) at "values")
			 		 legend:(distribution_of(resident collect each.behaviour,20,0,100) at "legend"); 				 
			 }				
			
		}

		
	display "Beh - ATT" type:java2D{
		chart "Attitude" type: series   x_serie_labels: cycle   {
			data "Min" 	value: resident min_of 		each.attitude 	color: #red marker_shape: marker_empty;		
			data "Avg" 	value: resident mean_of 	each.attitude 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.attitude 	color: #blue marker_shape: marker_empty;	
			}
		}

	display "Beh - SN" type:java2D{
		chart "Social norm" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.soc_norm 	color: #red marker_shape: marker_empty;		
			data "Avg" 	value: resident mean_of 	each.soc_norm 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.soc_norm 	color: #blue marker_shape: marker_empty;	
			}
		}
		
	display "Beh - PBC" type:java2D   {
		chart "PBC" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.pbc 	color: #red marker_shape: marker_empty ;		
			data "Avg" 	value: resident mean_of 	each.pbc 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.pbc 	color: #blue marker_shape: marker_empty;	
			}
		}	
		
	display "Beh - Know" type:java2D{
		chart "Know" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.know 	color: #red marker_shape: marker_empty ;		
			data "Avg" 	value: resident mean_of 	each.know 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.know 	color: #blue marker_shape: marker_empty;	
			}
		}
		
	display "Beh - PANT" type:java2D{
		chart "PANT" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.PANT 	color: #red marker_shape: marker_empty ;		
			data "Avg" 	value: resident mean_of 	each.PANT 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.PANT 	color: #blue marker_shape: marker_empty;	
			}
		}
		
	display "Beh - Intention" type:java2D{
		chart "Intention" type: series   x_serie_labels: cycle{
			data "Min" 	value: resident min_of 		each.intention 	color: #red marker_shape: marker_empty;		
			data "Avg" 	value: resident mean_of 	each.intention 	color: #green marker_shape: marker_empty;	
			data "Max" 	value: resident max_of 		each.intention 	color: #blue marker_shape: marker_empty;	
			}
		}	
		


		
		display "KPIs - instant track" type:java2D{
			chart "KPIs" type: series  x_serie_labels: cycle{
				data "kpi org t" 	value: KPI_org_t color: #green;				
				data "kpi mix t" 	value: KPI_mix_t color: #red;				
				data "kpi pak t" 	value: KPI_pak_t color: #blue;				
				data "kpi avg t" 	value: KPI_avg_t color: #black;				
				}
			}
		
		
		
		
		display city type:java2D {
			species bin aspect:base;			
			species prod_build aspect:base;
			species resi_build aspect:base;
			species resident aspect:base;
			species collector;		
			
		}		
		
	}	
	
}


// A model that runs fast, because it runs in silent mode. 
// Only at the end of the year, it will produce a print with main results


// This experiment runs the simulation in silent mode and at the end of a whole year, it exports a csv filw
// that contains the models main KPIS. 
// Two batch experiments are defined separtly, beacuse of inssufient memory to run both.

experiment 'run_100_sims_low_dens' type: batch repeat: 100 keep_seed: false until: (cycle = 1096 ) parallel:10 {
	
	method exploration with: [	
	["shape_file_bin"::file("../includes/Low_Dens/S1.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")],
	["shape_file_bin"::file("../includes/Low_Dens/S2.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")],	
	["shape_file_bin"::file("../includes/Low_Dens/S3.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")],	
	["shape_file_bin"::file("../includes/Low_Dens/S4.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")],	
	["shape_file_bin"::file("../includes/Low_Dens/S5.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")],	
	["shape_file_bin"::file("../includes/Low_Dens/S6.shp"), "shape_file_residential"::file("../includes/Low_Dens/VILLA.shp"), "shape_file_productive"::file("../includes/Low_Dens/prod_villa.shp")]


	
		
	];
	
    reflex sim {
    	//seed <- rnd(0.0,1000.0);
    	int simul_n <- 0;
    	ask simulations
		{
        	save [simul_n, self.shape_file_residential, self.shape_file_bin, 
        		self.global_kpi_org, self.global_kpi_mix, self.global_kpi_pak, self.global_kpi_avg, self.seed, 
        		self.global_kpi_beh, self.global_kpi_beh_max, self.global_kpi_beh_min, 
        		self.global_kpi_count_beh_1, self.global_kpi_count_beh_2, self.global_kpi_count_beh_3, self.global_kpi_count_beh_4
        	] 
        							to: "../results/KPIs_l_dens.csv" format: "csv" rewrite: false;        				
        simul_n <- simul_n+1;
        }
        
        
	}
}


experiment 'run_100_sims_high_dens' type: batch repeat: 100 keep_seed: false until: (cycle = 1096 ) parallel:10 {
	
	method exploration with: [	
	["shape_file_bin"::file("../includes/High_Dens/S1.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")],
	["shape_file_bin"::file("../includes/High_Dens/S2.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")],	
	["shape_file_bin"::file("../includes/High_Dens/S3.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")],	
	["shape_file_bin"::file("../includes/High_Dens/S4.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")],	
	["shape_file_bin"::file("../includes/High_Dens/S5.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")],	
	["shape_file_bin"::file("../includes/High_Dens/S6.shp"), "shape_file_residential"::file("../includes/High_Dens/High_dens.shp"), "shape_file_productive"::file("../includes/High_Dens/High_prod.shp")]
	

	
		
	];
	
    reflex sim {
    	//seed <- rnd(0.0,1000.0);
    	int simul_n <- 0;
    	ask simulations
		{
        	save [simul_n, self.shape_file_residential, self.shape_file_bin, 
        		self.global_kpi_org, self.global_kpi_mix, self.global_kpi_pak, self.global_kpi_avg, self.seed, 
        		self.global_kpi_beh, self.global_kpi_beh_max, self.global_kpi_beh_min, 
        		self.global_kpi_count_beh_1, self.global_kpi_count_beh_2, self.global_kpi_count_beh_3, self.global_kpi_count_beh_4
        	] 
        							to: "../results/KPIs_h_dens.csv" format: "csv" rewrite: false;        				
        simul_n <- simul_n+1;
        }
        
        
	}
}
    

    
    
    