///////////////////////////////////////////////////
//
// Attract-Mode Frontend -  Emitter launcher
//
///////////////////////////////////////////////////
//

// --------------------
// Load Modules
// --------------------

fe.load_module("helpers");

// --------------------
// Plugin User Options
// --------------------

class UserConfig </ help="A plugin that calls LedSpicer's Emitter (ex. emitter LoadProfileByEmulator galaga arcade)  to show the controls for the selected game after a period of inactivity. Your AM emulator's configured System name must be the desired profile folder name for console systems or to use the arcade setting of Emitter, the configured system name  must be neogeo or start with the terms arcade, mame, fba, or daphne " /> {
	</ label="Delay Time",
		help="The amount of inactivity (in microseconds) before Launching Emitter",
		order=1 />
	delayTime="1000";
    </ label="Activation Mode",
		options="Automatic,Manual", 
        help="If set to to Automatic mode, after the delay time, Emitter will be called. In manual mode, you must push a button",
		order=2 /> 
		mode="Automatic";
    </ label="Key", 
        help="The key that will activate the Emitter plugin hen in Manual mode", 
        is_input="yes", 
        order=3 />
	    key="";
}



class Emitter {
	config = null;

    key = null; 
	currentTime = null;
	delayTime = null;
	signalTime = null;
    key_delay = null; 
	status = null; // 0 = off, 1 = on, 2 = ready
	introStatus = null; // 0 = off, 1 = on
	currentRom="attract"; 
    last_check = 0; 
	constructor() {
		config = fe.get_config();
			try {
				config["delayTime"] = config["delayTime"].tointeger();
				assert(config["delayTime"] >= 1);
			}
			catch (e) {
				print("ERROR in Emitter Plugin: user options - improper delay time\n");
				config["delayTime"] = 1000;
			}

		currentTime = 0;
		delayTime = config["delayTime"];
        key = config["key"];
        signalTime = 0;
		status = 2;
		introStatus = 0;
        key_delay = 250;
		last_check = 0;

        if ( config["mode"] == "Automatic" )
        {
            fe.add_ticks_callback(this, "ticks");
		    fe.add_transition_callback(this, "transitions");
        }
        else
        {
            fe.add_ticks_callback(this,"check_key");
        }

	}
	function check_key(ttime){
        local is_down = fe.get_input_state( key );
        if ( is_down )
        {
            if ( ttime - last_check > key_delay )
            {
                last_check = ttime;
                launch_emitter();
            }
        }
    }
	// ----- Ticks Callbacks -----
	function ticks(ttime) {
		// Current Time (accessible from transitions)
		currentTime = ttime;
		
		// Intro Status
		switch (IntroActive) {
			case 1:
				if (introStatus == 0) {
					introStatus = 1;
					status = 0;
				}
				break;
			case 0:
				if (introStatus == 1) {
					introStatus = 0;
					status = 2;
				}
				break;
		}

		// Update Signal Time and Status (after intro or FromGame)
		if (status == 2) {
			signalTime = currentTime;
			status = 1;
		}

		// Launch Emitter
		if (status == 1 && (currentTime >= signalTime + delayTime) && currentRom != fe.game_info(Info.Name) ) {
		  launch_emitter(); 
		}
	}
    function launch_emitter(){
        local emulatorname = fe.game_info(Info.Emulator);
		currentRom = fe.game_info(Info.Name);		
		//system("emitter LoadProfileByEmulator galaga arcade"); 
		system("emitter LoadProfileByEmulator " + fe.game_info(Info.Name )  + " " + emulatorname.tolower() + " --no-rotate"); 
        // print what just happened for debug purposes
        system("echo \"emitter LoadProfileByEmulator " + fe.game_info(Info.Name) + " " +  emulatorname.tolower() + "\" --no-rotate"); 
		//status = 1; 
    }
	// ----- Transition Callbacks -----

	function transitions(ttype, var, ttime) {
		signalTime = currentTime;

		switch (ttype) {
			case Transition.ToGame:
				status = 0;
				break;
			case Transition.FromGame:
				status = 2;
				break;
		}

		return false;
	}
}
fe.plugin["Emitter"] <- Emitter();


