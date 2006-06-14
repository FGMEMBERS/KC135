# Properties under /consumables/fuel/tank[n]:
# + level-gal_us    - Current fuel load.  Can be set by user code.
# + level-lbs       - OUTPUT ONLY property, do not try to set
# + selected        - boolean indicating tank selection.
# + density-ppg     - Fuel density, in lbs/gallon.
# + capacity-gal_us - Tank capacity 
#
# Properties under /engines/engine[n]:
# + fuel-consumed-lbs - Output from the FDM, zeroed by this script
# + out-of-fuel       - boolean, set by this code.

# ==================================== timer stuff ===========================================

# set the update period

UPDATE_PERIOD = 0.3;

# set the timer for the selected function

registerTimer = func {
	
    settimer(arg[0], UPDATE_PERIOD);

} # end function 

# =============================== end timer stuff ===========================================



initialized = 0;
enabled = 0;

print ("running aar");
#print (" enabled " , enabled,  " initialized ", initialized);  

updateTanker = func {
# print ("tanker update running ");
				#if (!initialized ) {
				#print("calling initialize");
				#initialize();}
    
        Refueling = props.globals.getNode("/systems/refuel/contact");
        AllAircraft = props.globals.getNode("ai/models").getChildren("aircraft");
				AllMultiplayer = props.globals.getNode("ai/models").getChildren("multiplayer");
        Aircraft = props.globals.getNode("ai/models/aircraft");
        
#   select all tankers which are in contact. For now we assume that it must be in 
#		contact	with us.
                
        selectedTankers = [];
				
				if ( enabled ) { # check that AI Models are enabled, otherwise don't bother
            foreach(a; AllAircraft) { 
								id_node = a.getNode("id" , 1 ); 
								id = id_node.getValue();
								if ( id != nil ) {
										contact_node = a.getNode( "refuel/contact" );
										tanker_node = a.getNode( "tanker" );
										
										contact = contact_node.getValue();
										tanker = tanker_node.getValue();
										
        #						print ("contact ", contact , " tanker " , tanker );
																
										if (tanker and contact) {
												append(selectedTankers, a);
										} # endif
								} # endif
            } # end foreach
						
						foreach(m; AllMultiplayer) {
								id_node = m.getNode("id" , 1 );
								id = id_node.getValue();
								
								if ( id != nil ) {
										contact_node = m.getNode("refuel/contact");
										tanker_node = m.getNode("tanker");
										
										contact = contact_node.getValue();
										tanker = tanker_node.getValue();
                
#										print (" mp contact ", contact , " tanker " , tanker );
                            
										if (tanker and contact) {
												append(selectedTankers, m);
										} # endif
								}  # endif
            } # end foreach
        } # endif
         
#		print ("tankers ", size(selectedTankers) );

        if ( size(selectedTankers) >= 1 ){
            Refueling.setBoolValue(1);
        } else {
            Refueling.setBoolValue(0);
        }
		registerTimer(updateTanker);
}

# Initalize: Make sure all needed properties are present and accounted
# for, and that they have sane default values.

initialize = func {
   
    AI_Enabled = props.globals.getNode("sim/ai/enabled");
    Refueling = props.globals.getNode("/systems/refuel/contact",1);
            
    Refueling.setBoolValue(0);
    enabled = AI_Enabled.getValue();
        
    initialized = 1;
}

initDoubleProp = func {
    node = arg[0]; prop = arg[1]; val = arg[2];
    if(node.getNode(prop) != nil) {
        val = num(node.getNode(prop).getValue());
    }
    node.getNode(prop, 1).setDoubleValue(val);
}

# Fire it up
if (!initialized) {initialize();}
registerTimer(updateTanker);


# ================================== EHSI Stuff ===================================


range_control_node = props.globals.getNode("/instrumentation/radar/range-control", 1);
range_node = props.globals.getNode("/instrumentation/radar/range", 1);
wx_range_node = props.globals.getNode("/instrumentation/wxradar/range", 1);
x_shift_node=  props.globals.getNode("instrumentation/tacan/display/x-shift", 1 );
x_shift_scaled_node=  props.globals.getNode("instrumentation/tacan/display/x-shift-scaled",1);
y_shift_node=  props.globals.getNode("instrumentation/tacan/display/y-shift", 1 );
y_shift_scaled_node=  props.globals.getNode("instrumentation/tacan/display/y-shift-scaled",1);
display_control_node = props.globals.getNode("/instrumentation/display-unit/control", 1);
radar_control_node = props.globals.getNode("/instrumentation/radar/mode-control", 1);
    
range_control_node.setIntValue(3); 
range_node.setIntValue(40); 
wx_range_node.setIntValue(40); 
x_shift_node.setDoubleValue(0);
x_shift_scaled_node.setDoubleValue(0);
y_shift_node.setDoubleValue(0);
y_shift_scaled_node.setDoubleValue(0);
display_control_node.setIntValue(1);
radar_control_node.setIntValue(1);
var scale = 2.55;	

# Lib functions
pow2 = func(e) { return e ? 2 * pow2(e - 1) : 1 } # calculates 2^e


adjustRange = func{

		range = range_node.getValue();
		range_control = range_control_node.getValue();
		
		range = 5 * pow2( range_control ); 

#  	print ( "range " , range);

		range_node.setIntValue( range );
		wx_range_node.setIntValue( range );
    scale = 1.275 * pow2 ( 7 - range_control ) * 0.1275;
	  scale = sprintf( "%2.3f" , scale );

#		print ( "scale " , scale );

} # end function adjustRange

scaleShift = func {

	x_shift_scaled_node.setDoubleValue( x_shift_node.getValue() * scale );
	y_shift_scaled_node.setDoubleValue( y_shift_node.getValue() * scale );
#	print ( "x-shift-scaled " , x_shift_scaled_node.getValue() );
#	print ( "y-shift-scaled " , y_shift_scaled_node.getValue() );
	registerTimer( scaleShift );
						
} # end func scaleshift


scaleShift();	

setlistener( range_control_node , adjustRange );

# ====================================== Radar Stuff ==================================

DEGREES_TO_RADIANS = 0.01745329252;

AllAircraft = props.globals.getNode("ai/models").getChildren("aircraft");
AllMultiplayer = props.globals.getNode("ai/models").getChildren("multiplayer");
AI_Enabled = props.globals.getNode("sim/ai/enabled");
wx_display_node = props.globals.getNode("/instrumentation/wxradar/display-mode", 1);
radar_mode_control_node = props.globals.getNode("/instrumentation/radar/mode-control", 1);
radar_display_hdg_node = props.globals.getNode("/instrumentation/radar/display-heading-deg", 1);

wx_display_node.setValue("plan");
radar_mode_control_node.setIntValue(1);

enabled = AI_Enabled.getValue();


scaleRadarShift = func{

	if ( enabled ) { # check that AI Models are enabled, otherwise don't bother
			heading_node = props.globals.getNode( "orientation/heading-deg" , 1 );
			heading = heading_node.getValue();
			
			foreach(a; AllAircraft) {
					id_node = a.getNode("id", 1 );
					id = id_node.getValue();  
					if (id != nil ) {		
						radar_bearing_deg_node = a.getNode( "radar/bearing-deg" );
						radar_distance_nm_node = a.getNode( "radar/range-nm" );
						radar_in_view_node = a.getNode( "radar/in-view" , 1 );
						radar_x_shift_scaled_node = a.getNode( "radar/x-shift-scaled" , 1 );
						radar_y_shift_scaled_node = a.getNode( "radar/y-shift-scaled" , 1 );
						
						radar_mode_control = radar_mode_control_node.getValue();	
						bearing = radar_bearing_deg_node.getValue() ;
						distance_nm = radar_distance_nm_node.getValue();
						
				#calculate relative bearing of tgt 
								
						if (heading != nil) {
								rel_brg = bearing - heading;
								if (rel_brg <= 0){
										rel_brg += 360;
								}
								
								if ( rel_brg < 120 or rel_brg > 240 ) { # we hide the target if it's behind the ac
										radar_in_view_node.setBoolValue( 1 );
								} else {
										radar_in_view_node.setBoolValue( 0 );
								}
								
								if ( radar_mode_control == 2 ) { # use rel brgs if we are in map mode
										y_shift = distance_nm * math.cos( rel_brg * DEGREES_TO_RADIANS );
										x_shift = distance_nm * math.sin( rel_brg * DEGREES_TO_RADIANS );
										display_heading = 0;
										
								} else { # use true brgs in plan mode
										y_shift = distance_nm * math.cos( bearing * DEGREES_TO_RADIANS );
										x_shift = distance_nm * math.sin( bearing * DEGREES_TO_RADIANS );
										display_heading = heading;
								}
								
								radar_x_shift_scaled_node.setDoubleValue( x_shift * scale );
								radar_y_shift_scaled_node.setDoubleValue( y_shift * scale );
								
								radar_display_hdg_node.setDoubleValue( display_heading );
						}
						
					}
			} #end foreach
			
			foreach(m; AllMultiplayer) { # do it over for multiplayer
					id_node = m.getNode("id", 1 );
					id = id_node.getValue(); 
					
					if (id != nil ) {		
						multiplayer_bearing_deg_node = m.getNode("radar/bearing-deg");
						multiplayer_distance_nm_node = m.getNode("radar/range-nm");
						multiplayer_x_shift_scaled_node = m.getNode("radar/x-shift-scaled" , 1 );
						multiplayer_y_shift_scaled_node = m.getNode("radar/y-shift-scaled" , 1 );
						multiplayer_in_view_node = m.getNode( "radar/in-view" , 1 );
						
						bearing = multiplayer_bearing_deg_node.getValue() ;
						distance_nm = multiplayer_distance_nm_node.getValue();
						
						#calculate relative bearing of tgt 
								
						if (heading != nil) {
								rel_brg = bearing - heading;
								if (rel_brg <= 0){
										rel_brg += 360;
								}
								
								if ( rel_brg < 120 or rel_brg > 240 ) { # we hide the target if it's behind the ac
										multiplayer_in_view_node.setBoolValue( 1 );
								} else {
										multiplayer_in_view_node.setBoolValue( 0 );
								}
								
								if ( radar_mode_control == 2 ) { # use rel brgs if we are in map mode
										y_shift = distance_nm * math.cos( rel_brg * DEGREES_TO_RADIANS );
										x_shift = distance_nm * math.sin( rel_brg * DEGREES_TO_RADIANS );
										display_heading = 0;
										
								} else { # use true brgs in plan mode
										y_shift = distance_nm * math.cos( bearing * DEGREES_TO_RADIANS );
										x_shift = distance_nm * math.sin( bearing * DEGREES_TO_RADIANS );
										display_heading = heading;
								}
								
						multiplayer_x_shift_scaled_node.setDoubleValue( x_shift * scale );
						multiplayer_y_shift_scaled_node.setDoubleValue( y_shift * scale );
					}
				}
			} #end foreach
	
	} # endif
	
registerTimer( scaleRadarShift );		
	
} # end func

updateRadarMode = func{
	radar_mode_control = radar_mode_control_node.getValue();
		if ( radar_mode_control == 2 ) {
				wx_display_node.setValue("map");
		} else {
				wx_display_node.setValue("plan");
		}
} # end func

setlistener( radar_mode_control_node , updateRadarMode );

scaleRadarShift();

# end
