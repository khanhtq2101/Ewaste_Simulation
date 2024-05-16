/**
* Name: waste sorting
* Author: Jonathan Cohen
* Description: Simulation to model the Theory of Planned Behavior in relation of waste sorting.
* Tags: TPB, Waste, Urban
*/


model waste_sorting

global {
	//if the number of types of waste change, need to change the other variable about the hyperparam also (average number of devices)
	//Lets try :) 
	int n_ebin <- 5;
	int n_ewaste <- 5;
	
	int n_waste_type <- n_ewaste;
	//int n_ebin <- 3; //can not be more than 3 because of the dataset

	//[[smartphone, laptop], [battery], [bulb]]
	list<int> sub_cat <- [2, 1, 1, 1, 1];
	
	//Right data for final running 
	//Might get other data for testing if needed
	list<list<float>> avg_n_devices <- list([[1.67, 0.1], 
											[10], 
											[23],
											[10],
											[10]]);
	list<list<float>> avg_n_new_devices <- list([[1.67/(3*104), 0.1/(3*104)], 
											[10/104], 
											[23/104],
											[23/104],
											[10/104]]);	
	
	//fiexed size of e-device
	matrix<list<int>> size <- [list<int>([])] as_matrix({n_ewaste, 1});
	
//	matrix<bool> accepted_waste <- matrix([[true, false, true], 
//											[true, true, false], 
//											[false, true, true]]);
// index: (bin type, waste type)
	list<matrix<bool>> accepted_waste <- list([matrix([true, true, true, true, true]), 
											matrix([false, true, true, false, false]), 
											matrix([true, true, false, false, false]),
											matrix([false, true, false, false, true]),
											matrix([false, false, false, true, false])]);
	
	//Lifespan of device
	matrix<list<int>> mean_device_lifespan <- [list<int>([])] as_matrix({n_ewaste, 1});		
	matrix<list<int>> std_device_lifespan <- [list<int>([])] as_matrix({n_ewaste, 1});
	
	matrix<list<int>> mean_device_size <- [list<int>([])] as_matrix({n_ewaste, 1});
	matrix<list<int>> std_device_size <- [list<int>([])] as_matrix({n_ewaste, 1});	
	
	// GLOBAL E-WASTE KPI FOR TRACKING
	// Time
    int global_time_at_home;
   	matrix<int> global_ewaste_time_at_home <- 0 as_matrix({n_ebin, n_ewaste});
   	
   	//Amount of waste
   	int global_ewaste_total <- 0;
   	matrix<int> global_ewaste_size_total <- 0 as_matrix({n_ebin, n_ewaste});
   	matrix<int> global_ewaste_n_total <- 0 as_matrix({n_ebin, n_ewaste});
   	
   	//In general bin
   	int global_time_at_home_genbin;
   	matrix<int> global_ewaste_time_at_home_genbin <- 0 as_matrix({n_ebin, n_ewaste});
   	int global_ewaste_total_genbin <- 0;
   	matrix<int> global_ewaste_size_total_genbin <- 0 as_matrix({n_ewaste, 1});
   	matrix<int> global_ewaste_n_total_genbin <- 0 as_matrix({n_ewaste, 1});
   	
	
	// SET A STARTING SEED, in case of getting the same simulation
	//float seed <- rnd(0.0,1000.0);				
	
	///////////////////////////////////////////////
	//    URBAN SITUATIONS: PLACE HOLD FOR SHAPEFILES
	////////////////////////////////////////7
	
	//full units and population
	file shape_file_residential 	<- file("../../includes/HDBExistingBuilding_scaled_down_6/HDBExistingBuilding_scaled_down_6.shp");
	
	//full units with 2 residents per unit
	//file shape_file_residential 	<- file("../../includes/HDBExistingBuilding_demo/HDBExistingBuilding_demo.shp");
	
	//100 units with 2 residents per unit	
	//file shape_file_residential 	<- file("../../includes/HDBExistingBuilding_demo_100unit_2res/HDBExistingBuilding_demo.shp");
	file shape_file_productive 		<- file("../../includes/Low_Dens/office_demo.shp");	
	//file shape_file_bin 			<- file("E:/Social-Industrial Symbiosis - SIMTech/progress/week 9/getting data/E-wasteCollectionPoints_demo/E-wasteCollectionPoints_demo.shp");	
	file shape_file_bin				<- file("../../includes/E-wasteCollectionPoints_etype/E-wasteCollectionPoints_etype.shp");
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
    
    matrix<int> start_info_bin <- 50 as_matrix({n_waste_type, 1});
    
//  int start_info_bin[0] 	<- 50;					// Define how much information is in the org bin
//	int start_info_bin[1]	<- 50;					// Define how much information is in the residual bin
//	int start_info_bin[2]	<- 50;					// Define how much information is in the residual bin
	
	
		
		
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
	
	// mean and standard deviation of the waste
	matrix<int> mean_waste_day <- 0 as_matrix({n_waste_type, 1});
	//Initialization in init{}
		
//	int org_day		<- 115;		// 115 grms per day
//	int mix_day 	<- 430;		// 430 grms per day
//	int pak_day 	<- 178;		// 178 grms per day	
	
	matrix<int> waste_day_std <- 0 as_matrix({n_waste_type, 1});
	//Initialization in init{}	
	
//	int org_day_sd	<- 20; 		// 115 grms per day
//	int mix_day_sd 	<- 70; 		// 430 grms per day
//	int pak_day_sd 	<- 30; 		// 178 grms per day		

	matrix<int> global_bin_info <- 0 as_matrix({n_waste_type, 1});
	
	////// Miss sorting waste
	////////////////////////////////////
	float thold_wrong_pak <- 0.3;
	float thold_wrong_org <- 0.5;
	
	
	
	///////////////////////////////////
	////// Process of creating agents
	///////////////////////////////////
	init {
		
		//E-device type: [[Smartphone, Laptop], [Battery], [Lamp/Buld]]
		//hyper-parameters
		mean_device_lifespan[0] << 30;
		mean_device_lifespan[0] << 50;
		mean_device_lifespan[1] << 10;
		mean_device_lifespan[2] << 10;
		mean_device_lifespan[3] << 10;
		mean_device_lifespan[4] << 10;
		
		std_device_lifespan[0] << 5;
		std_device_lifespan[0] << 10;
		std_device_lifespan[1] << 2;
		std_device_lifespan[2] << 2;
		std_device_lifespan[3] << 2;
		std_device_lifespan[4] << 2;
		
		mean_device_size[0] << 1084;
		mean_device_size[0] << 75;
		mean_device_size[1] << 1;
		mean_device_size[2] << 94;
		mean_device_size[3] << 94;
		mean_device_size[4] << 94;
		
		std_device_size[0] << 0;
		std_device_size[0] << 0;
		std_device_size[1] << 0;
		std_device_size[2] << 0;
		std_device_size[3] << 0;
		std_device_size[4] << 0;
		
		//Deterministic size
		size[0] <- list<int>([15, 300]);
		size[1] <- list<int>([1]);
		size[2] <- list<int>([20]);
		
		//Waste generation mean and std initialization
		//Waste type: org, mix, pak
		mean_waste_day[0]	<- 115;		// 115 grms per day
		mean_waste_day[1] 	<- 430;		// 430 grms per day
		mean_waste_day[2] 	<- 178;		// 178 grms per day
		mean_waste_day[3] 	<- 3780;		// 178 grms per day
		
		waste_day_std[0]	<- 20; 		// 115 grms per day
		waste_day_std[1] 	<- 70; 		// 430 grms per day
		waste_day_std[2] 	<- 30; 		// 178 grms per day
		waste_day_std[3] 	<- 30; 		// 178 grms per day
		
		
		loop i from: 0 to: n_waste_type - 1{
			global_bin_info[i] <- start_info_bin[i];
		}
		
		create scheduler;		
		create collector;		
		create prod_build 	from: shape_file_productive returns:  productive_list {}
		
		// Bins are created from shapefile
		create bin 			from: shape_file_bin returns:  bin_list with: [
			id:int(read ("id")), 
			type:string(read("TYP")),
			e_type: int(read("e_type"))
			] {
				if (type="MIX") { color <- #red;} 
				else if (type="ORG"){ color<- #green; }
				else {color <-#violet;}
				
				//ASSIGN THE BINS TYPE BY ORDER:
				type_bool[e_type] <- true;
				type_id <- e_type;
				
				info_bin <- global_bin_info[0]; // min:0 max:100;
			}
				
			
		// The creation of residential buildings triggers the creation of people and their households.
		// Important to notice that this comes from data written in the shapefile!
		write "Number of bin: " + length(bin_list);
		
		create resi_build 	from: shape_file_residential returns:  residence_list with: [			
			tot_pop:int(read('tot_pop')) div 60,
			hholds:int(read('h_units'))] {
				
				if self.tot_pop > 0 {				
					//create resident number: 1 returns: resident_list {				
					create resident number: self.tot_pop returns: resident_list {
						write "Creating resident " + self.name;	
						//INITIATE LIST OF E-DEVICES FOR EACH RESIDENT
						int n_devices;
						loop i from:0 to: n_ewaste - 1{
							loop j from:0 to: sub_cat[i] - 1{
								n_devices <- poisson(avg_n_devices[i][j]);
								
								e_device[i] <- e_device[i] + list_with(n_devices, int(j));
							
							}
						}
		
						//define lifespan and size randomly		
						loop i from:0 to: n_ewaste - 1{
							if length(e_device[i]) > 0 {
								loop j from:0 to: length(e_device[i]) - 1 {
									device_endcycle[i] << int(gauss(mean_device_lifespan[i][e_device[i][j]], 
																	std_device_lifespan[i][e_device[i][j]]));		
									device_size[i] << int(gauss(mean_device_size[i][e_device[i][j]], 
																	std_device_size[i][e_device[i][j]]));
								}
							}
						}
		
						home_place 	<- myself;
						work_place 	<- one_of(productive_list);
						my_work 	<-any_location_in(work_place);
						
						work_place.q_people <- work_place.q_people+ 1;
						
						location <- any_location_in(home_place);
						my_place <- location;
						
						//Note: Idea to do here!!!
						//Might use loop to assign nearest bin!!!
						
						matrix<float> dist_bin <- 0.0 as_matrix({n_ebin, 1});
						near_bin <- nil as_matrix({n_ebin, 1});
						
						//Assign shortest bin for each type of bin
						loop i from: 0 to: n_ebin - 1 {
							near_bin[i] <- bin where (each.type_id = i)	closest_to self;
							dist_bin[i] <- self distance_to near_bin[i]		with_precision(1);
						}
										
						// Percentage of people doing home office
						home_office	<- flip(home_office_proba) ? true:false;
						
						// Percentage of people that start out of their homes
						// This is fixed but can be dynamically assigned in the model
						head_work	<- flip(early_start_proba) ? true:false;
						
											
						// Load initial values of waste
						loop i from: 0 to: n_waste_type - 1{
							budget_waste[i] <- int(gauss(mean_waste_day[i], waste_day_std[i]));
						}
						//behaviour <- gauss(80,10);					
						//Original: mean_dist <- (0.5*dist_bin_org +0.1*dist_bin_mix  + 0.3* dist_bin_pak) with_precision(2);	
						
						mean_dist <- mean(dist_bin);
						//mean_dist <- (0.5*dist_bin[0] +0.1*dist_bin[1]  + 0.3* dist_bin[2]) with_precision(2);
						
						mean_dist <- scale_dist*mean_dist;									
						}					
						
				
					// The agent building create households based on the varible hholds in the shapefile
					create house_hold number: self.hholds returns: hhold_list {
											
						//Initialization of max waste
						bin_max[1] <- rnd(1.0,1.5);// In Kg
						bin_max[0] <- rnd(1.0,1.5);// In Kg
						bin_max[2] <- rnd(1.0,2.0); // In Kg
					
						hh_bin_full[1] <- bin_cc[1] = 0 ? false : true;
						hh_bin_full[0] <- bin_cc[1] = 0 ? false : true;
						hh_bin_full[2] <- bin_cc[1] = 0 ? false : true;
						
						int tot_hholds <- myself.hholds;					
						// I need to find a better solution for this last line
						max_people <- int((myself.tot_pop /myself.hholds)) + rnd(0,1); // + rnd(0,1);	
						address <- myself;
						
						address.list_of_homes <+ self;
						// Defines the perception of space at home
						
						//how much space one household has
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
			}
		} // closing of residential building creation
		
		// Make some random friends - and set my socials
		write "Ending creating residents";
		ask resident {
			write self.name;
			// This is the list of how many friends they have
			int rand_friends <- rnd(1,10);	
			space		<-	h_unit.space_bin;	
			int n_friends <- 0;
			
			loop while: (rand_friends >= n_friends) {
				friend_list <+ one_of((resident - self) where (each.h_unit != self.h_unit));
				n_friends <- n_friends + 1;								
				}
				
			friend_list <- remove_duplicates (friend_list);
			
			// Define a list of residents sharing bins
			my_org_comm <- (resident - self)  where (each.near_bin[0] = self.near_bin[0]);
			my_mix_comm <- (resident - self)  where (each.near_bin[1] = self.near_bin[1]);
			my_pak_comm <- (resident - self)  where (each.near_bin[2] = self.near_bin[2]);			
			
			roomies_list 	<- (resident - self)  where (each.h_unit = self.h_unit);		
			colleg_list 	<- (resident - self)  where (each.work_place = self.work_place);
		}
		write "Ending ask resident";
		// Define waste types and create them
		ask bin {
			loop i from: 0 to: n_ebin - 1{
				if (type_id = i) {				
					pop <- length(resident  where (each.near_bin[i] = self));			
				}
			}		
		}
		write "Ending Initilization";
	} // Close initialize
	
	
	// This following set of variables are inteded to be used during the simulation
	// These variables change the amont information in the bins
	
	action increase_info {
		ask bin {
			info_bin <- info_bin + 5;
		}
	}
	action decrease_info {
		ask bin {
			info_bin <- info_bin - 5;
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
	        
	       	write "Res-org (Kg): " 		+ (from_res_waste[0]) 	with_precision(2);
	        write "Res-mix (Kg): " 		+ (from_res_waste[1]) 	with_precision(2);        
	        write "Res-pak (Kg): " 		+ (from_res_waste[2]) 	with_precision(2);	           
	        write "Res-total (Kg): " 	+ (from_res_total) 	with_precision(2);
	        
	        
	        write "Total organic (Kg): " 	+ (from_res_waste[0] + from_prod_org) with_precision(2);
	        write "Total residual (Kg): " 	+ (from_prod_mix + from_res_waste[1]) with_precision(2);        
	        write "Total recyclable (Kg): " 	+ (from_prod_pak+ from_res_waste[2])  with_precision(2);
	        
	        
	       	write "Total waste (Ton): " 	+ ((from_prod_total + from_res_total)/1000) 					with_precision(2);
	        write "Percentage of residential (%): " +  ((from_res_total / (from_res_total + from_prod_total))*100) 	with_precision(2);
	        

	        write "Total waste (Kg/pc): "  		+ ((from_prod_total + from_res_total)/length(resident) )	with_precision(2);
	        write "Total organic (Kg/pc):" 		+ ((from_res_waste[0] + from_prod_org)/length(resident)) 			with_precision(2);
	        write "Total residual (Kg/pc): "	+ ((from_prod_mix + from_res_waste[1])/length(resident)) 			with_precision(2);       
	        write "Total recyclable (Kg/pc): " 	+ ((from_prod_pak+ from_res_waste[2])/length(resident)) 				with_precision(2);
        
        
        	// kPIS
        	write "Org in org: " +  (res_waste_in_bin[0, 0]/(res_waste_in_bin[0, 0] + res_waste_in_bin[0, 1] + res_waste_in_bin[0, 2]))*100;
        	write "Mix in mix: " +  (res_waste_in_bin[1, 1]/(res_waste_in_bin[1, 1] + res_waste_in_bin[1, 2] + res_waste_in_bin[1, 0]))*100;
        	write "Pak in pak: " +  (res_waste_in_bin[2, 2]/(res_waste_in_bin[2, 2] + res_waste_in_bin[2, 1] + res_waste_in_bin[2, 0]))*100;
        	
        	write "Average: " +    (((res_waste_in_bin[0, 0]/(res_waste_in_bin[0, 0] + res_waste_in_bin[0, 1] + res_waste_in_bin[0, 2])) +  
        							(res_waste_in_bin[1, 1]/(res_waste_in_bin[1, 1] + res_waste_in_bin[1, 2] + res_waste_in_bin[1, 0])) +
        							(res_waste_in_bin[2, 2]/(res_waste_in_bin[2, 2] + res_waste_in_bin[2, 1] + res_waste_in_bin[2, 0])))/3)*100;
        							
        							
        	// The variables below are used to calculate KPIs
        	// KPI ORG -> Calculates the percentage of properly sorted organics						
        	global_kpi_org <- (res_waste_in_bin[0, 0]/(res_waste_in_bin[0, 0] + res_waste_in_bin[0, 1] + res_waste_in_bin[0, 2]))*100 with_precision(2);
        	
        	// KPI MIX -> Calculates the percentage of properly sorted residuals
        	global_kpi_mix <- (res_waste_in_bin[1, 1]/(res_waste_in_bin[1, 1] + res_waste_in_bin[1, 2] + res_waste_in_bin[1, 0]))*100 with_precision(2);
        	
        	// KPI PAK -> Calculates the percentage of properly sorted recyclables
        	global_kpi_pak <- (res_waste_in_bin[2, 2]/(res_waste_in_bin[2, 2] + res_waste_in_bin[2, 1] + res_waste_in_bin[2, 0]))*100 with_precision(2);
        	
        	// KPI ORG -> Calculates the Average of the KPIs
        	global_kpi_avg <-  (((res_waste_in_bin[0, 0]/(res_waste_in_bin[0, 0] + res_waste_in_bin[0, 1] + res_waste_in_bin[0, 2])) +  
        							(res_waste_in_bin[1, 1]/(res_waste_in_bin[1, 1] + res_waste_in_bin[1, 2] + res_waste_in_bin[1, 0])) +
        							(res_waste_in_bin[2, 2]/(res_waste_in_bin[2, 2] + res_waste_in_bin[2, 1] + res_waste_in_bin[2, 0])))/3)*100 with_precision(2);
	
			
			// After the year, and the values of the variables are transfered, 
			// The bins are returned to 0
    		from_res_total 			<-0.0;
			from_res_waste[0] 			<-0.0;
			from_res_waste[1] 			<-0.0;
			from_res_waste[2] 			<-0.0;
			res_waste_in_bin[0, 0] 			<-0.0;
			res_waste_in_bin[1, 0] 			<-0.0;
			res_waste_in_bin[2, 0] 			<-0.0;
			res_waste_in_bin[0, 1] 			<-0.0;
			res_waste_in_bin[1, 1] 			<-0.0;
			res_waste_in_bin[2, 1] 			<-0.0;
			res_waste_in_bin[0, 2] 			<-0.0;
			res_waste_in_bin[1, 2] 			<-0.0;
			res_waste_in_bin[2, 2] 			<-0.0;			
			KPI_waste[0] 				<-0.0;
			KPI_waste[1] 				<-0.0;
			KPI_waste[2] 				<-0.0;
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
		try{KPI_org_t <-(((bin where (each.type='ORG') sum_of(each.waste[0]))
								/(bin where (each.type='ORG') sum_of(each.current_cap)))*100) with_precision(2);}
								
		try{KPI_mix_t <-(((bin where (each.type='MIX') sum_of(each.waste[1]))
								/(bin where (each.type='MIX') sum_of(each.current_cap)))*100) with_precision(2);}
								
		try{KPI_pak_t <-(((bin where (each.type='PAK') sum_of(each.waste[2]))
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
	
	matrix<float> bin_cc <- 0.0 as_matrix({n_waste_type, 1});
	
//	float waste_cc[1];
//	float waste_cc[0];
//	float waste_cc[2];
	
	//matrix to track waste, order: org, mix, pak
	//row: waste type, column: bin
	matrix waste_in_bin <- 0.0 as_matrix({3, 3});
	
	//float org_in_mix
	//float waste_in_bin[0, 1];	
//	float waste_in_bin[1, 1];	
//	float waste_in_bin[2, 1];
//	
//	float waste_in_bin[0, 0];	
//	float waste_in_bin[1, 0];	
//	float waste_in_bin[2, 0];
//	
//	float waste_in_bin[0, 2];	
//	float waste_in_bin[1, 2];	
//	float waste_in_bin[2, 2];
	
	
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
	
	//E-waste variable to track
	matrix<list<int>> ewaste <- [list<int>([])] as_matrix({n_ewaste, 1});
	matrix<list<int>> device_size <- [list<int>([])] as_matrix({n_ewaste, 1});
	matrix<list<int>> begined_at_home <- [list<int>([])] as_matrix({n_ewaste, 1});
	matrix<list<int>> time_at_home <- [list<int>([])] as_matrix({n_ewaste, 1});
	int size_total <- 0;
	
	matrix<bool> accepted_options <- [false] as_matrix({n_ebin, n_ebin});
	//tracking the shortest distance to the bins
	matrix<float> distance_to_bins <- #infinity as_matrix({n_ebin, n_ebin});	
	float shortest_dist <- #infinity;
	matrix<int> shortest_bins <- [-1] as_matrix({2, 1});	
	
	
	matrix<bool> waste_portfolio <- [false] as_matrix({n_ewaste, 1});
	bool new_waste <- false;
	
	
	//matrix to track waste, order: org, mix, pak
	//row: waste type, column: bin
	matrix<float> waste_in_bin <- 0.0 as_matrix({n_waste_type, n_ebin}); 
	matrix<float> bin_max <- 0.0 as_matrix({n_ebin, 1});
	matrix<float> bin_cc <- 0.0 as_matrix({n_ebin, 1});
	matrix<int> bin_tick <- 0 as_matrix({n_ebin, 1});
	
	matrix<bool> hh_bin_full <- false as_matrix({n_ebin, 1});
	
	int space_bin min:0 max: 100;
	int waste_time_at_home <- 0;
	
	//LOOP REPLACEMENT, FOR GENERALIZATION
	// The following reflexes that degreade waste
	reflex decompose {
		loop i from:0 to: n_ebin - 1 {
			if (bin_tick[i] != 0) {
				bin_tick[i] <- bin_tick[i] + 1;
			}
		}
		//write "In household bin: " + waste_in_bin[3, 0] + waste_in_bin[3, 1] + waste_in_bin[3, 2];
	}
	
//	reflex org_decompose when: (waste_tick[0] !=0) {
//		waste_tick[0] <- waste_tick[0] + 1;		
//	}
//	
//	reflex mix_decompose when: (waste_tick[1] !=0) {
//		waste_tick[1] <- waste_tick[1] + 1;		
//	}
//	
//	reflex pak_decompose when: (waste_tick[2] !=0) {
//		waste_tick[2] <- waste_tick[2] + 1;		
//	}

	reflex adding_time {
		//adding multiple times by residents of the household
		//need to check again
		//maybe change to do by the household
		loop i from: 0 to: length(time_at_home) - 1{
			if length(time_at_home[i]) > 0 {
				loop j from: 0 to: length(time_at_home[i]) - 1{
					//adding one for all the time_at_home element, for tracking the time at home
					time_at_home[i][j] <- time_at_home[i][j] + 1;
					waste_time_at_home <- waste_time_at_home + 1;
				}
			}
		}
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
	int e_type;
	float current_cap;
	int used;
	
	//type in boolean encoding, still the household solid waste
	matrix<bool> type_bool <- false as_matrix({n_ebin, 1});
	
	int type_id;
	matrix<float> waste <- 0.0 as_matrix({n_waste_type, 1});
	//initialize by solid waste type, need to change later
	matrix<bool> ebin_type <- type_bool; //false as_matrix({n_ebin, 1});
	
	matrix<int> ewaste_size_total <- 0 as_matrix({n_ewaste, 1});
	matrix<int> ewaste_n_total <- 0 as_matrix({n_ewaste, 1});
	matrix<int> ewaste_time_at_home <- 0 as_matrix({n_ewaste, 1});
	
	int ewaste_total <- 0;
	int total_time_at_home <- 0;
	int correct_amount <- 0;
	int incorrect_amount <- 0;
	
	

	//Setting boundary at the creation might work // Dont work
	//matrix<int> info_bin <- 0 as_matrix({n_waste_type, 1});
	int info_bin <- 0;
	
	int pop;
		
	aspect base {
		// In case of using a shapefile
		draw square(4) color: color ;
		
	}
	reflex get_correct_amount {
		//get the type_id of the bin (type in int number)
		//get the accepted type of waste from the matrix accepted_waste (global)
		//sum the one with true (matrix multiplication)
//		write "------------";
//		write "Total amount matrix: " + ewaste_size_total;
//		write "Accepted matrix" + matrix<int>(accepted_waste[type_id]);
//		write "E waste total size list in bin:" + ewaste_size_total*matrix<int>(accepted_waste[type_id]);	
//		correct_amount <- sum(ewaste_size_total*matrix<int>(accepted_waste[type_id]));
		incorrect_amount <- sum(ewaste_size_total) - correct_amount;
		
//		write "Correct amount: " + correct_amount;
//		write "Incorrect amount: " + incorrect_amount;
		
	}
}


species collector schedules: [] {  //
	float from_prod_org;
	float from_prod_mix;
	float from_prod_pak;
	
	float from_prod_total;

	
	reflex restart when: (cycle>1) and every(3# cycle){
		// In kgrams
		from_prod_org <- from_prod_org + (prod_build sum_of(each.bin_cc[0])) with_precision(2);
		from_prod_mix <- from_prod_mix + (prod_build sum_of(each.bin_cc[1])) with_precision(2);
		from_prod_pak <- from_prod_pak + (prod_build sum_of(each.bin_cc[2])) with_precision(2);
		
		// In grams
		from_prod_total <- (from_prod_pak + from_prod_org + from_prod_mix);
		ask prod_build {
			loop i from: 0 to: n_waste_type - 1{
				bin_cc[i] <- 0;
			}
		}
			
	}
	
	float from_res_total;
	
	matrix<float> from_res_waste <- 0.0 as_matrix({n_waste_type, 1});
	
	//matrix to track the type of waste in bins (on street bin)
	matrix res_waste_in_bin <- 0.0 as_matrix({n_waste_type, n_ebin});
	
	matrix<float> KPI_waste <- 0.0 as_matrix({n_waste_type, 1});

	
	float KPI_avg;

	// Global e-waste KPI
	// Time
//    int global_time_at_home;
//   	matrix<int> global_ewaste_time_at_home <- 0 as_matrix({n_ebin, n_ewaste});
//   	
//   	//Amount of waste
//   	int global_ewaste_total <- 0;
//   	matrix<int> global_ewaste_size_total <- 0 as_matrix({n_ebin, n_ewaste});
//   	matrix<int> global_ewaste_n_total <- 0 as_matrix({n_ebin, n_ewaste});
   
	
	reflex e_clean_frequent when: ((cycle>1) and every(collect_freq# cycle)){
		//Adding to the global KPI, to track the environmental indicator
		//DOUBLE CHECK AGAIN LATER: 1st time: okay
		global_time_at_home <- global_time_at_home;
		
		loop i from: 0 to: n_ebin - 1 {
			loop j from: 0 to: n_ewaste - 1{
				//Time at home KPI
				global_time_at_home <- global_time_at_home + 
										(bin where (each.type_id = i) sum_of(each.ewaste_time_at_home[j]));
				global_ewaste_time_at_home[i, j] <- global_ewaste_time_at_home[i, j]
													+ (bin where (each.type_id = i) sum_of(each.ewaste_time_at_home[j]));
													
				//Amount at home KPI
				global_ewaste_total <- global_ewaste_total + 
										(bin where (each.type_id = i) sum_of(each.ewaste_size_total[j]));
				global_ewaste_size_total[i, j] <- global_ewaste_size_total[i, j] +
											(bin where (each.type_id = i) sum_of(each.ewaste_size_total[j]));
				global_ewaste_n_total[i, j] <- global_ewaste_n_total[i, j] +
											(bin where (each.type_id = i) sum_of(each.ewaste_n_total[j]));										
			}
		}
		
		//reset the state of bin to initial 
		ask bin {	
			ewaste_size_total <- 0 as_matrix({n_ebin, n_ewaste});
			ewaste_n_total <- 0 as_matrix({n_ebin, n_ewaste});
			ewaste_time_at_home <- 0 as_matrix({n_ebin, n_ewaste});
			
			ewaste_total <- 0;
			total_time_at_home <- 0;
			correct_amount <- 0;
			incorrect_amount <- 0;
		}
	}
	
	reflex clean_frequent when: ((cycle>1) and every(collect_freq# cycle) and clean_on) or 
								every(1094 #cycle) {
											
		//Might rewrite the collection function!
		loop i from: 0 to: n_ewaste - 1 {
			//might be wrong with the type of the bin, because index is number of waste
			//why to sum up all the bin with type i? what i am tracking? total waste in all the bin? 
			//need to define what need to be tracked, and then define the function to track.
			//REFINE LATER
			
			from_res_waste[i] <- from_res_waste[i] + (bin where (each.type_bool[i] = true) sum_of(each.current_cap)) with_precision(2);
			
			//res_waste_in_bin index order (waste type, bin type)
			loop j from: 0 to: n_waste_type - 1{
				res_waste_in_bin[j, i] <- res_waste_in_bin[j, i] + (bin where (each.type_bool[i] = true) sum_of(each.waste[j])) with_precision(2);
			}
		}	
		
//		// In grams
//		from_res_total <- sum(from_res_waste); //from_res_waste[0] + from_res_waste[1] + from_res_waste[2];
//
//		loop i from:0 to: n_waste_type - 1{
//			try{KPI_waste[i] <- ((res_waste_in_bin[i, i]/from_res_waste[i])*100) with_precision(2);}
//		}
//		
//		try{KPI_avg <- sum(KPI_waste)/n_waste_type with_precision(2);}
		
		ask bin {
			used 		<- 	0;
			loop i from:0 to:length(waste) - 1{
				waste[i] <- 0.0;
			}
			current_cap <-	0.0;				
		}
				
	}
		
	//For manual cleaning during runtime
	action empty_n_clean {		
		loop i from: 0 to: n_ebin - 1 {
			from_res_waste[i] <- from_res_waste[i] + (bin where (each.type_bool[i] = true) sum_of(each.current_cap)) with_precision(2);
			
			loop j from:0 to: n_waste_type - 1 {
				res_waste_in_bin[j, i] <- from_res_waste[j, i] + (bin where (each.type_bool[i] = true) sum_of(each.waste[j])) with_precision(2);			
			}
			//res_waste_in_bin index order (waste type, bin type)
			res_waste_in_bin[0, i] <- from_res_waste[0, i] + (bin where (each.type_bool[i] = true) sum_of(each.waste[0])) with_precision(2);
			res_waste_in_bin[1, i] <- from_res_waste[1, i] + (bin where (each.type_bool[i] = true) sum_of(each.waste[1])) with_precision(2);
			res_waste_in_bin[2, i] <- from_res_waste[2, i] + (bin where (each.type_bool[i] = true) sum_of(each.waste[2])) with_precision(2);
		}
		
		from_res_total <- sum(from_res_waste);
			
		ask bin {
			used 		<- 	0;
			loop i from:0 to:length(waste) - 1{
				waste[i] <- 0.0;
			}
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
	
	
	matrix<bin> near_bin;	
	
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
	int q_consume;
		
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
	
	//might ignore the case of work from home
	
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
	
	
	/////////////////////////////////////
	//// E-WASTE PROTOTYPE IMPLEMENTATION
	/////////////////////////////////////
	
	//device orders: [ict, lamp, battery]
	//ict: [smartphone, laptop]
	//lamp: [lamp]
	//battery: [battery]
	matrix<list<int>> e_device <- [list<int>([])] as_matrix({n_ewaste, 1});		
	matrix<list<int>> device_endcycle <- [list<int>([])] as_matrix({n_ewaste, 1});
	matrix<list<int>> device_size <- [list<int>([])] as_matrix({n_ewaste, 1});
	
	
	//probability to transfer ewaste to bin each cycle
	int init_throw_prob <- 70;
	int throw_prob <- init_throw_prob;
		
	float transfer_prob <- 0.0;
	float transfer_score <- 0.0;
	
	float e_behaviour <- gauss(50,5) min:0.0 max:100.0;
	float e_soc_norm <- gauss(50,5) with_precision(2) 	min:0.0		max:100.0;	
	
	reflex get_new_edevice {
		int n_devices;
		//generating list of device
		loop i from:0 to: n_ewaste - 1{
			loop j from:0 to: sub_cat[i] - 1{
				n_devices <- poisson(avg_n_new_devices[i][j]);
				
				if n_devices > 0{
					write "Number of new devices: " + n_devices; 
				}
				
				e_device[i] <- e_device[i] + list_with(n_devices, int(j));
				
//				if self.name = 'resident1'{
//					write "Number of device: " + n_devices;
//					write "List of devices: " + e_device;
//				}
			}
		}
		
		//DOUBLE CHECKING THE INITIALIZATION OF SIZE AND ATTRIBUTE!
		//define lifespan and size randomly			
		loop i from:0 to: n_ewaste - 1{
			if length(e_device[i]) > 0 {
				loop j from:0 to: length(e_device[i]) - 1 {
					device_endcycle[i] << cycle + int(gauss(mean_device_lifespan[i][e_device[i][j]], 
													std_device_lifespan[i][e_device[i][j]]));
													
					//define device size by distribution
					device_size[i] << int(gauss(mean_device_size[i][e_device[i][j]], 
													std_device_size[i][e_device[i][j]]));
													
				}
			}
		}
	}
	
	action update_bin_options {
		bool accepted <- true;
		loop i from: 0 to: n_ebin - 1 {
			loop j from: i to: n_ebin - 1 {
				
				accepted <- true;
				//i, j are index of bins
						
				//if all element of waste portfolio is false i.e. no waste at home:
				//no need to go out -> set the all option to false, then the probability is zero
				if h_unit.waste_portfolio all_match (each = false){ 
					accepted <- false;
				} else {
					loop k from: 0 to: n_ewaste - 1 {
						if  h_unit.waste_portfolio[k]{
							accepted <- accepted and (accepted_waste[i][k] or accepted_waste[j][k]);
						}
					}	
				}
				h_unit.accepted_options[i, j] <- accepted;
			}
		}
	}
	
	action update_shortest_distance {
		float d;
		loop i from: 0 to: n_ebin - 1 {
			loop j from: i to: n_ebin - 1 {
				if h_unit.accepted_options[i, j]{
					if i = j {
						d <- self distance_to near_bin[i];
						h_unit.distance_to_bins[i, j] <- d with_precision(2);
					} else {
						d <- self distance_to near_bin[i] + self distance_to near_bin[j];
						h_unit.distance_to_bins[i, j] <- d with_precision(2);
					}
				} else {
					h_unit.distance_to_bins[i, j] <- #infinity;
				}
			}
		}
		h_unit.shortest_dist <- min(h_unit.distance_to_bins);
		loop i from: 0 to: n_ebin - 1 {
			loop j from: i to: n_ebin - 1 {
				if h_unit.distance_to_bins[i, j] = h_unit.shortest_dist {
					h_unit.shortest_bins[0] <- i;
					h_unit.shortest_bins[1] <- j;
				}
			}
		}
	}
	
	reflex transfer_device_home {
		//check if a device is ended, let it at home.
		//type i, subcategory ewaste[i][j]
		loop i from:0 to:n_ewaste - 1{
			//checking condition again, the same problem
			if length(e_device[i])> 0 {
			loop j from:0 to:length(e_device[i]) - 1{
					if cycle = device_endcycle[i][j]{
						
						h_unit.new_waste <- true;
											
						h_unit.ewaste[i] << e_device[i][j];
						h_unit.device_size[i] << device_size[i][j];
						h_unit.begined_at_home[i] << cycle;
						h_unit.time_at_home[i] << 0;
						h_unit.size_total <- h_unit.size_total + device_size[i][j];
						
						//update waste portfolio of household
						h_unit.waste_portfolio[i] <- true;					
						
						if self.name = 'resident1'{
							write "--------------";
							write "CYCLE: " + cycle;
							write "Device size in resident: \n" + device_size +
							"\n Device size in household: \n" + h_unit.device_size +
							'\n Life span: ' + device_endcycle +
							"\n Total size:" + h_unit.size_total;
							write "Beginned cycle in household: \n" + h_unit.begined_at_home + '\n';
						}
					}
				}
			}
		}
		
		//Quite okay with the distance calculation
		//NOTE:
		//	Optimize later, considering the variable accepted_options and distance_to_bin to species household
		//	Because they are the same for resident of the same household
		
		if h_unit.new_waste {
			do update_bin_options;
			do update_shortest_distance;
			do knowledge;
			h_unit.new_waste <- false;
		}
				
//		if name = 'resident1' {
//			write "-------------------";
//			write "Cycle " + cycle;
//			write "\nAccepted bin option: \n" + h_unit.accepted_options;
//			write "Distance to accepted bins: \n \t" + h_unit.distance_to_bins;
//			write "Shortest distance: " + h_unit.shortest_dist;
//			write "Waste portfolio: " + h_unit.waste_portfolio;
//			write "Time at home cycle" + cycle + "\n \t" + h_unit.time_at_home;
//			write "Total time at home: " + h_unit.waste_time_at_home;
//		}
	}

	action empty_household_bin(int waste_type) {
		//reset the waste at home, to make it empty		
		h_unit.size_total <- h_unit.size_total - sum(h_unit.device_size[waste_type]);
		
		h_unit.device_size[waste_type] <- [];
		h_unit.ewaste[waste_type] <- [];
		h_unit.begined_at_home[waste_type] <- [];
		
		h_unit.waste_time_at_home <- h_unit.waste_time_at_home - sum(h_unit.time_at_home[waste_type]);
		h_unit.time_at_home[waste_type] <- [];
		
		h_unit.waste_portfolio[waste_type] <- false;
	}

	//transfer waste type to bin type
	action transfer_waste_to_bin (int waste_type, int bin_type) {	
		//Total amount and amount of each type of waste on the bin
		near_bin[bin_type].ewaste_size_total[waste_type] <- near_bin[bin_type].ewaste_size_total[waste_type] + sum(h_unit.device_size[waste_type]);
		near_bin[bin_type].ewaste_n_total[waste_type] <- near_bin[bin_type].ewaste_n_total[waste_type] + length(h_unit.ewaste[waste_type]);
		near_bin[bin_type].ewaste_total <- near_bin[bin_type].ewaste_total + sum(h_unit.device_size[waste_type]);
		
		//Tracking time at home			
		near_bin[bin_type].ewaste_time_at_home[waste_type] <- near_bin[bin_type].ewaste_time_at_home[waste_type] + sum(h_unit.begined_at_home[waste_type]);
		near_bin[bin_type].total_time_at_home <- near_bin[bin_type].total_time_at_home + sum(h_unit.begined_at_home[waste_type]);
		
		do empty_household_bin(waste_type);
		
	}
	
	action transfer_waste_to_genbin (int waste_type) {	
		global_ewaste_size_total_genbin[waste_type] <- global_ewaste_size_total_genbin[waste_type] + sum(h_unit.device_size[waste_type]);
		global_ewaste_total_genbin <- global_ewaste_total_genbin + sum(h_unit.device_size[waste_type]);
		global_ewaste_n_total_genbin[waste_type] <- global_ewaste_n_total_genbin[waste_type] + length(h_unit.ewaste[waste_type]);
		
		//Tracking time at home			
		global_ewaste_time_at_home_genbin[waste_type] <- global_ewaste_time_at_home_genbin[waste_type] + sum(h_unit.begined_at_home[waste_type]);
		global_time_at_home_genbin <- global_time_at_home_genbin + sum(h_unit.begined_at_home[waste_type]);
			
		do empty_household_bin(waste_type);
	}
	
	//transfer ewaste from household to ebin
	reflex transfer_to_bin {
		if flip(transfer_prob) and (true in h_unit.waste_portfolio){
			if flip(e_behaviour) {
				//RIGHT AVENUE: TO THE ASSIGNED BIN
				loop i from: 0 to: n_ewaste - 1{
					if h_unit.waste_portfolio[i] {
							if accepted_waste[h_unit.shortest_bins[0]][i]{
								do transfer_waste_to_bin(i, h_unit.shortest_bins[0]);
							} else if accepted_waste[h_unit.shortest_bins[1]][i]{
								do transfer_waste_to_bin(i, h_unit.shortest_bins[1]);
							}
						}
					}
			} else {
				//WRONG AVENUE: GENERAL BIN
				loop i from: 0 to: n_ewaste - 1{
					if h_unit.waste_portfolio[i] {
						do transfer_waste_to_genbin(i);
					}
				}
			}
			
			//reset waste portfolio
			do update_bin_options;
			do update_shortest_distance;
		}
	}
	
	reflex calculate_transfer_socre {
		transfer_score <- h_unit.waste_time_at_home + h_unit.size_total - h_unit.shortest_dist/100;
		//TO BE DONE: analyze more carefully the range of the transfer score to decide the threshold
		
		transfer_prob <- transfer_score/1500;
	}
	
	action e_social_norm {
		// My waste related Community is an averaged value of the behavior of waste bins
		my_waste_community 	<- 	wgt_org_comm*int(my_org_comm mean_of(each.e_behaviour)) +
		 						wgt_mix_comm*int(my_mix_comm mean_of(each.e_behaviour)) +
								wgt_pak_comm*int(my_pak_comm mean_of(each.e_behaviour));		
			
		// ROOMIES
		// Takes averages of the residents that share the same house hold unit
		roomies_beh 		<- int(roomies_list mean_of(each.e_behaviour));	

		// CO-WORKERS
		// Average of residents that share the non residental space
		colleg_beh 			<- int(colleg_list mean_of(each.e_behaviour));		

		// FRIENDS
		// The friends behavior is an average of the friends list
		try   { friends_beh 	<- int(friend_list mean_of (each.e_behaviour));}
		catch { friends_beh 	<-50;}

		float e_soc_norm_old 	<- e_soc_norm;
		
		//Adding place holdeers
		e_soc_norm <- (gauss(10,0.5)	 +
			gauss(friend_b,friend_se) * friends_beh +
			gauss(colleg_b,colleg_se) * colleg_beh + 
			gauss(roomies_b,roomies_se) * roomies_beh +
			gauss(media_b,media_se) * media_beh +
			gauss(waste_b,waste_se) * my_waste_community) /sn_fine_tune;
	
	
					
		float e_soc_norm_diff <- e_soc_norm - e_soc_norm_old;
		
		e_soc_norm <- e_soc_norm_old + 0.5 * e_soc_norm_diff;		
	}

	action calculate_behavior_score {
		//all components are included
		//how to define the function?
		
		e_behaviour <- e_soc_norm + attitude + know + pbc - h_unit.shortest_dist/100;
		
//		if (true in h_unit.waste_portfolio){
//			write "Shortest distance to the assigned bin:" + h_unit.shortest_dist;
//			write "Actual Value: " + (e_soc_norm + attitude + know + pbc - h_unit.shortest_dist/100);
//			write "E Behavious soce of " + self.name + ": " + e_behaviour;
//		}
	}
	
	reflex behavior {
		do calculate_behavior_score;
	}
		
	/////////////////////////////////////
	//// GET WASTE
	/////////////////////////////////////
	
	//       NEED TO BE MODIFIED        //
	//will come back to you later
	//Change to use MATRIX
	//It might not necessary to set the boundary, might be good for runtime optimization
	matrix<float> set_consumption <- 0.0 as_matrix({n_waste_type, 1});
	
	//matrix<int> budget_waste <- matrix([0, 0, 0]);
	matrix<int> budget_waste <- 0 as_matrix({n_waste_type, 1});	
	
	//matrix<int> current_waste <- matrix([0, 0, 0]);
	matrix<int> current_waste <- 0 as_matrix({n_waste_type, 1});
	
	/// This is the main waste generation mechanims.
	// The proportions of waste generation vary along the day
	
	action get_waste {
		// The variable q_consume defines what proportion of waste is generated in each step
		// At the end of the action q_consume get a +1.
		if ( q_consume = 0 ) {
			//Assumption on the waste generation during the day
			loop i from: 0 to: n_waste_type - 1{
				set_consumption[i] 	<- rnd(0.00,  0.15) with_precision(2);
			}
		}
		
		if ( q_consume = 1 ) {
			loop i from: 0 to: n_waste_type - 1{
				set_consumption[i] 	<- rnd(0.00,  0.25) with_precision(2);	
			}
		}
		// As waste gets generated, transfered from the budget of waste,
		// to the current waste of different types
		
		loop i from: 0 to: n_waste_type - 1{
			current_waste[i] 		<- int(budget_waste[i] * set_consumption[i]);	
			budget_waste[i] 			<- budget_waste[i] - current_waste[i];		
		}
		q_consume <- q_consume + 1;	
				
		// Q waste is added one, so next time a different amount of waste gets assigned
	}
	
	// This action is triggered to 
	// consume the last part of waste not consumed during the preious steps
	action get_d_rest {
		loop i from:0 to:n_waste_type - 1{
			current_waste[i] <- budget_waste[i];
		}
		q_consume <- 0;	
		
		// After the consumption of all waste is dones, q_consume variable is set to 0
		// q_consume is the trigger that defines the percentage of waste to get during the day			
	}
	
	
	//This action is used to generate new waste,
	// This action is casted in the restart reflex which occurs very day
	action reset_waste_budget {
		loop i from: 0 to:n_waste_type - 1 {
			//CHANGE THE ORG_DAY TO MATRIX //DONE
			budget_waste[i] <- int(gauss(mean_waste_day[i], waste_day_std[i]));
		}
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
					 	gauss(dist_2_beh_b,dist_2_beh_se) * (mean_dist*dist_fine_tune)) / beh_fine_tune ;
					 	//gauss(pant_2_beh_b,pant_2_beh_se) * PANT)/beh_fine_tune ;					 	
			}	
			
	///////////////////////
	// Intention
	///////////////////////

	float intention min:0.0 max: 100.0;	
	
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
		do e_social_norm;
		if self.name = 'resident1'{
			write "E-social norm of cycle " + cycle + ":" + e_soc_norm;
			write "Tracking the time at home: \n" + global_ewaste_time_at_home;
			write "Tracking the total amount: \n" + global_ewaste_size_total;
		}
	}
	
	reflex evaluate_att when: (cycle>1) and every(3# cycle){		
		do attitude;		
	}
			
	reflex evaluate_pbc when: (cycle>1) and every(3# cycle){
		do pbc;
	}


	//Do not do the action knowledge every 3 cycle anymore
	//Update knowledge if a new bins are assigned	
//	reflex evaluate_know when: (cycle>1) and every(3# cycle){
//		do knowledge;
//	}
	

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
//// Change for the e-waste scenario
//////////////////////////////
	int avg_bin_info  min: 0 max: 100;
	float know <- gauss(60,2) min:0.0 max:100.0;	
	// This is an extension of the TPB that includes information related variables.
	// Information in bins is an item inside the constructs
	action knowledge {
		float know_old <- know;	
		avg_bin_info <- int((near_bin[h_unit.shortest_bins[0]].info_bin +
								near_bin[h_unit.shortest_bins[1]].info_bin) / 2);

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

	//Modifying for the e-waste scenario
	action pbc {
//		loop i from: 0 to: n_ebin - 1{
//			if near_bin[i].pop = 0 {
//				write "Bin type " + i;
//			}
//		}
		hygenic <- int(near_bin sum_of((each.ewaste_total / each.pop)*100));
				
		float pbc_old <- pbc;
		
		//time is how much time resident has, not time stayed at home of edevice
		//might use population statistics to initialize the attribute
		pbc <- (gauss(pbc_b,pbc_se) + 
				   gauss(hygen_b,hygen_se) * (hygenic*pbc_fine_hygenic) + 
				   gauss(time_b,time_se)  * time + 
				   gauss(pleasant_b,pleasant_se)  * pleasant +
				   gauss(space_b,space_se)  * space ) / pbc_fine_tune;
				   									//more space at home, more control over behavior
				   									//space		<-	h_unit.space_bin; how much space one household has
		
		float pbc_diff <- pbc - pbc_old;
		pbc <- pbc_old + 0.2*pbc_diff;			
	}


	
	////////////////////////////////
	///////BEH MENU
	//////////////////////////
	
	
	string beh_label;
	int beh_level;
	
	//throwing probability, waste i to bin j
	matrix p_throw <- 0 as_matrix({n_waste_type, n_ebin});
	
	
//	it might not necessary to set the upper bound to 100, because of the action check
//	int p_throw[1, 1] min:0 max:100;
//	int p_throw[1, 0] min:0 max:100;
//	int	p_throw[1, 2] min:0 max:100;
//		
//	//int	p_org_in_org min:0 max:100;
//	int	p_throw[0, 0] min:0 max:100;
//	int	p_thorw[0, 1] min:0 max:100;
//	int	p_throw[0, 2] min:0 max:100;
//		
//	int	p_throw[2, 2] min:0 max:100;
//	int	p_throw[2, 1] min:0 max:100;
//	int	p_throw[2, 0] min:0 max:100;
//	
	
	action main_beh {
		// Placeholders for more extensive models where behaviour could
		// be broken in 2 or 5 chunks. Here I do it with 4.
		// To be uploded on request. This is part of future studies
		if (q_breaks_string ="4 lines")   {do set_beh_4_lines;}	 

	}

	
	action checks {
				
		// For Mix
		if (p_throw[1, 1]+p_throw[1, 0]) > 100 {
			p_throw[1, 0] <-0;
			p_throw[1, 2] <-0;} 
			
		else if ((p_throw[1, 1]+p_throw[1, 0]) = 100) {
				p_throw[1, 2] <-0; } 
								
		else {p_throw[1, 2] <- 100 - p_throw[1, 1] - p_throw[1, 0];}
		
		// For Org		
		if (p_throw[0, 0] + p_throw[0, 1]) > 100 {
			p_throw[0, 1] <-0;
			p_throw[0, 2] <-0;} 
			
		else if ((p_throw[0, 0]+p_throw[0, 1]) = 100) {
				p_throw[0, 2] <-0; } 
								
		else {p_throw[0, 2] <- 100 - p_throw[0, 1] - p_throw[0, 0];}
		
		// For Pak	
		if (p_throw[2, 2]+p_throw[2, 1]) > 100 {
			p_throw[2, 1] <-0;
			p_throw[2, 0] <-0;
			}
		else if ((p_throw[2, 2]+p_throw[2, 1]) = 100) {
				p_throw[2, 0] <-0; }
								
		else {
			p_throw[2, 0] <- 100 - p_throw[2, 2] - p_throw[2, 1];
		}	
		
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
			p_throw[1, 1] <- int(truncated_gauss(((2.17*behaviour)+0),2.5));  //ok
			p_throw[1, 0] <- 0;	 		

			// OF ORG
			p_throw[0, 0] <- int(truncated_gauss(((1*behaviour)+0),2.5));       //ok
			p_throw[0, 1] <- int(truncated_gauss(((-1.34*behaviour)+100),5));	//ok
			
					
			// OF PAK
			p_throw[2, 2] <- int(truncated_gauss(((2*behaviour)+0),5));  //ok
			p_throw[2, 1] <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok
			
			//testes
			p_throw[3, 2] <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok
						
			}
			
		if (beh_level = 2) {
			// Sorting probability
			// OF MIX
			p_throw[1, 1] <- int(truncated_gauss(((2*behaviour) + 53),5)); //ok
			p_throw[1, 0] <- 0;			

			// OF ORG
			p_throw[0, 0] <- int(truncated_gauss(((0.8*behaviour)+21),5));   //ok
			p_throw[0, 1] <-int(truncated_gauss(((-1.2*behaviour)+96),5));	//ok	
	
			// OF PAK
			p_throw[2, 2] <- int(truncated_gauss(((0.2*behaviour)+69),5));  //ok
			p_throw[2, 1] <- int(truncated_gauss(((-1.2*behaviour)+116),5));	//ok
			
			//tested
			p_throw[3, 2] <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok
		}		

		if (beh_level = 3) {

			// Sorting probability
			// OF MIX
			p_throw[1, 1] <- int(truncated_gauss(((0.3*behaviour) + 61),5)); //ok
			p_throw[1, 0] <- int(truncated_gauss(2,2));			

			// OF ORG
			p_throw[0, 0] <- int(truncated_gauss(((0.8*behaviour)+23),5));  //ok
			p_throw[0, 1] <- int(truncated_gauss(((-1*behaviour)+85),5));   //ok

			// OF PAK
			p_throw[2, 2] <- int(truncated_gauss(((0.3*behaviour)+66),5));  //ok
			p_throw[2, 1] <- int(truncated_gauss(((-1.3*behaviour)+118),5));	//ok

			//tested
			p_throw[3, 2] <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok

			}
			
		if (beh_level = 4) {		

			// Sorting probability
			// OF MIX
			p_throw[1, 1] <- int(truncated_gauss(((0.8*behaviour) + 20),5)); //ok
			p_throw[1, 0] <- int(truncated_gauss(1,1	));

			// OF ORG
			p_throw[0, 0] <- int(truncated_gauss(((0.8*behaviour)+20),5));  //ok
			p_throw[0, 1] <- int(truncated_gauss(((-0.4*behaviour)+40),5)); //ok

			// OF PAK
			p_throw[2, 2] <- int(truncated_gauss(((0.6*behaviour)+40),5));  //ok
			p_throw[2, 1] <- int(truncated_gauss(((-1*behaviour)+100),5));	//ok
			
			//tested
			p_throw[3, 2] <- int(truncated_gauss(((-0.67*behaviour)+100),5));	//ok
			
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
		
		//LOOP REPLACEMENT
		loop i from: 0 to: n_waste_type - 1{
			current_waste[i] <-0;
			waste_dumped[i] <- false;
		}
	}

	
	//MATRIX REPLACEMENT
	matrix<bool> waste_dumped <- false as_matrix({n_waste_type, 1});
	

	
	// Throw waste inside of their households bins
	action internal_throw_home {		
		
		//GENERALIZATION MODIFICATION NEEDED
		
		////////// Throw organics
		//write "Throwing probability: \n" + p_throw + flip(p_throw[0, 0]/100);
		if(flip(p_throw[0, 0]/100) and not(waste_dumped[0])) {
		//if(p_org_in_org >= rnd_num and not(org_dumped)) {

			h_unit.bin_cc[0] 			<- h_unit.bin_cc[0] + current_waste[0]*0.001;
			h_unit.waste_in_bin[0, 0]		<- h_unit.waste_in_bin[0, 0] + current_waste[0]*0.001;		
			if (h_unit.bin_tick[0] = 0) {h_unit.bin_tick[0] <- 1;} 
			waste_dumped[0] <- true;
		}		
		
		if(flip(p_throw[0, 1]/100) and not(waste_dumped[0])) {
		//if(p_org_in_mix >= rnd_num  and not(org_dumped)) {

			h_unit.bin_cc[1] 			<- h_unit.bin_cc[1] + current_waste[0]*0.001;
			h_unit.waste_in_bin[0, 1]		<- h_unit.waste_in_bin[0, 1] + current_waste[0]*0.001;
			if (h_unit.bin_tick[1] = 0) {h_unit.bin_tick[1] <- 1;} 	
			waste_dumped[0] <- true;		
		}

		////////// Throw residuals
		if(flip(p_throw[1, 1]/100) and not(waste_dumped[1])) {			

			h_unit.bin_cc[1] 			<- h_unit.bin_cc[1] + current_waste[1]*0.001;
			h_unit.waste_in_bin[1, 1]		<- h_unit.waste_in_bin[1, 1] + current_waste[1]*0.001;	
			if (h_unit.bin_tick[1] = 0) {h_unit.bin_tick[1] <- 1;} 
			waste_dumped[1] <- true;	
		}
		
		if(flip(p_throw[1, 0]/100)  and not(waste_dumped[1])) {	
				
			h_unit.bin_cc[0] 			<- h_unit.bin_cc[0] + current_waste[1]*0.001;
			h_unit.waste_in_bin[1, 0]		<- h_unit.waste_in_bin[1, 0] + current_waste[1]*0.001;
			if (h_unit.bin_tick[0] = 0) {h_unit.bin_tick[0] <- 1;} 	
			waste_dumped[1] <- true;	
		}		
		
		if(flip(p_throw[1, 2]/100) and not(waste_dumped[1])) {	

			h_unit.bin_cc[2] 			<- h_unit.bin_cc[2] + current_waste[1]*0.001;
			h_unit.waste_in_bin[1, 2]		<- h_unit.waste_in_bin[1, 2] + current_waste[1]*0.001;		
			if (h_unit.bin_tick[2] = 0) {h_unit.bin_tick[2] <- 1;} 	
			waste_dumped[1] <- true;	
		}
		
		////////// Throw packages
		if(flip(p_throw[2, 2]/100) and not(waste_dumped[2])) {		

			h_unit.bin_cc[2] 			<- h_unit.bin_cc[2] + current_waste[2]*0.001;
			h_unit.waste_in_bin[2, 2]		<- h_unit.waste_in_bin[2, 2] + current_waste[2]*0.001;		
			if (h_unit.bin_tick[2] = 0) {h_unit.bin_tick[2] <- 1;} 	
			waste_dumped[2] <- true;
		}		
		
		if(flip(p_throw[2, 1]/100) and not(waste_dumped[2])) {
		
			h_unit.bin_cc[1] 			<- h_unit.bin_cc[1] + current_waste[2]*0.001;
			h_unit.waste_in_bin[2, 1]		<- h_unit.waste_in_bin[2, 1] + current_waste[2]*0.001;	
			if (h_unit.bin_tick[1] = 0) {h_unit.bin_tick[1] <- 1;} 	
			waste_dumped[2] <- true;	
		}
		
		
		////////// Throw the fourth thype of waste
		if(flip(p_throw[3, 2]/100) and not(waste_dumped[2])) {		

			h_unit.bin_cc[2] 			<- h_unit.bin_cc[2] + current_waste[3]*0.001;
			h_unit.waste_in_bin[3, 2]		<- h_unit.waste_in_bin[3, 2] + current_waste[3]*0.001;		
			if (h_unit.bin_tick[2] = 0) {h_unit.bin_tick[2] <- 1;} 	
			waste_dumped[3] <- true;
		}		
		
		
	// Secure some dump - Process to make sure that some waste is dumped.
	// In case the probabilities all pass and nothing has passed
	if not(waste_dumped[0]) {
		
		h_unit.bin_cc[1] 			<- h_unit.bin_cc[1] + current_waste[0]*0.001;
		h_unit.waste_in_bin[0, 1]		<- h_unit.waste_in_bin[0, 1] + current_waste[0]*0.001;
		if (h_unit.bin_tick[1] = 0) {h_unit.bin_tick[1] <- 1;} 	
		waste_dumped[0] <- true;		
		}
		
	if not(waste_dumped[1]) {
		if flip(0.8) {
		
			h_unit.bin_cc[0] 			<- h_unit.bin_cc[0] + current_waste[1]*0.001;
			h_unit.waste_in_bin[1, 0]		<- h_unit.waste_in_bin[1, 0] + current_waste[1]*0.001;
			if (h_unit.bin_tick[0] = 0) {h_unit.bin_tick[0] <- 1;} 	
			waste_dumped[1] <- true;		
			}
		else {
			
			h_unit.bin_cc[2] 			<- h_unit.bin_cc[2] + current_waste[1]*0.001;
			h_unit.waste_in_bin[1, 2]		<- h_unit.waste_in_bin[1, 2] + current_waste[1]*0.001;		
			if (h_unit.bin_tick[2] = 0) {h_unit.bin_tick[2] <- 1;} 	
			waste_dumped[1] <- true;				
		}
	}
	
	if not(waste_dumped[2]) {
		h_unit.bin_cc[1] 			<- h_unit.bin_cc[1] + current_waste[2]*0.001;
		h_unit.waste_in_bin[2, 1]		<- h_unit.waste_in_bin[2, 1] + current_waste[2]*0.001;	
		if (h_unit.bin_tick[1] = 0) {h_unit.bin_tick[1] <- 1;} 	
		waste_dumped[2] <- true;
	}
	
	
	// make the bins full
	if (h_unit.bin_cc[0] >= h_unit.bin_max[0]){h_unit.hh_bin_full[0]<-true;}
	if (h_unit.bin_cc[1] >= h_unit.bin_max[1]){h_unit.hh_bin_full[1]<-true;}
	if (h_unit.bin_cc[2] >= h_unit.bin_max[2]){h_unit.hh_bin_full[2]<-true;}		
	
	}
	
	///////////////////////7
	/// Move waste out from the household to the bins
	/////////////////////////////////////

	// Since the residents are at not all the time at home, part of waste is thrown in non residetianl bins
	// Theroy suggests that waste sorting at work could follow specific behavior
	// on request this can be changed, and tpb behavior is included in previous versions.	
	action throw_prod {
		loop i from:0 to: n_waste_type - 1{
			work_place.bin_cc[i]	<- work_place.bin_cc[i] + current_waste[i]*0.001;
		}		
	}	
	
	// The action of transfering waste out is divided by waste types
	// Since residents can throw waste incorrectly, if the percentage of miss soring is more than 50%
	// This means that waste is not sorted	
	
	action transfer_org_out {		
		//		Penalty
		

		if (((h_unit.waste_in_bin[1, 0] + h_unit.waste_in_bin[2, 0]) / (h_unit.bin_cc[0] + 0.001)) >= thold_wrong_org) { /// 0.001 secures that the division is not 0
	
			
			near_bin[1].current_cap <- near_bin[1].current_cap +  h_unit.bin_cc[0];		
			near_bin[1].used <- near_bin[1].used + 3;		
			
			//Continue tracking types
			near_bin[1].waste[0] <- near_bin[1].waste[0] + h_unit.waste_in_bin[0, 0]; //org in org
			near_bin[1].waste[1] <- near_bin[1].waste[1] + h_unit.waste_in_bin[1, 0]; //mix in org
			near_bin[1].waste[2] <- near_bin[1].waste[2] + h_unit.waste_in_bin[2, 0]; //pak in org
			
		}
		
		else {				
			near_bin[0].current_cap <- near_bin[0].current_cap +  h_unit.bin_cc[0];		
			near_bin[0].used <- near_bin[0].used + 1;
			
			//Continue tracking types
			near_bin[0].waste[0] <- near_bin[0].waste[0] + h_unit.waste_in_bin[0, 0];
			near_bin[0].waste[1] <- near_bin[0].waste[1] + h_unit.waste_in_bin[1, 0];
			near_bin[0].waste[2] <- near_bin[0].waste[2] + h_unit.waste_in_bin[2, 0];
			
			//write "Transfer org out correct, amount s" + h_unit.waste_in_bin[0, 0] + near_bin[0].waste[0] + near_bin[0].waste[1] + near_bin[0].waste[2];
		
		}
	
		h_unit.bin_cc[0] 			<- 0.0;
		h_unit.hh_bin_full[0]		<- false;
		h_unit.bin_tick[0] 		<- 0;	
		
		// reseting after dump
	 	h_unit.waste_in_bin[0, 0] <-0.0;	
	 	h_unit.waste_in_bin[1, 0] <-0.0;	
	 	h_unit.waste_in_bin[2, 0] <-0.0;
		
		q_empty_org <- q_empty_org + 1;
		h_unit.bin_max[0] <- rnd(1.0,1.5);
	}

	action transfer_mix_out {			
		// simple			
		near_bin[1].current_cap <- near_bin[1].current_cap +  h_unit.bin_cc[1];
		near_bin[1].used <- near_bin[1].used + 1;
		
		//Continue tracking types
		near_bin[1].waste[0] <- near_bin[1].waste[0] + h_unit.waste_in_bin[0, 1];
		near_bin[1].waste[1] <- near_bin[1].waste[1] + h_unit.waste_in_bin[1, 1]; //mix in mix
		near_bin[1].waste[2] <- near_bin[1].waste[2] + h_unit.waste_in_bin[2, 1]; //pak in mix
		
				
		h_unit.bin_cc[1] 			<- 0.0;
		h_unit.hh_bin_full[1]		<- false;
		h_unit.bin_tick[1] 		<- 0;	
		
		// reseting after dump
	 	h_unit.waste_in_bin[0, 1] <-0.0;	
	 	h_unit.waste_in_bin[1, 1] <-0.0;	
	 	h_unit.waste_in_bin[2, 1] <-0.0;
		
		q_empty_mix <- q_empty_mix + 1;	
		h_unit.bin_max[1] <- rnd(1.0,1.5);		
	}
		
	action transfer_pak_out {				
		if (((h_unit.waste_in_bin[1, 2] + h_unit.waste_in_bin[0, 2]) / h_unit.bin_cc[2]+0.001) >= thold_wrong_pak) {		/// 0.001 secures that the division is not 0	
			
			near_bin[1].current_cap <- near_bin[1].current_cap +  h_unit.bin_cc[2];		
			near_bin[1].used <- near_bin[1].used + 3;		
			
			//Continue tracking types
			near_bin[1].waste[0] <- near_bin[1].waste[0] + h_unit.waste_in_bin[0, 2]; //org in pak
			near_bin[1].waste[1] <- near_bin[1].waste[1] + h_unit.waste_in_bin[1, 2]; //mix in pak
			near_bin[1].waste[2] <- near_bin[1].waste[2] + h_unit.waste_in_bin[2, 2]; //pak in pak
			
		}
		
		else {
			near_bin[2].current_cap <- near_bin[2].current_cap +  h_unit.bin_cc[2];		
			near_bin[2].used <- near_bin[2].used + 1;
		
			//Continue tracking types
			near_bin[2].waste[0] <- near_bin[2].waste[0] + h_unit.waste_in_bin[0, 2];
			near_bin[2].waste[1] <- near_bin[2].waste[1] + h_unit.waste_in_bin[1, 2];
			near_bin[2].waste[2] <- near_bin[2].waste[2] + h_unit.waste_in_bin[2, 2];
		
		}
		
		// Penalty
		h_unit.bin_cc[2] 			<- 	0.0;
		h_unit.hh_bin_full[2]		<-	false;
		h_unit.bin_tick[2] 		<-	0;	
			
		// reseting after dump
	 	h_unit.waste_in_bin[0, 2] 		<-	0.0;	
	 	h_unit.waste_in_bin[1, 2] 		<-	0.0;	
	 	h_unit.waste_in_bin[2, 2] 		<-	0.0;
	 	
	 	q_empty_pak 			<- 	q_empty_pak + 1;
	 	h_unit.bin_max[2] 			<-	rnd(1.0,2.0);

				
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
		if (h_unit.hh_bin_full[0] and h_unit.bin_cc[0] >0)  { 				
				do transfer_org_out; 			
			}			
			
		// // Disposal when waste degreades
		if (h_unit.bin_tick[0]/3) > rnd(4,6) {				
				do transfer_org_out; 				
			}	
			
	//////////////MIX
		// mix - general	
		if (h_unit.hh_bin_full[1] and h_unit.bin_cc[1] >0){				
				do transfer_mix_out; 
			}
		// Disposal when waste degreades	
		if (h_unit.bin_tick[1]/3) > rnd(5,8) {				
				do transfer_mix_out; 
			}			
			
	///////////// PAK
		// General disposal mechanism		
		if (h_unit.hh_bin_full[2] and h_unit.bin_cc[2] >0){				
				do transfer_pak_out;				
			}	
		// Disposal when waste degreades	
		if (h_unit.bin_tick[2]/3) > rnd(5,14) {				
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
		//Turn off commute for better tracking
		//do commute;		
		
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
	
	user_command "Increase info" category: "During simulation" color:#blue {
		ask world {do increase_info;}
	}
	
	user_command "Decrease info" category: "During simulation" color:#red {
		ask world {do decrease_info;}
	}
	
//	user_command "Increase mix info" category: "During simulation" color:#blue {
//		ask world {do increase_mix_info;}
//	}
//	
//	user_command "Decrease mix info" category: "During simulation" color:#red {
//		ask world {do decrease_mix_info;}
//	}
//
//	user_command "Increase pak info" category: "During simulation" color:#blue {
//		ask world {do increase_pak_info;}
//	}
//	
//	user_command "Decrease pak info" category: "During simulation" color:#red {
//		ask world {do decrease_pak_info;}
//	}
	
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

//////////////////////////
// TEMPORALLY IGNORE  ///
/////////////////////////

//	parameter "Info in Org"   var: global_bin_info[0] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
//	
//	parameter "Info in Mix"   var: global_bin_info[1] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
//		
//	parameter "Info in Pak"   var: global_bin_info[2] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
		
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
			
			chart "Behaviour distribution" type:histogram
			 	x_serie_labels: ["Behaviour"]
			 	series_label_position: xaxis
			 	{ 
			 		datalist value:(distribution_of(resident collect each.behaviour,20,0,100) at "values")
			 		 legend:(distribution_of(resident collect each.behaviour,20,0,100) at "legend"); 				 
			 }				
			
		}
		


			
	display "Waste type in STREET bins"  type:2d {
			chart "Waste inside of STREET bins" type:histogram
			 	x_serie_labels: ["Organic bin", "Residual bin", "Recyclable bin"]
			 	
			series_label_position: legend
			 {
				datalist value:[
					
					[	(sum(bin where (each.type = "ORG") collect each.waste[0])),
						(sum(bin where (each.type = "MIX") collect each.waste[0])),
						(sum(bin where (each.type = "PAK") collect each.waste[0]))],
						
					[	(sum(bin where (each.type = "ORG") collect each.waste[1])),
						(sum(bin where (each.type = "MIX") collect each.waste[1])),
						(sum(bin where (each.type = "PAK") collect each.waste[1]))],
						
					[	(sum(bin where (each.type = "ORG") collect each.waste[2])),
						(sum(bin where (each.type = "MIX") collect each.waste[2])),
						(sum(bin where (each.type = "PAK") collect each.waste[2]))]

						
					]
					   style:stack 
					   legend:["Organic", "Residual", "Recyclable"]
					   color: [	(#green),(#red), (#blue)];
			}
		
								
		}
	/////////////////
	//E-WASTE DISPLAY
	/////////////////
		display "Time at home of E-devices" type:2d {
			chart "Time at home of E-devices" type:histogram
			 	x_serie_labels: ["ICT", "Battery", "Lamp"]
			 	
			series_label_position: legend
			 {
				datalist value:[
					global_ewaste_time_at_home[0, 0], global_ewaste_time_at_home[1, 0], global_ewaste_time_at_home[2, 0]
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
					
					[	(collector  collect each.res_waste_in_bin[0, 0]),
						(collector  collect each.res_waste_in_bin[1, 0]),
						(collector  collect each.res_waste_in_bin[2, 0])],
						
						[(collector  collect each.res_waste_in_bin[0, 1]),
						(collector  collect each.res_waste_in_bin[1, 1]),
						(collector  collect each.res_waste_in_bin[2, 1])],
						
					[	(collector  collect each.res_waste_in_bin[0, 2]),
						(collector  collect each.res_waste_in_bin[1, 2]),
						(collector  collect each.res_waste_in_bin[2, 2])]

						
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
					[	(sum(house_hold collect each.waste_in_bin[0, 0])),
						(sum(house_hold collect each.waste_in_bin[1, 0])),
						(sum(house_hold collect each.waste_in_bin[2, 0]))],
						
					[	(sum(house_hold collect each.waste_in_bin[1, 0])),
						(sum(house_hold collect each.waste_in_bin[1, 1])),
						(sum(house_hold collect each.waste_in_bin[1, 2]))],
						
					[	(sum(house_hold collect each.waste_in_bin[2, 0])),
						(sum(house_hold collect each.waste_in_bin[2, 1])),
						(sum(house_hold collect each.waste_in_bin[2, 2]))]
						
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
		
//		display city  type:2d {
//			species bin aspect:base;			
//			species prod_build aspect:base;
//			species resi_build aspect:base;
//			species resident aspect:base;
//			species collector;	
//			
//		}
		
	}
	
}


// This experiment shows the only the tpb constructs and how behavior evolves
experiment only_tpb type: gui{
	
	user_command "Clean bins" category: "During simulation" color:#green {
		ask collector {do empty_n_clean;}
	}
	
	
	parameter "Clean frequently" var: clean_on category:"During simulation";
	parameter "TPB at work" var: work_tpb category:"During simulation";	
	
	
	user_command "Increase info" category: "During simulation" color:#blue {
		ask world {do increase_info;}
	}
	
	user_command "Decrease info" category: "During simulation" color:#red {
		ask world {do decrease_info;}
	}
	
//	user_command "Increase mix info" category: "During simulation" color:#blue {
//		ask world {do increase_mix_info;}
//	}
//	
//	user_command "Decrease mix info" category: "During simulation" color:#red {
//		ask world {do decrease_mix_info;}
//	}
//
//	user_command "Increase pak info" category: "During simulation" color:#blue {
//		ask world {do increase_pak_info;}
//	}
//	
//	user_command "Decrease pak info" category: "During simulation" color:#red {
//		ask world {do decrease_pak_info;}
//	}	
	
	
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

//////////////////////////
// TEMPORALLY IGNORE  ///
/////////////////////////
	
//	parameter "Info in Org"   var: global_bin_info[0] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
//	
//	parameter "Info in Mix"   var: global_bin_info[1] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
//		
//	parameter "Info in Pak"   var: global_bin_info[2] min: 0 max: 100 step: 5
//		category: "Scenario definition";	
		
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
    

    
    
    