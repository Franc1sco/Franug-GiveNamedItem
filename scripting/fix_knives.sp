#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <PTaH>
#include <sm_franugknife>
#include <givenameditem>

public void OnPluginStart()
{
	PTaH(PTaH_GiveNamedItemPre, Hook, GiveNamedItemPre);
	PTaH(PTaH_GiveNamedItem, Hook, GiveNamedItem);
}

public Action GiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView)
{
	if (IsValidClient(client))
	{
		if (Franug_GetKnife(client) > 2 && IsKnifeClass(classname))
		{
			ignoredCEconItemView = true;
			GiveNamedItemEx.GetClassnameByItemDefinition(Franug_GetKnife(client), classname, sizeof(classname));
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void GiveNamedItem(int client, const char[] classname, const CEconItemView item, int entity)
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