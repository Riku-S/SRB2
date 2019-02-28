// Connect 5 by Ors

local function LClick(p)
	p.lclick = true // Player just clicked
end

COM_AddCommand("lclick", LClick, 0)

local maxgames = 8

local function InitPlayer(p)
	p.inited = true
	p.mousex = 160*FRACUNIT
	p.mousey = 100*FRACUNIT
	p.lclick = false
	p.custom1down = false
	p.jumpdown = false
	p.ingame = false
	p.inmenu = true
	p.drawing = false
	p.justinited = true // Player is initialized this or the previous tic
	COM_BufInsertText(p, "bind mouse1 lclick")
	if (p == server)
		p.games = {}
		for i = 0, maxgames - 1
			p.games[i] = {}
			p.games[i][0] = false // Active
			p.games[i][1] = nil // X-player
			p.games[i][2] = nil // O-Player
			p.games[i][3] = {} // Board
			for j = 0, 17
				p.games[i][3][j] = {}
				for k = 0, 17
					p.games[i][3][j][k] = 0 // Empty
				end
			end
			p.games[i][4] = 1 // X's turn
		end
	end
end

local function Toggle(a)
	if not (a)
		a = true
	else
		a = false
	end
	return a
end

// Check if the mouse is on a specified area
local function MouseOn(mxf, myf, x,y,w,h)
	local mx = mxf/FRACUNIT
	local my = myf/FRACUNIT
	if(mx >= x and mx < x + w and my >= y and my < y + h)
		return true
	else
		return false
	end
end

local function StartGame(game)
	game[0] = true// Game is active
	// Reset the players
	game[1].drawing = false
	game[2].drawing = false
	// Clear the grid
	for j = 0, 17
		for k = 0, 17
			game[3][j][k] = 0 // Empty
		end
	end
	game[4] = 1 // X's turn
end

local function EndGame(game)
	game[0] = false // Game is not active
	for player in players.iterate
		if(player.game == game)
			player.game = nil
			player.inmenu = true
		end
	end
	game[1] = nil
	game[2] = nil
	game[4] = 1
end

local function CheckWin(x, y, game)
	local mark = game[3][x][y]
	// Player wins with 5 in a row
	local streak = 0
	// Horizontal win
	for i = x-4,x+4
		if (i >= 0 and i < 18)
			if(game[3][i][y] == mark)
				streak = $1 + 1
				if(streak >= 5)
					return true
				end
			else
				streak = 0
			end
		end
	end
	// Vertical win
	for i = y-4,y+4
		if (i >= 0 and i < 18)
			if(game[3][x][i] == mark)
				streak = $1 + 1
				if(streak >= 5)
					return true
				end
			else
				streak = 0
			end
		end
	end
	// Diagonal (positive slope)
	for i = -4,4
		if (x+i >= 0 and x+i < 18 and y+i >= 0 and y+i < 18)
			if(game[3][x+i][y+i] == mark)
				streak = $1 + 1
				if(streak >= 5)
					return true
				end
			else
				streak = 0
			end
		end
	end
	// Diagonal (negative slope)
	for i = -4,4
		if (x-i >= 0 and x-i < 18 and y+i >= 0 and y+i < 18)
			if(game[3][x-i][y+i] == mark)
				streak = $1 + 1
				if(streak >= 5)
					return true
				end
			else
				streak = 0
			end
		end
	end
	return false
end

addHook("ThinkFrame", function()
	// Clear the challenge from une
	if(server.inited)
		for i = 0, maxgames - 1
			if (server.games[i][1] != nil) and (not server.games[i][1].valid)
				server.games[i][1] = nil
			end
			if (server.games[i][2] != nil) and (not server.games[i][2].valid)
				server.games[i][2] = nil
			end
		end
	end
	
	for p in players.iterate
		if(p.jointime < 35)
			// Nothing, sync
		elseif not(p.inited)
			InitPlayer(p)
			// Nothing more, sync
		else
			if not (p.cmd.buttons & BT_CUSTOM1)
				p.custom1down = false
			end
			if (p.cmd.buttons & BT_CUSTOM1 and not p.custom1down)
				p.custom1down = true
				p.ingame = Toggle(p.ingame)
				if(p.ingame == true)
					S_ChangeMusic(24, true, p)
				else
					S_ChangeMusic(mapmusname, true, p)
				end
			end
			if not (p.cmd.buttons & BT_JUMP)
				p.jumpdown = false
			end
			if (p.cmd.buttons & BT_JUMP and not p.jumpdown)
				p.jumpdown = true
				p.lclick = true
			end
			if not (p.ingame)
				// Nothing
			else
				// We don't want player to jump
				if not (p.pflags & PF_JUMPSTASIS)
					p.pflags = $1 + PF_JUMPSTASIS
				end
				
				if (p.inmenu)
					if(p.lclick)
						for i = 0, 7
							//Player clicked scatter icon
							if(MouseOn(p.mousex, p.mousey, 0,16*i+16,16,16))
								if server.games[i][1] == nil // The player is in one game a time
									for i = 0, maxgames - 1
										if (server.games[i][1] == p)
											server.games[i][1] = nil
										end
										if (server.games[i][2] == p)
											server.games[i][2] = nil
										end
									end
									server.games[i][1] = p // Occupy the game
									p.game = server.games[i]
									CONS_Printf(p, "You play as Scatter")
								else
									if (server.games[i][1] == p)
										server.games[i][1] = nil
										p.game = nil
									else
										CONS_Printf(p, "Scatter occupied")
									end
								end
							end
							if(MouseOn(p.mousex, p.mousey, 288,16*i+16,16,16))
								if server.games[i][2] == nil // The player is in one game a time
									for i = 0, maxgames - 1
										if (server.games[i][1] == p)
											server.games[i][1] = nil
										end
										if (server.games[i][2] == p)
											server.games[i][2] = nil
										end
									end
									server.games[i][2] = p // Occupy the game
									p.game = server.games[i]
									CONS_Printf(p, "You play as Ring")
								else
									if (server.games[i][2] == p)
										server.games[i][2] = nil
										p.game = nil
									else
										CONS_Printf(p, "Ring occupied")
									end
								end
							end
							// Spectate
							if(MouseOn(p.mousex, p.mousey, 304,16*i+16,16,16))
								p.game = nil
								if (server.games[i][1] == p)
									server.games[i][1] = nil
								elseif (server.games[i][2] == p)
									server.games[i][2] = nil
								end
								CONS_Printf(p, "You took spectator mode")
							end
						end
					end
					if(p.game != nil)
						for i = 0, 7
							if(server.games[i][1] != nil and server.games[i][2] != nil)
								if (server.games[i][1].inmenu and server.games[i][2].inmenu)
									StartGame(server.games[i])
								end
								p.inmenu = false // The game is going on
							end
						end
					end
				else
					if(p.game == nil)
						p.inmenu = true
					elseif(p.game[1] == nil or p.game[2] == nil)
						EndGame(p.game)
					else
						if(p.lclick)
							local squarex = p.mousex/FRACUNIT/8-11
							local squarey = p.mousey/FRACUNIT/8-2
							local game = p.game
							if(squarex >= 0 and squarex < 18 and squarey >= 0 and squarey < 18)
								// X's turn and player is X
								if(p == p.game[1] and p.game[4] == 1)
									if(p.game[3][squarex][squarey] == 0)
										p.game[3][squarex][squarey] = 1
										p.game[4] = 2 // O's turn
										for player in players.iterate
											if(player.game == game)
												S_StartSound(nil,90,player)
											end
										end
										if (CheckWin(squarex, squarey, p.game))
											print(p.game[1].name.." won "..p.game[2].name.."!")
											EndGame(p.game)
										end
									end
								// O's turn and player is O
								elseif(p == p.game[2] and p.game[4] == 2)
									if(p.game[3][squarex][squarey] == 0)
										p.game[3][squarex][squarey] = 2
										p.game[4] = 1 // X's turn
										for player in players.iterate
											if(player.game == game)
												S_StartSound(nil,90,player)
											end
										end
										if (CheckWin(squarex, squarey, p.game))
											print(p.game[2].name.." won "..p.game[1].name.."!")
											EndGame(p.game)
										end
									end
								end
							end
							// Resign/Exit
							if(MouseOn(p.mousex, p.mousey, 0,144,88,16))
								if(p == p.game[1] or p == p.game[2])
									if(p == p.game[1])
										print(p.game[2].name.." won "..p.game[1].name.."!")
									end
									if(p == p.game[2])
										print(p.game[1].name.." won "..p.game[2].name.."!")
									end
									EndGame(p.game)
								else
									p.inmenu = true
									p.game = nil
								end
								//Draw
							elseif(MouseOn(p.mousex, p.mousey, 232,144,88,16))
								p.drawing = true
								if(p.game[1].drawing and p.game[2].drawing)
									print(p.game[1].name.." drawed with "..p.game[2].name.."!")
									EndGame(p.game)
								end
							end
						end
					end
				end
				
				// Move the mouse
				local mousespeed = FRACUNIT/150 // The default mousespeed
				
				// Let move controls move the cursor as an alternative way
				if not (p.justinited)
					p.aiming = $1 + p.cmd.forwardmove*FRACUNIT*5
					p.mo.angle = $1 - p.cmd.sidemove*FRACUNIT*5
				end
				
				p.mousex = $1 + FixedMul(-p.mo.angle + FRACUNIT,mousespeed)
				p.mousey = $1 + FixedMul(-p.aiming,mousespeed)
				
				if(p.mousex < 0)
					p.mousex = 0
				elseif (p.mousex >= 320*FRACUNIT)
					p.mousex = 319*FRACUNIT
				end
				if(p.mousey < 0)
					p.mousey = 0
				elseif (p.mousey >= 200*FRACUNIT)
					p.mousey = 199*FRACUNIT
				end
				if not (p.justinited)
					p.mo.angle = 0
					p.aiming = 0
				end
				p.justinited = false
				p.lclick = false // Let's not keep clicking
				
				p.mo.momx = 0
				p.mo.momy = 0
			end
		end
	end
end)


hud.add(function(v, p)
	if not (p.inited)
		return
	end
	if not (p.ingame)
		v.drawString(160, 0, "Press Custom 1 to enter rOS", V_ALLOWLOWERCASE|V_YELLOWMAP|V_TRANSLUCENT, "center")
		return
	end
	//Bg
	v.drawFill(0,0,320,200,31)
	v.drawString(160, 0, "Press Custom 1 to exit rOS", V_ALLOWLOWERCASE|V_YELLOWMAP|V_TRANSLUCENT, "center")

	// Buttons
	if (p.inmenu)
		v.drawString(160, 168, "Press a scatter or ring to play!", V_ALLOWLOWERCASE, "center")
		v.drawString(160, 184, "Mouse to move cursor. Left mb to select", V_ALLOWLOWERCASE, "center")
		// Draw the games
		for i = 0, maxgames - 1
			// Draw the buttons' filters
			// Play with X
			if(MouseOn(p.mousex, p.mousey, 0,16*i+16,16,16))
				v.drawFill(0,16*i+16,16,16,16)
			end
			// Play with O
			if(MouseOn(p.mousex, p.mousey, 288,16*i+16,16,16))
				v.drawFill(288,16*i+16,16,16,16)
			end
			// Spectating button
			if(MouseOn(p.mousex, p.mousey, 304,16*i+16,16,16))
				v.drawFill(304,16*i+16,16,16,16)
			end
			v.drawFill(0,16*i+16,320,1,120) // Draw the white lines
			
			// Draw the icons for the buttons
			v.drawScaled(296*FRACUNIT, (16*i+31)*FRACUNIT, FRACUNIT/2, v.cachePatch("RINGA0"))
			v.drawScaled(8*FRACUNIT, (16*i+31)*FRACUNIT, FRACUNIT/2, v.cachePatch("RNGSA0"))
			v.drawString(308, 16*i+16, "F")
			v.drawString(304, 16*i+24, "12")
			
			//Players
			if(server.games[i][1] != nil)
				v.drawString(20,16*i+20, string.sub(server.games[i][1].name,0,16))
			end
			if(server.games[i][2] != nil)
				v.drawString(156,16*i+20, string.sub(server.games[i][2].name,0,16))
			end
		end
		// More white lines
		v.drawFill(15,16,1,128,120)
		v.drawFill(151,16,1,128,120)
		v.drawFill(287,16,1,128,120)
		v.drawFill(303,16,1,128,120)
	else
		v.drawString(160, 168, "Get 5 in a row horizontally,", V_ALLOWLOWERCASE, "center")
		v.drawString(160, 184, "vertically or diagonally!", V_ALLOWLOWERCASE, "center")
		local squarex = p.mousex/FRACUNIT/8-11
		local squarey = p.mousey/FRACUNIT/8-2
		if(squarex >= 0 and squarex < 18 and squarey >= 0 and squarey < 18)
			local drawx = squarex*8+88
			local drawy = squarey*8+16
			v.drawFill(drawx, drawy, 8, 8, 16)
		end
		// Draw the grid
		for i = 0, 17
			v.drawFill(88,i*8+16,144,1,16)
		end
		for i = 0, 17
			v.drawFill(i*8+88,16,1,144,16)
		end
		for i = 0, 17
			v.drawFill(88,i*8+23,144,1,8)
		end
		for i = 0, 17
			v.drawFill(i*8+95,16,1,144,8)
		end
		
		// Draw the players
		v.drawString(4, 24, string.sub(p.game[1].name,0,10))
		if(p.game[1].mo.valid)
			v.draw(4,40,v.cachePatch(skins[p.game[1].mo.skin].face),0,v.getColormap(p.game[1].mo.skin, p.game[1].mo.color))
		end
		v.draw(68,70,v.cachePatch("RNGSA0"))
		v.drawString(236, 24, string.sub(p.game[2].name,0,10))
		if(p.game[2].mo.valid)
			v.draw(236,40,v.cachePatch(skins[p.game[2].mo.skin].face),0,v.getColormap(p.game[2].mo.skin, p.game[2].mo.color))
		end
		v.draw(300,70,v.cachePatch("RINGA0"))
		
		// Resign/Exit
		if(MouseOn(p.mousex, p.mousey, 0,144,88,16))
			v.drawFill(0,144,88,16,16)
		end
		v.drawFill(0,144,88,1,120)
		if(p == p.game[1] or p == p.game[2])
			v.drawString(4,148,"Resign")
		else
			v.drawString(4,148,"Exit")
		end
		// Draw
		// X is drawing
		if (p.game[1].drawing)
			v.drawFill(232,144,88,16,199)
		end
		// O is drawing
		if(p.game[2].drawing)
			v.drawFill(232,144,88,16,108)
		end
		
		if(MouseOn(p.mousex, p.mousey, 232,144,88,16))
			v.drawFill(232,144,88,16,16)
		end
		v.drawFill(232,144,88,1,120)
		v.drawString(236,148,"Draw")
		// Draw Xs and Os
		for i = 0, 17
			for j = 0, 17
				if(p.game[3][i][j] == 1)
					v.drawScaled(92*FRACUNIT+8*i*FRACUNIT, 23*FRACUNIT+8*j*FRACUNIT, FRACUNIT/4, v.cachePatch("RNGSA0"))
				elseif(p.game[3][i][j] == 2)
					v.drawScaled(92*FRACUNIT+8*i*FRACUNIT, 23*FRACUNIT+8*j*FRACUNIT, FRACUNIT/4, v.cachePatch("RINGA0"))
				end
			end
		end
	end
	// Cursor
	v.drawScaled(p.mousex, p.mousey, FRACUNIT/2, v.cachePatch(skins[p.mo.skin].face),0,v.getColormap(p.mo.skin, p.mo.color))
end, "game")