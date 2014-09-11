#include <windows.h>		// Needed for windows stuff
#include <tlhelp32.h>		// "
#include <tchar.h>		// "
#include <cstdio>		// printf and the like
#include <sstream>		// std::stringstream
#include <iostream>		// std::cout, std::endl
#include <vector>		// std::vector
#include <map>			// std::map
#include <cstdint>		// std::uint64_t
#include <bitset>		// std::bitset
#include <iomanip>		// std::setfill, std::setw
#include <utility>		// std::pair


// Fairly obvious offset descriptions
#define BIOS_OFFSET 0x004F4318
#define FRAME_COUNTER_OFFSET 0x004F45F4
#define GAMETIME_OFFSET 0x150
#define INV_OFFSET 0x153C

// Map of the various item names
std::map<int, std::string> message = { 
		{ 0, "Long beam" }, 
		{ 1, "Ice beam" }, 
		{ 2, "Wave beam" }, 
		{ 3, "Plasma beam" }, 
		{ 4, "Charge beam" }, 
		{ 5, "Bombs" }, 
		{ 6, "Hi-jump" }, 
		{ 7, "Speed booster" }, 
		{ 8, "Space jump" }, 
		{ 9, "Screw attack" }, 
		{ 10, "Varia suit" }, 
		{ 11, "Gravity suit" }, 
		{ 12, "Morph ball" }, 
		{ 13, "Power grip" }, 
		{ 14, "Missles" }, 
		{ 15, "Super missles" } };

// Create std::pairs to represent the two types of inv space (Beam and Bombs & Suit and Missles)
// This is due to how both are represented in memory. See http://http://datacrystal.romhacking.net/wiki/Metroid_Zero_Mission:RAM_map
std::pair<int, int> BaBStat, SaMStat;

// Create a bitset to hold the inventory values
// Done as a bitset as its the easiest way to keep track I could think.
// I might make a function to parse this to see what items I have, but I fear it might be hacked & evil
std::bitset<16> inv;

// Endianness can go die in a hole somewhere
unsigned int endian_swap(unsigned const int& x)
{
	return (((x & 0x000000FF) << 24) |
		((x & 0x0000FF00) << 8) |
		((x & 0x00FF0000) >> 8) |
		((x & 0xFF000000) >> 24));
}

// Neat function to format a hex address into bytes for easy viewing.
std::string hexOutput(std::uint64_t x, bool flag)
{
	std::stringstream s;
	s << std::hex << std::setfill('0') <<
		std::setw(2) << ((x >> (flag ? 0x00 : 0x18)) & 0xFF) << " " <<
		std::setw(2) << ((x >> (flag ? 0x08 : 0x10)) & 0xFF) << " " <<
		std::setw(2) << ((x >> (flag ? 0x10 : 0x08)) & 0xFF) << " " <<
		std::setw(2) << ((x >> (flag ? 0x18 : 0x00)) & 0xFF);
	return s.str();
}

// Return a string of the item based on its position in the map
std::string messageOut(int n)
{
	for (auto i : message)
	{
		if (i.first == n)
			return i.second;
		else
			return "Not found.";
	}
	return std::string("Something went awry",GetLastError());
}

// Calculate which item you just picked up from the difference
// I might migrate difference into this at some point...
int invCalc(int d, char t)
{
	std::vector<int> bArr = { 0x1, 0x2, 0x4, 0x8, 0x10, 0x80 };
	std::vector<int> sArr = { 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80 };

	if (t == 'b')
	{
		for (auto i = bArr.begin(); i != bArr.end(); ++i)
		{
			auto position = std::distance(bArr.begin(), i);
			if (d == bArr[position])
			{
				inv[position] = 1;
				std::cout << messageOut(position);
			}
		}
	}
	else if (t == 's')
	{
		for (auto i = sArr.begin(); i != sArr.end(); ++i)
		{
			auto position = std::distance(sArr.begin(), i);
			if (d == sArr[position])
			{
				inv[position+6] = 1;
				std::cout << messageOut(position+6);
			}
		}
	}
	else
	{
		std::cout << "Something went awry. (" << GetLastError() << ")";
		return 1;
	}
	return 0;
}

// Neat-ish function to format time into a nice string
std::string parseTime(std::uint64_t x)
{
	std::stringstream s;
	s << std::setfill('0') << std::setw(2) << (x & 0xFF) << ":" << ((x >> 8) & 0xFF) << ":" << ((x >> 16) & 0xFF) << "";
	return s.str();
}


// TODO: Comment main()
int main()
{
	// Define the variables (Messy atm, will move all here at some point)
	DWORD pid;
	int invAddress;
	int invValue;
	int curTime;

	SIZE_T bytesRead;
	DWORD baseAddress;

	// Find the window handle based on the title
	HWND window = FindWindow(NULL, _T("VBA-RR v24 svn480"));

	if (window != 0)
	{
		// I honestly don't know what this stuff does but it works so fuck it
		GetWindowThreadProcessId(window, &pid);
		HANDLE phandle = OpenProcess(PROCESS_VM_READ, 0, pid);
		if (!phandle)
			std::cout << "Could not get handle! (" << GetLastError() << ")" << std::endl;
		else
			std::cout << "Handle obtained, PID: " << pid << std::endl << std::endl;

		// Wiccan magic to find the base address
		HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pid);
		MODULEENTRY32 module;
		module.dwSize = sizeof(MODULEENTRY32);
		Module32First(snapshot, &module);
		baseAddress = (DWORD)module.modBaseAddr;

		// Inv offsets (BaB get, BaB use, SaM get, SaM use)
		printf("\t\t\t\t\t3C 3D 3E 3F\n");

		// Memory magic
		if (ReadProcessMemory(phandle, (void*)(baseAddress + FRAME_COUNTER_OFFSET), &invAddress, 4, &bytesRead))
		{
			if (ReadProcessMemory(phandle, (LPCVOID)((DWORD)invAddress + INV_OFFSET), &invValue, 4, &bytesRead))
			{
				SaMStat.first = endian_swap(invValue);

				std::cout << "Value of GBA 0x0300153C: \t\t" << hexOutput(SaMStat.first, false) << std::endl;
			}
			else
			{
				std::cout << "ROM not loaded. (" << GetLastError() << ")" << std::endl;

				if (bytesRead != 0)
					std::cout << "Bytes read: " << bytesRead << std::endl;
			}
			do
			{
				ReadProcessMemory(phandle, (LPCVOID)((DWORD)invAddress + INV_OFFSET), &invValue, 4, &bytesRead);
				SaMStat.second = endian_swap(invValue);
			//} while (SaMStat.old == SaMStat.cur);
			} while (false);

			ReadProcessMemory(phandle, (LPCVOID)((DWORD)invAddress + GAMETIME_OFFSET), &curTime, 4, &bytesRead);
			std::cout << parseTime(curTime) << std::endl;

			std::cout << "SaMStat.cur: \t\t\t\t" << (hexOutput(SaMStat.first, false)) << std::endl << "SaMStat.old: \t\t\t\t" << hexOutput(SaMStat.first, false) << std::endl;
			if (SaMStat.first != SaMStat.second)
			{
				unsigned int difference = (SaMStat.second >> 8) - (SaMStat.first >> 8);
				ReadProcessMemory(phandle, (LPCVOID)((DWORD)invAddress + GAMETIME_OFFSET), &curTime, 4, &bytesRead);
				std::cout << std::hex << curTime << std::endl;
				invCalc(difference, 's');
			}

		}
		else
		{
			std::cout << "Failed to load offset. (" << GetLastError() << ")" << std::endl;

			if (bytesRead != 0)
				std::cout << "Bytes read: " << bytesRead << std::endl;
		}
	}
	else
	{
		std::cout << "Unable to find window, try again. (" << GetLastError() << ")" << std::endl;
		return 1;
	}
	return 0;
}
