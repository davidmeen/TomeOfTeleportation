Tome of Teleportation
---------------------

Tome of Teleportation organises all of your teleporting spells and items into
a single window.  If the item needs to be equipped then it will automatically
be unequipped after you have teleported. The Tome also lets you create macros
to use the spells.  Just type /tele to open the Tome, or click on the icon next
to the minimap.

The buttons in the Tome of Teleportation will each be one of three colours:
* Green: You can cast this spell now.
* Yellow: This spell is on cooldown. The cooldown remaining is displayed on
  the button.
* Red: This item is cast using an item that must be equipped. Click on the
  button once to equip it.  If this doesn't start a cooldown, then click again
  to teleport.  Once the summon is successful or you close the Tome the item
  will be unequipped.

Right clicking the minimap icon will bring up a quick list of your favourite
spells. To add a spell to this list right click on it in the main window.
Equippable items can not be added to this menu.

Adding New Items or Spells
--------------------------

Right click on the main window then select "Customize Spells and More Settings" then press the
"-" button and select Customize Teleporters. On this screen press "Refresh Spell List." This
will let you add spells and items. using the controls at the bottom of the screen. To do this,
you need to go to wowhead.com and get the spell or item id. For example, "Teleport: Moonglade"
is at http://www.wowhead.com/spell=18960/teleport-moonglade which tells you the spell id is 18960.

Customize Spells also lets you change the sort order by hovering over a spell and pressing the Move button.
This will only be available when the sort order is set to Custom. You can also hide or show individual
spells. Using the Show Always option lets you work around bugs in the game that may make it think
spells aren't available.

While the cursor is over a spell press the "Set Zone" button to change how the spell is grouped.
The new zone name will be taken from the Zone box at the bottom of the screen. If this is empty
it will be placed back into its default group.

Advanced Options
----------------

The /tele command can be used for advanced options. The following commands are
available:

/tele move x y
Move the window to the specified location. For example "/tele move 100 200".

/tele reset
Move the window back to the centre of the screen. Useful if the window is moved
off the edge of the screen.

/tele showicon
Show the minimap icon.

/tele hideicon
Show the minimap icon.

------------------

/tele set parameter value
Sets an option without using the UI. Omit the value to reset to the default. Some examples:

/tele set allCovenants true
When random hearthstone is enabled include all covenants, not just the one you belong to. This is off
by default because it has been known to cause problems on some characters.

/tele set background Interface/DialogFrame/UI-DialogBox-Background-Dark
Change the background to black.

/tele setnum backgroundA 0.8
Change the background to 80% opacity.

/tele set buttonWidth 128
Change the width of the buttons.

/tele set buttonHeight 64
Change the height of the buttons.

Credits
-------

By Remeen
Thanks to everybody who has contributed at https://github.com/davidmeen/TomeOfTeleportation