#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <PTaH>
#include <sm_franugknife>
#include <givenameditem>

#define DATA "1.1"

public Plugin:myinfo =
{
	name = "SM Fix Knives for Franug GiveNamedItem plugin",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	PTaH(PTaH_GiveNamedItemPre, Hook, GiveNamedItemPre);
	PTaH(PTaH_GiveNamedItemPost, Hook, GiveNamedItem);
}

public Action GiveNamedItemPre(int client, char classname[64], CEconItemView &Item, bool &IgnoredCEconItemView, bool &OriginIsNULL, float Origin[3])
{
	if (IsValidClient(client))
	{
		if (Franug_GetKnife(client) > 2 && IsKnifeClass(classname))
		{
			IgnoredCEconItemView = true;
			GiveNamedItemEx.GetClassnameByItemDefinition(Franug_GetKnife(client), classname, sizeof(classname));
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void GiveNamedItem(int client, const char[] classname, const CEconItemView Item, int entity, bool OriginIsNULL, const float Origin[3])
{
	if (IsValidClient(client) && IsValidEntity(entity))
	{
		if (Franug_GetKnife(client) > 2 && IsKnifeClass(classname))
		{
			EquipPlayerWeapon(client, entity);
		}
	}
}

stock bool IsKnifeClass(const char[] classname)
{
	if (StrContains(classname, "knife") > -1 || StrContains(classname, "bayonet") > -1)
		return true;
	return false;
}

stock bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    return true;
}