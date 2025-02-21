

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 81) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 43) then
					if (Enum <= 21) then
						if (Enum <= 10) then
							if (Enum <= 4) then
								if (Enum <= 1) then
									if (Enum > 0) then
										if (Inst[2] <= Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									elseif (Stk[Inst[2]] ~= Inst[4]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum <= 2) then
									local A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								elseif (Enum == 3) then
									local A = Inst[2];
									local Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									local Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								else
									local B = Inst[3];
									local K = Stk[B];
									for Idx = B + 1, Inst[4] do
										K = K .. Stk[Idx];
									end
									Stk[Inst[2]] = K;
								end
							elseif (Enum <= 7) then
								if (Enum <= 5) then
									local A = Inst[2];
									local Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									local Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								elseif (Enum > 6) then
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
								elseif (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum <= 8) then
								local A = Inst[2];
								Stk[A](Stk[A + 1]);
							elseif (Enum == 9) then
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A]());
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 15) then
							if (Enum <= 12) then
								if (Enum > 11) then
									if (Stk[Inst[2]] ~= Inst[4]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
							elseif (Enum <= 13) then
								if (Stk[Inst[2]] < Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum > 14) then
								Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A]());
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 18) then
							if (Enum <= 16) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							elseif (Enum > 17) then
								Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
							else
								Env[Inst[3]] = Stk[Inst[2]];
							end
						elseif (Enum <= 19) then
							Stk[Inst[2]] = Stk[Inst[3]] / Inst[4];
						elseif (Enum == 20) then
							Stk[Inst[2]][Inst[3]] = Inst[4];
						else
							Stk[Inst[2]] = Stk[Inst[3]] * Inst[4];
						end
					elseif (Enum <= 32) then
						if (Enum <= 26) then
							if (Enum <= 23) then
								if (Enum == 22) then
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								else
									local A = Inst[2];
									do
										return Unpack(Stk, A, A + Inst[3]);
									end
								end
							elseif (Enum <= 24) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							elseif (Enum > 25) then
								Stk[Inst[2]] = Inst[3] ~= 0;
							else
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum <= 29) then
							if (Enum <= 27) then
								local NewProto = Proto[Inst[3]];
								local NewUvals;
								local Indexes = {};
								NewUvals = Setmetatable({}, {__index=function(_, Key)
									local Val = Indexes[Key];
									return Val[1][Val[2]];
								end,__newindex=function(_, Key, Value)
									local Val = Indexes[Key];
									Val[1][Val[2]] = Value;
								end});
								for Idx = 1, Inst[4] do
									VIP = VIP + 1;
									local Mvm = Instr[VIP];
									if (Mvm[1] == 64) then
										Indexes[Idx - 1] = {Stk,Mvm[3]};
									else
										Indexes[Idx - 1] = {Upvalues,Mvm[3]};
									end
									Lupvals[#Lupvals + 1] = Indexes;
								end
								Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
							elseif (Enum > 28) then
								VIP = Inst[3];
							else
								local A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
							end
						elseif (Enum <= 30) then
							Stk[Inst[2]][Inst[3]] = Inst[4];
						elseif (Enum > 31) then
							if not Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
						end
					elseif (Enum <= 37) then
						if (Enum <= 34) then
							if (Enum > 33) then
								Stk[Inst[2]] = {};
							else
								Env[Inst[3]] = Stk[Inst[2]];
							end
						elseif (Enum <= 35) then
							local A = Inst[2];
							Stk[A](Stk[A + 1]);
						elseif (Enum == 36) then
							local A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						end
					elseif (Enum <= 40) then
						if (Enum <= 38) then
							local B = Inst[3];
							local K = Stk[B];
							for Idx = B + 1, Inst[4] do
								K = K .. Stk[Idx];
							end
							Stk[Inst[2]] = K;
						elseif (Enum == 39) then
							if (Stk[Inst[2]] == Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						end
					elseif (Enum <= 41) then
						Stk[Inst[2]] = Stk[Inst[3]] % Inst[4];
					elseif (Enum > 42) then
						Stk[Inst[2]] = Inst[3];
					else
						do
							return Stk[Inst[2]];
						end
					end
				elseif (Enum <= 65) then
					if (Enum <= 54) then
						if (Enum <= 48) then
							if (Enum <= 45) then
								if (Enum == 44) then
									local A = Inst[2];
									local Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									local Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								else
									local A = Inst[2];
									local B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
								end
							elseif (Enum <= 46) then
								Stk[Inst[2]] = Stk[Inst[3]] * Inst[4];
							elseif (Enum > 47) then
								Stk[Inst[2]] = Inst[3];
							else
								VIP = Inst[3];
							end
						elseif (Enum <= 51) then
							if (Enum <= 49) then
								if not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 50) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							else
								Stk[Inst[2]] = Upvalues[Inst[3]];
							end
						elseif (Enum <= 52) then
							local A = Inst[2];
							local C = Inst[4];
							local CB = A + 2;
							local Result = {Stk[A](Stk[A + 1], Stk[CB])};
							for Idx = 1, C do
								Stk[CB + Idx] = Result[Idx];
							end
							local R = Result[1];
							if R then
								Stk[CB] = R;
								VIP = Inst[3];
							else
								VIP = VIP + 1;
							end
						elseif (Enum == 53) then
							local A = Inst[2];
							Stk[A] = Stk[A]();
						else
							local A = Inst[2];
							local C = Inst[4];
							local CB = A + 2;
							local Result = {Stk[A](Stk[A + 1], Stk[CB])};
							for Idx = 1, C do
								Stk[CB + Idx] = Result[Idx];
							end
							local R = Result[1];
							if R then
								Stk[CB] = R;
								VIP = Inst[3];
							else
								VIP = VIP + 1;
							end
						end
					elseif (Enum <= 59) then
						if (Enum <= 56) then
							if (Enum > 55) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
							else
								local A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							end
						elseif (Enum <= 57) then
							local A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum == 58) then
							do
								return Stk[Inst[2]];
							end
						else
							Stk[Inst[2]] = Env[Inst[3]];
						end
					elseif (Enum <= 62) then
						if (Enum <= 60) then
							Stk[Inst[2]] = Stk[Inst[3]] % Inst[4];
						elseif (Enum == 61) then
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						end
					elseif (Enum <= 63) then
						if (Inst[2] < Stk[Inst[4]]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum == 64) then
						Stk[Inst[2]] = Stk[Inst[3]];
					elseif (Stk[Inst[2]] == Stk[Inst[4]]) then
						VIP = VIP + 1;
					else
						VIP = Inst[3];
					end
				elseif (Enum <= 76) then
					if (Enum <= 70) then
						if (Enum <= 67) then
							if (Enum == 66) then
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							else
								Stk[Inst[2]] = Env[Inst[3]];
							end
						elseif (Enum <= 68) then
							local A = Inst[2];
							local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							local Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
						elseif (Enum > 69) then
							Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
						else
							Stk[Inst[2]] = Inst[3] ~= 0;
						end
					elseif (Enum <= 73) then
						if (Enum <= 71) then
							if (Inst[2] <= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Enum == 72) then
							Stk[Inst[2]] = Stk[Inst[3]];
						else
							Stk[Inst[2]] = Stk[Inst[3]] / Inst[4];
						end
					elseif (Enum <= 74) then
						if (Stk[Inst[2]] == Inst[4]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum > 75) then
						Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
					else
						local A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Top));
					end
				elseif (Enum <= 82) then
					if (Enum <= 79) then
						if (Enum <= 77) then
							local NewProto = Proto[Inst[3]];
							local NewUvals;
							local Indexes = {};
							NewUvals = Setmetatable({}, {__index=function(_, Key)
								local Val = Indexes[Key];
								return Val[1][Val[2]];
							end,__newindex=function(_, Key, Value)
								local Val = Indexes[Key];
								Val[1][Val[2]] = Value;
							end});
							for Idx = 1, Inst[4] do
								VIP = VIP + 1;
								local Mvm = Instr[VIP];
								if (Mvm[1] == 64) then
									Indexes[Idx - 1] = {Stk,Mvm[3]};
								else
									Indexes[Idx - 1] = {Upvalues,Mvm[3]};
								end
								Lupvals[#Lupvals + 1] = Indexes;
							end
							Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
						elseif (Enum == 78) then
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						else
							local A = Inst[2];
							Stk[A] = Stk[A]();
						end
					elseif (Enum <= 80) then
						do
							return;
						end
					elseif (Enum > 81) then
						Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
					elseif (Stk[Inst[2]] < Stk[Inst[4]]) then
						VIP = VIP + 1;
					else
						VIP = Inst[3];
					end
				elseif (Enum <= 85) then
					if (Enum <= 83) then
						Stk[Inst[2]] = {};
					elseif (Enum == 84) then
						for Idx = Inst[2], Inst[3] do
							Stk[Idx] = nil;
						end
					else
						do
							return;
						end
					end
				elseif (Enum <= 86) then
					if (Inst[2] < Stk[Inst[4]]) then
						VIP = VIP + 1;
					else
						VIP = Inst[3];
					end
				elseif (Enum > 87) then
					Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
				elseif Stk[Inst[2]] then
					VIP = VIP + 1;
				else
					VIP = Inst[3];
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!1B3Q0003063Q00676574696E760359022Q007365745F62675F636F6C6F727C302C302C302C322Q300A7365745F626F726465725F636F6C6F727C302C302C302C3235300A7365745F64656661756C745F636F6C6F727C60300A612Q645F6C6162656C5F776974685F69636F6E7C6269677C69486B617A20436F2Q6D756E6974792048656C7065727C6C6566747C37312Q387C0A612Q645F736D612Q6C746578747C682Q7470733A2Q2F6473632E2Q672F69686B617A7C6C6566747C0A612Q645F7370616365727C736D612Q6C7C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C576861742773204E65773F205041544348203A205B603432312F30322F323032352Q605D7C6C6566747C363132347C0A612Q645F7370616365727C736D612Q6C7C0A612Q645F736D612Q6C746578747C5B2B5D20412Q6465642053686F727463757420436F6E76657274204469616D6F6E64204C6F636B7320746F20426C75652047656D204C6F636B732069662075207772656E63682074656C6570686F6E652E2060327468616E6B7320746F205B534154414E4D4F4E415243485D2Q607C6C6566747C0A612Q645F736D612Q6C746578747C5B2B5D20412Q646564204C6F677370696E20617420706C61796572206E616D657C6C6566747C0A612Q645F7370616365727C736D612Q6C7C0A612Q645F736D612Q6C746578747C603243726561746F722Q60203A2060314070616E676572616E737C6C6566747C0A612Q645F7370616365727C736D612Q6C7C0A656E645F6469616C6F677C67617A652Q74657C48412Q505920534352495054494E47212Q7C0A612Q645F717569636B5F657869747C0A03E8022Q007365745F62675F636F6C6F727C302C302C302C322Q300A7365745F626F726465725F636F6C6F727C302C302C302C3235300A7365745F64656661756C745F636F6C6F727C60300A612Q645F6C6162656C5F776974685F69636F6E7C6269677C4C69737420436F2Q6D616E6473203A207C6C6566747C33327C0A612Q645F736D612Q6C746578747C6034682Q7470733A2Q2F6473632E2Q672F69686B617A7C6C6566747C0A612Q645F7370616365727C736D612Q6C7C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F776C207B636F756E747D5D2044726F2Q70696E6720574C537C6C6566747C3234327C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F646C207B636F756E747D5D2044726F2Q70696E6720444C537C6C6566747C313739367C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F62676C207B636F756E747D5D2044726F2Q70696E672042474C537C6C6566747C37312Q387C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F6162736F207B636F756E747D5D2044726F2Q70696E67204162736F6C757465204C6F636B737C6C6566747C31362Q37307C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F7764207B636F756E747D5D20576974647261772042474C206F6E207468652062616E6B737C6C6566747C363239307C0A612Q645F6C6162656C5F776974685F69636F6E7C736D612Q6C7C5B2F6465706F207B636F756E747D5D204465706F7369742042474C20746F207468652062616E6B737C6C6566747C363239307C0A612Q645F7370616365727C736D612Q6C7C0A612Q645F736D612Q6C746578747C603243726561746F722Q60203A2060314070616E676572616E737C6C6566747C0A612Q645F7370616365727C736D612Q6C7C0A656E645F6469616C6F677C67617A652Q74657C48412Q505920534352495054494E47212Q7C0A612Q645F717569636B5F657869747C0A03043Q0064726F7003043Q006C6F677303063Q0067657442676C030B3Q006C6F636B62616C616E636503053Q006364726F7003053Q0062616E6B73030A3Q00676574706C617965727303073Q00636D646C697374030B3Q0076617269616E746C697374030B3Q0053656E645661726C697374028Q00030F3Q004F6E4469616C6F6752657175657374026Q00F03F03053Q00