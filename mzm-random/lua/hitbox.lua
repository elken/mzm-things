DisplaySamusBox = 1
DisplayProjectileBoxes = 1
DisplayEnemyBoxes = 1

while true do

	local cameraX, cameraY = memory.readshort(0x30013B4), memory.readshort(0x30013B6)
	-- these are the co-ordinates of the top-left of the screen measured in quarter pixels

	if DisplayEnemyBoxes ~= 0 then
		-- This function displays the hitbox of all the enemies in the room
		for i=0,23 do
			local originAddress = 0x30001AC + i*56;
			if memory.readshort(originAddress) ~= 0 then
				local enemyX, enemyY = memory.readshort(originAddress+4), memory.readshort(originAddress + 2) --0x30001B0
				local topleft = {(enemyX + memory.readshortsigned(originAddress + 14) - cameraX)/4, (enemyY + memory.readshortsigned(originAddress + 10) - cameraY)/4}
				local bottomright = {(enemyX + memory.readshortsigned(originAddress + 16) - cameraX)/4, (enemyY + memory.readshortsigned(originAddress + 12) - cameraY)/4}
				gui.box(topleft[1], topleft[2], bottomright[1], bottomright[2], "clear", "#808080")
				-- draw enemy hitbox
			end
		end
	end


	if DisplaySamusBox ~= 0 then
		local samusX, samusY = memory.readshort(0x3001600), memory.readshort(0x3001602)
		local armcannonX, armcannonY = (memory.readshort(0x3000BEE) - cameraX - 2)/4, (memory.readshort(0x3000BEC)-cameraY - 2)/4
		local topleft = {(samusX + memory.readshortsigned(0x30015F6)- cameraX - 2)/4, (samusY + memory.readshortsigned(0x30015F8)- cameraY - 2)/4}
		local bottomright = {(samusX - memory.readshortsigned(0x30015F6) - cameraX - 2)/4, (samusY - cameraY - 2)/4}
		gui.box(topleft[1], topleft[2], bottomright[1], bottomright[2], "clear", "#80FFFF")
		-- draw Samus' hitbox
		gui.box(armcannonX-1, armcannonY-1, armcannonX+1, armcannonY+1, "green")
		-- draw arm cannon point

		local cooldown = memory.readbyte(0x3001418)
		if cooldown ~= 0 then
			gui.text(armcannonX-1, armcannonY-9, cooldown, "green")
		end
		-- show current cooldown time
	end


	-- show projectile hitboxes
	if DisplayProjectileBoxes ~= 0 then
		for i=0,15 do
			local originAddress = 0x3000A2C + i*28;
			if memory.readshort(originAddress) ~= 0 then
				local projectileX, projectileY = memory.readshort(originAddress + 10), memory.readshort(originAddress + 8)
				topleft = {(projectileX + memory.readshortsigned(originAddress + 24) - cameraX - 2)/4, (projectileY + memory.readshortsigned(originAddress + 20) - cameraY - 2)/4}
				local bottomright = {(projectileX + memory.readshortsigned(originAddress + 26) - cameraX - 2)/4, (projectileY + memory.readshortsigned(originAddress + 22) - cameraY - 2)/4}
				gui.box(topleft[1], topleft[2], bottomright[1], bottomright[2], "clear", "#FFFF80")
				-- draw projectile hitbox
			end
		end
	end
	vba.frameadvance()
end