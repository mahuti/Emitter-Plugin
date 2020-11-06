# Emitter Plugin

The Emitter plugin for AttractMode works with LEDSpicer to change your lighting configuration based on your currently selected ROM in AttractMode. 

## Installation

*NOTE:* Make sure you have [LEDSpicer](https://sourceforge.net/p/ledspicer/wiki/Home/) installed and configured or this plugin will not work, and will probably aggrivate your system. 

Once you've confirmed LEDSpicer is installed and working, add the Emitter plugin folder to the plugins folder of AttractMode (make sure the correct permissions are set on the folder so that AttractMode can see the newly added plugin). Start (or restart) AttractMode and enable the plugin. 

## Setup

The plugin calls the Emitter app with a command similar to this: 

    emitter LoadProfileByEmulator digdug arcade --no-rotate

This will tell Emitter what profile to use based on the currently selected rom name and emulator name, but will not make any changes to dynamic joysticks like the Ultimarc Ultrastik 360 or Servostiks.

*VERY IMPORTANT CONFIGURATION NOTE:* The emulator name is the *configured emulator name* in AttractMode. If you named your emulator "Bob" when you created it in AttractMode, then the emulator name passed to Emitter will be "Bob". So, name it something like "Arcade" (if using RetroPie) or "NES", "Daphne", "Mame" etc. Any uppercase letters in the name will be converted to lowercase, so you at least don't have to worry about that. 

## Modes

The Emitter plugin has 2 modes. Manual and Automatic. 

### Automatic mode 

In Automatic mode, the plugin will wait for a set period of inactivity before calling the Emitter application. The default for the delay upon inactivity is 1 second, but you can edit the plugin settings to change the wait time. 

Once the plugin senses the period of inactivity, it will call the LEDSpicer Emitter app.

### Manual mode

In Manual mode, the plugin requires a key to be configured. When the key is pressed the plugin will call the LEDSpicer Emitter app. 
