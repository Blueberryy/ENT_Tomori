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

#include <adminmenu>

ConVar gH_Cvar_Tomori_Gathering_Enabled;					//Enable or disable Gathering Module (0 - Disable, 1 - Enabled);
ConVar gH_Cvar_Tomori_Gathering_Flag;						//Flag to use sm_player

int gShadow_Tomori_Target[MAXPLAYERS+1];
int gShadow_Tomori_AdminChat[MAXPLAYERS+1] = false;

int gShadow_Tomori_AdminBanning[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminCTBanning[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminKicking[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminInGag[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminInMute[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminInSil[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminBanning_Reason[MAXPLAYERS+1] = false;
int gShadow_Tomori_AdminBanning_Length_Temp[MAXPLAYERS+1];

public void Gather_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Gathering", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Gathering_Enabled = AutoExecConfig_CreateConVar("tomori_gathering_enabled", "1", "Enable or disable gathering module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Gathering_Flag = AutoExecConfig_CreateConVar("tomori_gathering_flag", "b", "Flag to use sm_player", 0);

	if (gH_Cvar_Tomori_Gathering_Enabled.BoolValue && AllowRun)
	{
		char gat_flag[32];
		gH_Cvar_Tomori_Gathering_Flag.GetString(gat_flag, sizeof(gat_flag));
		
		GetFlagInt(gat_flag);
		int gr_flag = StringToInt(gat_flag);
		RegAdminCmd("sm_player", Command_Player, gr_flag, "Open admin menu for targeted player");
	}

	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Gathering_Enabled.SetInt(0, true, false);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public Action Command_Player(int client, int args)
{
	if (gH_Cvar_Tomori_Gathering_Enabled.BoolValue && IsValidClient(client) && AllowRun)
	{
		if (args < 1)
		{
			ShowPlayerList(client);
		}
		else if (args == 1)
		{
			char sTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, sTarget, sizeof(sTarget));

			char sClientName[MAX_TARGET_LENGTH];
			int aiTargetList[MAXPLAYERS];
			bool b_tn_is_ml;
			ProcessTargetString(sTarget, client, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);
			
			int iTarget = aiTargetList[0];
			
			if(iTarget && IsClientInGame(iTarget))
			{
				gShadow_Tomori_Target[client] = iTarget;
				ShowData(client, iTarget, 1);
			}
		}
	}
	return Plugin_Handled;
}

stock Action ShowPlayerList(int client)
{
	if (IsValidClient(client) && AllowRun)
	{
		Menu menu = CreateMenu(MenuHandler_Player);
		
		char title[100], clientid[32], name[64];
		Format(title, sizeof(title), "-=| %t |=-\n ", "Tomori PlayerMenu");
		menu.SetTitle(title);
		
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (IsValidClient(idx))
			{
				IntToString(idx, clientid, sizeof(clientid));
				GetClientName(idx, name, sizeof(name));
			
				menu.AddItem(clientid, name);
			}
		}
		
		menu.Display(client, MENU_TIME_FOREVER);	
	}
}

public int MenuHandler_Player(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		int userid = StringToInt(info);

		if (userid == 0)
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NoLongerAvailable");
		}
		else if (!CanUserTarget(client, userid))
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori UnableToTarget");
		}
		else
		{
			gShadow_Tomori_Target[client] = userid;
			ShowData(client, userid, 1);
		}
	}
}

stock Action ShowData(int client, int target, int itemNum)
{
	if (IsValidClient(client) && AllowRun)
	{
		char databuffer[128];
		Format(databuffer, sizeof(databuffer), "-=| %N |=-\n \n", target);
		if (gShadow_Tomori_Client_Prime[target] == true) Format(databuffer, sizeof(databuffer), "%s%t: %t\n", databuffer, "Tomori Prime", "Tomori Yes");
		else if (gShadow_Tomori_Client_Prime[target] == false) Format(databuffer, sizeof(databuffer), "%s%t: %t\n", databuffer, "Tomori Prime", "Tomori No");
		
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n", databuffer, "Tomori SteamLevel", gShadow_Tomori_Client_Level[target]);
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n", databuffer, "Tomori PlayHours", gShadow_Tomori_Client_Hour[target]);
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n ", databuffer, "Tomori UserID", GetClientUserId(target));

		Menu menu = CreateMenu(MenuHandler_DataChoice);
		menu.SetTitle(databuffer);
		
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminControl");
		menu.AddItem("admin", databuffer);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_DataChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if (StrEqual(info, "admin"))
		{
			AdminControl(client, 1);
		}
	}
}

stock Action AdminControl(int client, int itemNum)
{
	if (IsValidClient(client) && AllowRun)
	{
		char databuffer[128];
		Format(databuffer, sizeof(databuffer), "-=| %t |=-\n ", "Tomori AdminControl");
		Menu menu = CreateMenu(MenuHandler_AdminChoice);
		menu.SetTitle(databuffer);
		
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminBan");
		menu.AddItem("ban", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminKick");
		menu.AddItem("kick", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminGag");
		menu.AddItem("gag", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminMute");
		menu.AddItem("mute", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori AdminSilence");
		menu.AddItem("silence", databuffer);
		
		if (gShadow_CTBanFound)
		{
			Format(databuffer, sizeof(databuffer), "%t", "Tomori CTBan Commands");
			menu.AddItem("ctbancmd", databuffer);
		}
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_AdminChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (StrEqual(info, "ban"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminBanning[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (StrEqual(info, "kick"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminBanning_Reason[client] = true;
			gShadow_Tomori_AdminKicking[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteReason");
		}
		else if (StrEqual(info, "gag"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInGag[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (StrEqual(info, "mute"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInMute[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (StrEqual(info, "silence"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInSil[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (gShadow_CTBanFound && StrEqual(info, "ctbancmd"))
		{
			CtbanControl(client, 1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ShowData(client, gShadow_Tomori_Target[client], 1);
	}
}

stock Action CtbanControl(int client, int itemNum)
{
	if (IsValidClient(client) && AllowRun)
	{
		char databuffer[128];
		Format(databuffer, sizeof(databuffer), "-=| %t |=-\n ", "Tomori CTBan Commands");
		Menu menu = CreateMenu(MenuHandler_CTBanChoice);
		menu.SetTitle(databuffer);
		
		Format(databuffer, sizeof(databuffer), "%t", "Tomori CTBan BanCT");
		menu.AddItem("ctban", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori CTBan RemoveCTBan");
		menu.AddItem("unctban", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori CTBan ForceCT");
		menu.AddItem("forcect", databuffer);
		Format(databuffer, sizeof(databuffer), "%t", "Tomori CTBan Isbanned");
		menu.AddItem("isbanned", databuffer);
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_CTBanChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (StrEqual(info, "ctban"))
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminCTBanning[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (StrEqual(info, "unctban"))
		{
			FakeClientCommand(client, "sm_unctban #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
		else if (StrEqual(info, "forcect"))
		{
			FakeClientCommand(client, "sm_forcect #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
		else if (StrEqual(info, "isbanned"))
		{
			FakeClientCommand(client, "sm_isbanned #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
	}
	else if (action == MenuAction_Cancel)
	{
		AdminControl(client, 1);
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
	if (gShadow_Tomori_AdminChat[client] && IsValidClient(client))
	{
		if (StrEqual(message, "!cancel") || StrEqual(message, "/cancel"))
		{
			gShadow_Tomori_AdminChat[client] = false;
			gShadow_Tomori_AdminBanning[client] = false;
			gShadow_Tomori_AdminCTBanning[client] = false;
			gShadow_Tomori_AdminKicking[client] = false;
			gShadow_Tomori_AdminInGag[client] = false;
			gShadow_Tomori_AdminInMute[client] = false;
			gShadow_Tomori_AdminInSil[client] = false;
			gShadow_Tomori_AdminBanning_Reason[client] = false;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin AbortSuccess");
			return Plugin_Handled;
		}
		else
		{
			if (!gShadow_Tomori_AdminBanning_Reason[client])
			{
				if (!String_IsNumeric(message))
				{
					gShadow_Tomori_AdminBanning[client] = false;
					gShadow_Tomori_AdminBanning_Reason[client] = false;
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin InvalidTime");
					return Plugin_Handled;
				}
				else
				{
					gShadow_Tomori_AdminBanning_Reason[client] = true;
					gShadow_Tomori_AdminBanning_Length_Temp[client] = StringToInt(message, 10);
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteReason");
					return Plugin_Handled;
				}
			}
			else
			{
				if (gShadow_Tomori_AdminBanning[client])
					FakeClientCommand(client, "sm_ban #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminKicking[client])
					FakeClientCommand(client, "sm_kick #%i %s", GetClientUserId(gShadow_Tomori_Target[client]), message);
				else if (gShadow_Tomori_AdminInGag[client])
					FakeClientCommand(client, "sm_gag #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminInMute[client])
					FakeClientCommand(client, "sm_mute #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminInSil[client])
					FakeClientCommand(client, "sm_silence #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminCTBanning[client])
					FakeClientCommand(client, "sm_ctban #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
					
				gShadow_Tomori_AdminChat[client] = false;
				gShadow_Tomori_AdminBanning[client] = false;
				gShadow_Tomori_AdminCTBanning[client] = false;
				gShadow_Tomori_AdminKicking[client] = false;
				gShadow_Tomori_AdminInGag[client] = false;
				gShadow_Tomori_AdminInMute[client] = false;
				gShadow_Tomori_AdminInSil[client] = false;
				gShadow_Tomori_AdminBanning_Reason[client] = false;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}