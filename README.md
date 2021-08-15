# CORE
Originally a rewrite of my Monster Events library which branched out into further ideas, CORE is a small collection of libraries intended to make creating and using libraries in CYF mods easier.

CORE includes a system for listener-based events, a lightweight userdata wrapper, an alternate wave loader which allows for more communication between waves and the encounter script, and a reworked custom state system which allows you to define your own states, alongside a handful of smaller tweaks to Lua modules and CYF's behavior.

## How to Use This Library
1) Merge the Lua folder with your Mod's Lua folder.
2) Place `_ENV = require "CORE/init"` at the top of your Encounter and Monster files.
3) Set up any special variables as desired.

You can also move the CORE folder into `Libraries/` if desired, but `blank_wave.lua` must be in your mod's Wave folder.
Alternatively, you can use the provided "CORE Skeleton" mod as a jumping off point, just like you would Encounter Skeleton.

### Does this work with ____ out of the box?
I have no idea. Give it a try and find out!

### Are you going to add more features later?
Probably not; I intend to move on to other projects, but I may fix important bugs if any are brought to my attention.

### How can I get help if I don't understand how to use this?
Check the documentation. I've tried to make it as concise and understandable as possible. 
