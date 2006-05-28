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
                contact_node = a.getNode("refuel/contact");
                id_node = a.getNode("id");
                tanker_node = a.getNode("tanker");
                
                contact = contact_node.getValue();
                id = id_node.getValue();
                tanker = tanker_node.getValue();
                
#				print ("contact ", contact , " tanker " , tanker );
                            
                if (tanker and contact) {
                    append(selectedTankers, a);
                }
            }
						
						foreach(m; AllMultiplayer) {
                contact_node = m.getNode("refuel/contact");
                id_node = m.getNode("id");
                tanker_node = m.getNode("tanker");
                
                contact = contact_node.getValue();
                id = id_node.getValue();
                tanker = tanker_node.getValue();
                
#				print (" mp contact ", contact , " tanker " , tanker );
                            
                if (tanker and contact) {
                    append(selectedTankers, m);
                }
            }
        }
         
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


# ================================== Nav-Display Stuff ===================================


range_control_node = props.globals.getNode("/instrumentation/radar/range-control", 1);
range_node = props.globals.getNode("/instrumentation/radar/range", 1);
x_shift_node=  props.globals.getNode("instrumentation/tacan/display/x-shift", 1 );
x_shift_scaled_node=  props.globals.getNode("instrumentation/tacan/display/x-shift-scaled",1);
y_shift_node=  props.globals.getNode("instrumentation/tacan/display/y-shift", 1 );
y_shift_scaled_node=  props.globals.getNode("instrumentation/tacan/display/y-shift-scaled",1);
    
range_control_node.setIntValue(5); 
range_node.setIntValue(32); 
x_shift_node.setDoubleValue(0);
x_shift_scaled_node.setDoubleValue(0);
y_shift_node.setDoubleValue(0);
y_shift_scaled_node.setDoubleValue(0);

var scale = 2.55;	

# Lib functions
pow2 = func(e) { return e ? 2 * pow2(e - 1) : 1 } # calculates 2^e


adjustRange = func{

		range = range_node.getValue();
		range_control = range_control_node.getValue();
		
		range = pow2( range_control ); 

#  	print ( "range " , range);

		range_node.setIntValue( range );
		
		scale = 1.275 * pow2 ( 6 - range_control );
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

# end
