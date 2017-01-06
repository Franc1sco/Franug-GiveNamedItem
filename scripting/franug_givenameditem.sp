#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#define _givenameditem_server
#include <givenameditem>
#include "givenameditem/convars.inc"
//#include "givenameditem/hook.inc"
#include "givenameditem/items.inc"
#include "givenameditem/mm_server.inc"
#include "givenameditem/natives.inc"
#include "givenameditem/commands.inc"
#pragma semicolon 1

Handle g_hOnGiveNamedItemFoward = null;

#define DATA "3.0.2 private version"

public Plugin myinfo =
{
    name = "CS:GO GiveNamedItem Hook Franug Edition",
    author = "Franc1sco franug and Neuro Toxin",
    description = "Hook for GiveNamedItem to allow other plugins to force classnames and paintkits",
    version = DATA
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("givenameditem");
	CreateNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	
	RegisterCommands();
	BuildItems();
	RegisterConvars();
	g_hOnGiveNamedItemFoward = CreateGlobalForward("OnGiveNamedItemEx", ET_Ignore, Param_Cell, Param_String);
}

public void OnClientPutInServer(int client)
{	
	HookPlayer(client);
}

public void OnConfigsExecuted()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		OnClientPutInServer(client);
	}
}

stock void HookPlayer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

stock void UnhookPlayer(int client)
{
	SDKUnHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public OnMapStart()
{
	CreateTimer(1.0, Timer_CreateFakeClient, any:0, 2);
}

public OnClientDisconnect(client)
{
	if (client == g_iFakeClient)g_iFakeClient = -1;
}

public OnMapEnd()
{
	if(g_iFakeClient != -1 && IsClientInGame(g_iFakeClient)) KickClient(g_iFakeClient, "not used");
	g_iFakeClient = -1;
}

public Action Timer_CreateFakeClient(Handle:pTimer, any:_Data)
{
	g_iFakeClient = CreateFakeClient("BOT Franug");
}

public Action AddItemTimer(Handle timer, any ph)
{  
	int client, item, definitionindex;
	
	ResetPack(ph);
	
	client = EntRefToEntIndex(ReadPackCell(ph));
	item = EntRefToEntIndex(ReadPackCell(ph));
	definitionindex = ReadPackCell(ph);
	
	if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE)
	{
		GiveNamedItem_GiveKnife(client, definitionindex);
	}
}

public Action OnWeaponEquip(int client, int entity)
{
	if (g_iFakeClient == client)return;
	
	if(entity < 1 || !IsValidEdict(entity) || !IsValidEntity(entity)) return;
	
	if (GetEntProp(entity, Prop_Send, "m_hPrevOwner") > 0)
		return;
		
	new itemdefinition = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	char classname[64];
	if(!g_hServerHook.GetClassnameByItemDefinition(itemdefinition, classname, sizeof(classname))) return;
	
	// Call GiveNamedItemEx forward
	Call_StartForward(g_hOnGiveNamedItemFoward);
	Call_PushCell(client);
	Call_PushString(classname);
	
	// Do nothing if the forward fails
	if (Call_Finish() != SP_ERROR_NONE)
	{
		g_hServerHook.Reset(client);
		return;
	}
	
	if(!g_hServerHook.InUse && g_hServerHook.IsItemDefinitionKnife(itemdefinition) && g_hServerHook.ItemDefinition != -1)
	{
			
			Handle ph=CreateDataPack();
			WritePackCell(ph, EntIndexToEntRef(client));
			WritePackCell(ph, EntIndexToEntRef(entity));
			WritePackCell(ph, g_hServerHook.ItemDefinition);
			CreateTimer(0.5 , AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE);
			
			return;
	}
	
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "----====> OnGiveNamedItemPost(entity=%d, classname=%s)", entity, classname);
	}
	
	if(g_hServerHook.Paintkit == INVALID_PAINTKIT)
	{
		return;
	}
	
	// This is the magic peice
	SetEntProp(entity, Prop_Send, "m_iItemIDLow", -1);
	
	// Some more special attention around vanilla paintkits
	if (g_hServerHook.Paintkit == PAINTKIT_VANILLA)
	{
		//if (!g_hServerHook.TeamSwitch)
		//	SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
			
		/*if (g_hServerHook.EntityQuality == -1)
			g_hServerHook.EntityQuality = 1;*/
	}
	
	// Set fallback paintkit if the paintkit isnt vanilla
	else SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
	
	// Set wear and seed if required
	if (g_hServerHook.Paintkit != PAINTKIT_PLAYERS)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackSeed", g_hServerHook.Seed);
		SetEntPropFloat(entity, Prop_Send, "m_flFallbackWear", g_hServerHook.Wear);
	}
	
	// Special treatment for stattrak items
	if (g_hServerHook.Kills > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackStatTrak", g_hServerHook.Kills);
		
		if (g_hServerHook.EntityQuality == -1)
			g_hServerHook.EntityQuality = 1;
			
		if (g_hServerHook.AccountID == 0)
			g_hServerHook.AccountID = GetSteamAccountID(g_hServerHook.Client);
	}
	
	// The last few things
	if (g_hServerHook.EntityQuality > -1)
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", g_hServerHook.EntityQuality);
		
	if (g_hServerHook.AccountID > 0)
		SetEntProp(entity, Prop_Send, "m_iAccountID", g_hServerHook.AccountID);
	
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "-----=====> SETPAINTKIT(Paintkit=%d, Seed=%d, Wear=%f, Kills=%d, EntityQuality=%d)",
								g_hServerHook.Paintkit, g_hServerHook.Seed, g_hServerHook.Wear, g_hServerHook.Kills, g_hServerHook.EntityQuality);
	}
	
	
	g_hServerHook.Reset(client);
	
}

/*
stock GetReserveAmmo(weapon)
{
	new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
	if(ammotype == -1) return -1;
    
	return ammotype;
}

stock SetReserveAmmo(weapon, ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
	//PrintToChatAll("fijar es %i", ammo);
} 

Restore(client, weapon)
{
	char Classname[64];
	GetEdictClassname(weapon, Classname, 64);
	
	new weaponindex = GetEntProp(windex, Prop_Send, "m_iItemDefinitionIndex");
	switch (weaponindex)
	{
					case 60: strcopy(Classname, 64, "weapon_m4a1_silencer");
					case 61: strcopy(Classname, 64, "weapon_usp_silencer");
					case 63: strcopy(Classname, 64, "weapon_cz75a");
					case 500: strcopy(Classname, 64, "weapon_bayonet");
					case 506: strcopy(Classname, 64, "weapon_knife_gut");
					case 505: strcopy(Classname, 64, "weapon_knife_flip");
					case 508: strcopy(Classname, 64, "weapon_knife_m9_bayonet");
					case 507: strcopy(Classname, 64, "weapon_knife_karambit");
					case 509: strcopy(Classname, 64, "weapon_knife_tactical");
					case 515: strcopy(Classname, 64, "weapon_knife_butterfly");
					case 512: strcopy(Classname, 64, "weapon_knife_falchion");
					case 516: strcopy(Classname, 64, "weapon_knife_push");
					case 64: strcopy(Classname, 64, "weapon_revolver");
					case 514: strcopy(Classname, 64, "weapon_knife_survival_bowie");
	}
	
	new bool:knife = false;
	if(StrContains(Classname, "weapon_knife", false) == 0 || StrContains(Classname, "weapon_bayonet", false) == 0) 
	{
		knife = true;
	}
	
	
	//PrintToChat(client, "weapon %s", Classname);
	new ammo, clip;
	if(!knife)
	{
		ammo = GetReserveAmmo(windex);
		clip = GetEntProp(windex, Prop_Send, "m_iClip1");
	}
	RemovePlayerItem(client, windex);
	AcceptEntityInput(windex, "Kill");
	
	new entity;
	if(knife && !StrEqual(g_knife[client][classname], "none")) entity = GivePlayerItem(g_iFakeClient, g_knife[client][classname]);
	else GivePlayerItem(client, "weapon_knife");
	
	
	
	if(knife && !StrEqual(g_knife[client][classname], "none"))
	{
		EquipPlayerWeapon(client, entity);
	}
	else
	{
		SetReserveAmmo(entity, ammo);
		SetEntProp(entity, Prop_Send, "m_iClip1", clip);
	}
}*/