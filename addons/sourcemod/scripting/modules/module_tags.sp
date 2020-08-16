/*
 * SourceMod Entity Projects
 * by: Entity
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

ConVar gH_Cvar_Tomori_Tags_Enabled;					//Enable or disable Tags Module (0 - Disable, 1 - Enabled)

char gH_Cvar_Tomori_Tags_Flag[PLATFORM_MAX_PATH];
char gH_Cvar_Tomori_Tags_SteamID[PLATFORM_MAX_PATH];

Handle gShadow_Tomori_Client_ForceClan[MAXPLAYERS+1] = null;
char gShadow_Tomori_Client_Tag[MAXPLAYERS+1][64];
char gShadow_Tomori_Client_CTag[MAXPLAYERS+1][64];
char gShadow_Tomori_Client_TColor[MAXPLAYERS+1][64];
char gShadow_Tomori_Client_NColor[MAXPLAYERS+1][64];
char gShadow_Tomori_Client_CColor[MAXPLAYERS+1][64];

bool gShadow_Tomori_Client_Custom[MAXPLAYERS+1] = false;

bool gShadow_Tomori_Client_RainbowT[MAXPLAYERS+1] = false;
bool gShadow_Tomori_Client_RainbowC[MAXPLAYERS+1] = false;
bool gShadow_Tomori_Client_RainbowN[MAXPLAYERS+1] = false;

bool gShadow_Tomori_Client_RandomT[MAXPLAYERS+1] = false;
bool gShadow_Tomori_Client_RandomC[MAXPLAYERS+1] = false;
bool gShadow_Tomori_Client_RandomN[MAXPLAYERS+1] = false;

public void Tags_OnPluginStart()
{
	BuildPath(Path_SM, gH_Cvar_Tomori_Tags_Flag, sizeof(gH_Cvar_Tomori_Tags_Flag), "configs/Tomori/tags_flags.txt");
	BuildPath(Path_SM, gH_Cvar_Tomori_Tags_SteamID, sizeof(gH_Cvar_Tomori_Tags_SteamID), "configs/Tomori/tags_steamid.txt");

	AutoExecConfig_SetFile("Module_Tags", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Tags_Enabled = AutoExecConfig_CreateConVar("tomori_tags_enabled", "1", "Enable or disable Tags Module (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue || !AllowRun)
		gH_Cvar_Tomori_Tags_Enabled.SetInt(0, true, false);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void Tags_OnClientDisconnect(int client)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue && AllowRun) ResetClientID(client);
}

public void Tags_OnClientPostAdminCheck(int client)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue && AllowRun)
	{
		ResetClientID(client);
		
		if (!IsClientInSteamList(client))
			GetUserTagByFlag(client);
	}
}

stock void ResetClientID(int id)
{
	gShadow_Tomori_Client_Tag[id] = "";
	gShadow_Tomori_Client_CTag[id] = "";
	gShadow_Tomori_Client_TColor[id] = "";
	gShadow_Tomori_Client_NColor[id] = "";
	gShadow_Tomori_Client_CColor[id] = "";
	
	gShadow_Tomori_Client_RainbowT[id] = false;
	gShadow_Tomori_Client_RainbowC[id] = false;
	gShadow_Tomori_Client_RainbowN[id] = false;
	
	gShadow_Tomori_Client_RandomT[id] = false;
	gShadow_Tomori_Client_RandomC[id] = false;
	gShadow_Tomori_Client_RandomN[id] = false;
	
	if (gShadow_Tomori_Client_ForceClan[id] != null)
		delete gShadow_Tomori_Client_ForceClan[id];
}

stock bool IsClientInSteamList(int client)
{
	char ID[32];
	GetClientAuthId(client, AuthId_SteamID64, ID, sizeof(ID));
	
	char CheckID[32]; bool Set = false;
	KeyValues kv = CreateKeyValues("tomori_tags_by_steamid");
	kv.ImportFromFile(gH_Cvar_Tomori_Tags_SteamID);
	
	if (!kv.GotoFirstSubKey())
		return false;
		
	do
	{
		kv.GetSectionName(CheckID, sizeof(CheckID));
	
		if (StrEqual(ID, CheckID))
		{
			ResetClientID(client);
			
			kv.GetString("chat-tag", gShadow_Tomori_Client_Tag[client], sizeof(gShadow_Tomori_Client_Tag));
			kv.GetString("clan-tag", gShadow_Tomori_Client_CTag[client], sizeof(gShadow_Tomori_Client_CTag));
			kv.GetString("chat-color", gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor));
			kv.GetString("name-color", gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor));
			kv.GetString("tag-color", gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor));
			
			Set = true;
			SetUserTags(client);
		}
	}
	while (kv.GotoNextKey() && !Set);
	delete kv;
	
	return Set;
}

stock void GetUserTagByFlag(int client)
{
	char s_flag[32], a_flag[32]; bool NotSet = true;
	KeyValues kv = CreateKeyValues("tomori_tags_by_flag");
	kv.ImportFromFile(gH_Cvar_Tomori_Tags_Flag);
	
	if (!kv.GotoFirstSubKey())
		return;
		
	do
	{
		kv.GetSectionName(s_flag, sizeof(s_flag));
		
		if ((StrContains("abcdefghijklmnopqrstz", s_flag, false) == -1) && (!StrEqual(s_flag, "default")))
		{
			gH_Cvar_Tomori_Tags_Enabled.SetInt(0, true, false);
			LogToFileEx(gShadow_Tomori_LogFile, "Tags Disabled. The Flag config file contains incorrect flag (%s)", s_flag);
			return;
		}
		
		Format(a_flag, sizeof(a_flag), s_flag);
		
		GetFlagInt(s_flag);
		int flag = StringToInt(s_flag);
		
		if(Client_HasAdminFlags(client, flag) || StrEqual(a_flag, "default"))
		{
			ResetClientID(client);
			
			kv.GetString("chat-tag", gShadow_Tomori_Client_Tag[client], sizeof(gShadow_Tomori_Client_Tag));
			kv.GetString("clan-tag", gShadow_Tomori_Client_CTag[client], sizeof(gShadow_Tomori_Client_CTag));
			kv.GetString("chat-color", gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor));
			kv.GetString("name-color", gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor));
			kv.GetString("tag-color", gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor));
			
			NotSet = false;
			SetUserTags(client);
		}
	}
	while (kv.GotoNextKey() && NotSet);
	delete kv;
}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue && AllowRun && gShadow_Tomori_Client_Custom[client])
	{
		char sname[MAX_NAME_LENGTH];
		GetClientName(client, sname, MAX_NAME_LENGTH);
		
		if (gShadow_Tomori_Client_RainbowN[client])
			Format(name, MAX_NAME_LENGTH, "%s", SetRainbow(sname));
		else if (gShadow_Tomori_Client_RandomN[client])
			Format(name, MAX_NAME_LENGTH, "%s", SetRandom(sname));
		else
			Format(name, MAX_NAME_LENGTH, "%s%s", gShadow_Tomori_Client_NColor[client], sname);
		
		if (gShadow_Tomori_Client_RainbowC[client])
			Format(message, 512, "%s", SetRainbow(message));
		else if (gShadow_Tomori_Client_RandomC[client])
			Format(message, 512, "%s", SetRandom(message));
		else
			Format(message, 512, "%s%s", gShadow_Tomori_Client_CColor[client], message);
			
		if (gShadow_Tomori_Client_RainbowT[client])
			Format(name, MAX_NAME_LENGTH, "%s %s", SetRainbow(gShadow_Tomori_Client_Tag[client]), name);
		else if (gShadow_Tomori_Client_RandomT[client])
			Format(name, MAX_NAME_LENGTH, "%s %s", SetRandom(gShadow_Tomori_Client_Tag[client]), name);
		else
			Format(name, MAX_NAME_LENGTH, "%s%s %s", gShadow_Tomori_Client_TColor[client], gShadow_Tomori_Client_Tag[client], name);

		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock char[] SetRandom(char[] string)
{
	char sNewString[512];
	Format(sNewString, 512, "%c%s{default}", GetRandomColor(), string);
	return sNewString;
}

stock char[] SetRainbow(char[] string)
{
	char sNewString[512];
	char sTemp[512];
	
	int len = strlen(string);
	for(int i = 0; i < len; i++)
	{
		if (IsCharSpace(string[i]))
		{
			Format(sTemp, sizeof(sTemp), "%s%c", sTemp, string[i]);
			continue;
		}
		
		int bytes = GetCharBytes(string[i])+1;
		char[] c = new char[bytes];
		strcopy(c, bytes, string[i]);
		Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetRandomColor(), c);
		if (IsCharMB(string[i]))
		i += bytes-2;
	}		
	Format(sNewString, 512, "%s{default}", sTemp);
	
	return sNewString;
}

stock int GetRandomColor()
{
	switch(GetRandomInt(1, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x03';
		case  5: return '\x04';
		case  6: return '\x05';
		case  7: return '\x06';
		case  8: return '\x07';
		case  9: return '\x08';
		case 10: return '\x09';
		case 11: return '\x10';
		case 12: return '\x0A';
		case 13: return '\x0B';
		case 14: return '\x0C';
		case 15: return '\x0E';
		case 16: return '\x0F';
	}
	return '\x01';
}

stock void SetUserTags(int client)
{
	gShadow_Tomori_Client_Custom[client] = true;

	if (StrEqual(gShadow_Tomori_Client_TColor[client], "{rainbow}"))
		gShadow_Tomori_Client_RainbowT[client] = true;
	
	if (StrEqual(gShadow_Tomori_Client_NColor[client], "{rainbow}"))
		gShadow_Tomori_Client_RainbowN[client] = true;
	
	if (StrEqual(gShadow_Tomori_Client_CColor[client], "{rainbow}"))
		gShadow_Tomori_Client_RainbowC[client] = true;
		
	if (StrEqual(gShadow_Tomori_Client_TColor[client], "{random}"))
		gShadow_Tomori_Client_RandomT[client] = true;
	
	if (StrEqual(gShadow_Tomori_Client_NColor[client], "{random}"))
		gShadow_Tomori_Client_RandomN[client] = true;
	
	if (StrEqual(gShadow_Tomori_Client_CColor[client], "{random}"))
		gShadow_Tomori_Client_RandomC[client] = true;
	
	if (!StrEqual(gShadow_Tomori_Client_CTag[client], ""))
	{
		SetClanTagFix(client);
		gShadow_Tomori_Client_ForceClan[client] = CreateTimer(1.0, Timer_ForceClanTag, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ForceClanTag(Handle timer, int client)
{
	SetClanTagFix(client);
}

stock void SetClanTagFix(int client)
{
	CS_SetClientClanTag(client, gShadow_Tomori_Client_CTag[client]);
}