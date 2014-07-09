require "random"
-- var reference
--
-- inv[1] = long beam = 0x1
-- inv[2] = ice beam = 0x2
-- inv[3] = wave beam = 0x4
-- inv[4] = plasma beam = 0x8
-- inv[5] = charge beam = 0x10
-- inv[6] = bombs = 0x80
-- inv[7] = hi jump = 0x1
-- inv[8] = speed booster = 0x2
-- inv[9] = space jump = 0x4
-- inv[10] = screw attack = 0x8
-- inv[11] = varia suit = 0x10
-- inv[12] = gravity suit = 0x20
-- inv[13] = morph ball = 0x40
-- inv[14] = power grip = 0x80
-- inv[15] = missiles
-- inv[16] = super missiles
--
-- SaMStat/BaBStat[1] = previous value (used to calculate difference)
-- SaMStat/BaBStat[2] = current value (used to calculate difference)

-- Item states
-- 3C - Beam and Bomb (BaB) status
-- 3D - BaB activation stats
-- 3E - Suit and Misc (SaM) status
-- 3F - SaM activation status ()
-- 40 - Scanned map status 
-- 41 - Low health beep status (0 off, 1 on)
-- 42 - Extra suit status (0 normal, 1 unknown enabled, 2 zero, 3 1+2)
--
--    3C     3D   3E       3F 40  41  42
--  {  0 ,      0 ,   64 ,      0 , 0  , 0,    0} morph
--  {16 ,      0 ,   64 ,   64 , 0  , 0,    0} charge-get
--  {16 ,    16 ,   64 ,   64 , 0  , 0,    0} charge-use
-- {144 ,   16 ,   64 ,   64 , 0  , 0,    0} bomb-get
-- {144 , 144 ,   64 ,   64 , 0  , 0,    0} bomb-use
-- {152 , 144 ,   64 ,   64 , 0  , 0 ,   0} plasma
-- {152 , 144 , 192 ,   64 , 0  , 0 ,   0} power-get
-- {152 , 144 , 192 , 192 , 0  , 0 ,   0} power-use
-- {154 , 144 , 192 , 192 , 0  , 0 ,   0} ice-get
-- {154 , 146 , 192 , 192 , 0  , 0 ,   0} ice-use
-- {154 , 146 , 192 , 192 , 0  , 0 ,   0} super-get
-- {154 , 146 , 192 , 192 , 0  , 0 ,   0} super-use
-- {154 , 146 , 224 , 192 , 0  , 0 ,   0} gravity
-- {154 , 146 , 225 , 192 , 0  , 0 ,   0} hi-get
-- {154 , 146 , 225 , 193 , 0  , 0 ,   0} hi-use
-- {154 , 146 , 229 , 193 , 0  , 0 ,   0} space
-- {154 , 146 , 231 , 193 , 0  , 0 ,   0} speed-get
-- {154 , 146 , 231 , 195 , 0  , 0 ,   0} speed-use
-- {154 , 17  ,  231 , 128 , 0 , 0 ,    2} zero
-- {155 , 155 , 247 , 247 , 0 , 0 ,    1} all-get
-- {155 , 155 , 247 , 247 , 0 , 0 ,    1} all-use

BaBStat = {0,0}
SaMStat = {0,0}
inv = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}


function d2h (x)
	return string.format("%X", x)
end

function SaM()
	SaMStat[1] = SaMStat[2]
	SaMStat[2] = memory.readbyte(0x0300153E)

	local difference = SaMStat[2] - SaMStat[1] 
	invCalc(difference,"s")
end

function BaB()
	BaBStat[1] = BaBStat[2]
	BaBStat[2] = memory.readbyte(0x0300153C)

	local difference = BaBStat[2] - BaBStat[1]
	invCalc(difference,"b")
end

function missiles()
	inv[15] = 1
	vba.print(inv)
end

function super_missiles()
	inv[16] = 1
	vba.print(inv)
end

function invCalc(d,t)
	local bArr = {0x1, 0x2, 0x4, 0x8, 0x10, 0x80}
	local sArr = {0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80}

	if t == "b" then
		for i=1,6 do
			if d == bArr[i] then
				inv[i] = 1
				vba.print(inv)
			end
		end
	elseif t == "s" then
		for i=1,8 do
			if d == sArr[i] then
				inv[i+6] = 1
				vba.print(inv)
			end
		end
	else
		vba.print("invCalc has encountered an error parsing t.")
	end
end

memory.registerwrite(0x03001532,missiles)
memory.registerwrite(0x03001534,super_missiles)
memory.registerwrite(0x0300153C,BaB)
memory.registerwrite(0x0300153E,SaM)