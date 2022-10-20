
- basic setup skeleton 
- start with raw batteries (type etc.) (done)
	- new require function
	- new type/rawtype
	- table.deepcopy
	- table.find
	- json.indent
- rework/look back over event system (done)
	- more modular way of protecting events from being overwritten [on hold]
- revamp state system (done)
	- ~~new states: intro, enemydialoguepost~~ (more clunky than it's worth)
- pull in monster wrapping (mostly complete)
- pull in/revamp wave wrapping
	- make sure both have ways to add to the default sandbox
		- event that returns the sandbox as it's being created?
		- way to create functions which are locked into the new sandbox?
		- ~~lock in functions assigned to the sandbox to begin with?~~ (bad idea)
	- ensure text objects and onhit are taken care of properly

- ENSURE EVENTS/BATTERIES INCLUDED IN SANDBOXES

- rework/rewrite/update documentation

_____
--license crediting

--table.deepcopy
--[[
	This function comes from a stackoverflow answer by islet8.
	Slightly modified to respect the new type/rawtype distinction.
	https://stackoverflow.com/a/16077650
	https://creativecommons.org/licenses/by-sa/3.0/
--]]

