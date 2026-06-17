# Collision system

Keeping it very simple for now: I want to block the player from moving into a wall. A wall is nothing but a special type of block in the world. 

How's the player represented in the system: an entity with some ID

How's the block represented in the system: As another entity, perhaps?

Then we define a system for checking collision between these two entities. 