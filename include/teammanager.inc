#if defined _teammanager_inc_
	#endinput
#endif
#define _teammanager_inc_

forward Action TeamManager_CanHeal(int entity, int other, bool &result);
forward Action TeamManager_CanDamage(int entity, int other, bool &result);
forward Action TeamManager_CanPickupBuilding(int entity, int other, bool &result);
forward Action TeamManager_InSameTeam(int entity, int other, bool &result);

forward Action TeamManager_CanChangeTeam(int entity, int team, bool &result);
forward Action TeamManager_CanChangeClass(int entity, int class, bool &result);

native int TeamManager_GetEntityFakeTeam(int entity);
native int TeamManager_GetEntityTeam(int entity);

native void TeamManager_SetEntityFakeTeam(int entity, int faketeam);
native void TeamManager_SetEntityTeam(int entity, int team, bool raw);

native void TeamManager_SetPlayerFF(int player, bool ff);

stock int GetTeamIndex(const char[] name)
{
	if(StrEqual(name, "red") ||
		StrEqual(name, "2")) {
		return 2;
	} else if(StrEqual(name, "blu") ||
				StrEqual(name, "blue") ||
				StrEqual(name, "3")) {
		return 3;
	} else if(StrEqual(name, "spectate") ||
				StrEqual(name, "spec") ||
				StrEqual(name, "spectator") ||
				StrEqual(name, "1")) {
		return 1;
	} else {
		int count = GetTeamCount();
		for(int i = 0; i < count; i++) {
			char team[32];
			GetTeamName(i, team, sizeof(team));

			if(StrEqual(name, team)) {
				return i;
			}
		}

		return -1;
	}
}

public SharedPlugin __pl_teammanager =
{
	name = "teammanager",
	file = "teammanager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_teammanager_SetNTVOptional()
{
	MarkNativeAsOptional("TeamManager_GetEntityFakeTeam");
	MarkNativeAsOptional("TeamManager_GetEntityTeam");
	MarkNativeAsOptional("TeamManager_SetEntityFakeTeam");
	MarkNativeAsOptional("TeamManager_SetEntityTeam");
	MarkNativeAsOptional("TeamManager_SetPlayerFF");
}
#endif