///////////////////////////////////////////////////
//
// Attract-Mode Frontend -  Emitter launcher
//
// Plugin by mahuti https://github.com/mahuti/Emitter-Plugin
//
// requires LEDSpicer to be installed and configured to use
// https://sourceforge.net/p/ledspicer/wiki/Home/
//
///////////////////////////////////////////////////
//

// --------------------
// Load Modules
// --------------------

fe.load_module("helpers")

// --------------------
// Plugin User Options
// --------------------
local order = 0 
class UserConfig </ help="This plugin: 1. Changes light profiles while navigating AM based on the currently shown rom. 2. Changes light and joystick profiles when a rom is launched. FOR ARCADE SYSTEMS: Emulator System Name must include one of the following, arcade, mame, neo geo, neogeo, fba, final burn, or daphne. FOR CONSOLES: Emulator System Name must match the LEDSPicer profile name (for instance a system named \"Nintendo Entertainment System\" will launch the \"Nintendo Entertainment System.xml\" profile ) " /> {
	</ label="Delay Time",
		help="The amount of inactivity (in microseconds) before Launching Emitter",
		order=order++ />
		delayTime="1000";
    
	</ label = "Reset Time", 
		help="This is the period of time until the profile resets",
		order=order++ />
		reset_time="10000"; 
    
	</ label = "Default Profile",
		help="The name of the profile that should be sent after a game exits & after the reset time. This should be a valid profile name set up in LEDSpicer. If you use dynamic joysticks, the profile should include a rotator profile", 
		order=order++ />
		default_profile="attract";
    
    </ label = "Joystick Default Position",
        options="Use profile default,Vertical 2-way,4-way,8-way,Analog"
        help="If using dynamic joysticks, you can set a default joystick mode to use while in AttractMode. If you have a default profile set, this option will override it. Your joystick must support the selected mode, or the closest mode will be used instead",
        order=order++ />
        default_rotation="Use profile default";
        
    </ label="Activation Mode",
		options="Automatic,Manual", 
		help="If set to to Automatic mode, after the delay time, Emitter will be called. In manual mode, you must push a button",
		order=order++ /> 
		mode="Automatic";
    
    </ label="Key", 
        help="The key that will activate the Emitter plugin when in Manual mode", 
        is_input="yes", 
        order=order++ />
	    key="";
}



class Emitter {
	config = null
    key = null
	currentTime = null
	delayTime = null
    reset_long_time = 1000000000  // this value is used to keep the default profile from being reset to default over and over
    reset_time = null 
	signalTime = null
    key_delay = null 
	status = null // active, waiting
	currentRom="attract" 
    last_check = 0 
	constructor() {
        config = fe.get_config()
        try {
            config["delayTime"] = config["delayTime"].tointeger()
            assert(config["delayTime"] >= 1)
        }
        catch (e) {
            print("ERROR in Emitter Plugin: user options - improper delay time\n")
            config["delayTime"] = 1000
        }
        try {
            config["reset_time"] = config["reset_time"].tointeger()
            assert(config["reset_time"] >= 1)
        }
        catch (e) {
            print("ERROR in Emitter Plugin: user options - improper reset time\n")
            config["reset_time"] = 10000
        }
		currentTime = 0
		delayTime = config["delayTime"]
        reset_time = config["reset_time"] 
        key = config["key"]
        signalTime = 0
		status = "waiting"
		introStatus = 0
        key_delay = 250
		last_check = 0

        if ( config["mode"] == "Automatic" )
        {
            fe.add_ticks_callback(this, "ticks")
		    fe.add_transition_callback(this, "transitions")
        }
        else
        {
            fe.add_ticks_callback(this,"check_key")
        }
        
        fe.add_transition_callback(this, "loadgame")

	}
    
    /* ************************************  
    check_key
    ticks callback

    manual mode 
    
    This checks to see if the manual mode key
    is pressed  and launches emitter profiles 
    without rotation

    @return false
    ************************************ */ 
    
    // this ticks callback is used for manual mode
	function check_key(ttime){
        local is_down = fe.get_input_state( key )
        if ( is_down )
        {
            if ( ttime - last_check > key_delay )
            {
                last_check = ttime
                launch_emitter()
            }
        }
    }
    
    /* ************************************  
    ticks
    ticks callback

    manual mode 
    
    This checks to see if the manual mode key
    is pressed  and launches emitter profiles 
    without rotation

    @return false
    ************************************ */ 
	function ticks(ttime) {
        
		// Current Time (accessible from transitions)
		currentTime = ttime

		// Update Signal Time and Status (after intro or FromGame)
		if (status == "waiting") {
			signalTime = currentTime
			status = "active"
		}

		// Launch Emitter after the delay time in automatic mode
		if (status == "active" && (currentTime >= signalTime + delayTime) && currentRom != fe.game_info(Info.Name) ) {
		  launch_emitter() 
          reset_time = config["reset_time"] 
		}
        
        // when the default profile is activated by being reset, a very long time is set for the reset value so that we 
        // don't get a lot of needless resetting to the default over and over and over. Once a different rom is selected, 
        // the reset time is set back to the configured value
        if (status == "active" && (currentTime >= signalTime + reset_time + delayTime) && currentRom == fe.game_info(Info.Name) ) {
		  default_emitter() 
          status = "waiting" 
          reset_time = reset_long_time 
		}
	}
    /* ************************************  
    launch_emitter

    This launches emitter which activates 
    profiles & rotators. Emulators that include
    the words mame, daphne, neo geo, final burn,
    neogeo, fba, arcade, the LoadProfileByEmulator romname arcade
    method will be used. For all other system 
    names LoadProfile systemname will be used 

    @param rotate=false  if true, rotation will
    be enabled
    
    @return null
    ************************************ */ 
    function launch_emitter(rotate=false ){
        local no_rotate = " --no-rotate"
        currentRom = fe.game_info(Info.Name)		
        local emulatorname = fe.game_info(Info.Emulator)

        if (rotate)
        {
            no_rotate = ""
        } 
        
        local expression = regexp("f(?:inal burn|ba)|neo ?geo|(?:daphn|mam)e|arcade") // check for arcade-type systems
        local is_arcade = expression.match(emulatorname.tolower())
	    //system ("echo \"match: "+ is_arcade + "\"") 
        
        if (is_arcade)
        {
          if (rotate)
          {
            // setting a default in case the game / profile doesn't have one. 
            system("rotator 1 1 8 2 1 8 > /dev/null 2>&1") 
          }
          //example: system("emitter LoadProfileByEmulator galaga arcade") 
		  system("emitter LoadProfileByEmulator " + "\"" + fe.game_info(Info.Name ) + "\"" + " arcade" + no_rotate + " > /dev/null 2>&1") 
          // print what just happened for debug purposes
          //system("echo \"emitter LoadProfileByEmulator " + fe.game_info(Info.Name) + " " +  emulatorname + " --no-rotate\"") 
        }
        else
        {
            // not an arcade system, load a profile based on the system name
            // example: emitter LoadProfile "Sega Master System" 
		    system("emitter LoadProfile " + "\"" + emulatorname  + "\" " + no_rotate + " > /dev/null 2>&1") 
        }
    }
    /* ************************************  
    default_emitter

    This sets a default profile based on the
    configuration values, and sets the default
    rotator if configured
    
    @return null
    ************************************ */ 
    function default_emitter(){
        
        local no_rotate = " --no-rotate"
          
        if (config["default_rotation"] !="Use profile default")
        {
            // example: rotator 1 1 4 2 1 4 
            system("rotator 1 1 " + config["default_rotation"] + " 2 1 " + config["default_rotation"] +  "  > /dev/null 2>&1") 
            no_rotate = ""  // turn off rotation for the profile since we're setting a mode here.
        }
 
        if (config["default_profile"] != "" )
        {
            system("emitter LoadProfile " + config["default_profile"] + no_rotate + " > /dev/null 2>&1" )
        }
    }
    /* ************************************  
    reset_emitter

    clears last profile and runs the 
    default emitter profile
    
    @return null
    ************************************ */ 
    function reset_emitter()
    {
        system( "emitter FinishLastProfile > /dev/null 2>&1" )
        
        default_emitter()
    }

    /* ************************************  
    transitions
    transition callback

    automatic mode
    
    Sets times used in ticks callback and
    sets status of timer back to waiting

    @return false
    ************************************ */ 
	function transitions(ttype, var, ttime) {
		signalTime = currentTime

		switch (ttype) {
			case Transition.ToGame:
                status = "active"
				break
			case Transition.FromGame:
				status = "waiting"
				break
		}

		return false
	}
    /* ************************************  
    loadgame
    transition callback

    both manual and automatic modes
    
    launches emitter & rotator on ToGame
    resets emitter & rotator on FromGame

    @return false
    ************************************ */ 
    function loadgame(ttype, var, ttime) {

		switch (ttype) {
			case Transition.ToGame:
                launch_emitter(true)
                break
			case Transition.FromGame:
                reset_emitter()
                break
		}

		return false
	}
}
fe.plugin["Emitter"] <- Emitter()


