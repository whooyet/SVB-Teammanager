Handle dhShouldCollide = null;
Handle dhCanCollideWithTeammates = null;

stock void ShouldCollideCreate(GameData gamedata)
{
	dhShouldCollide = DHookCreateFromConf(gamedata, "CBaseEntity::ShouldCollide");
	dhCanCollideWithTeammates = DHookCreateFromConf(gamedata, "CBaseProjectile::CanCollideWithTeammates");
}

stock void ShouldCollideEntityCreated(int entity, const char[] classname)
{
	//SDKHook(entity, SDKHook_ShouldCollide, ShouldCollideSDKHook);
	//DHookEntity(dhShouldCollide, false, entity, INVALID_FUNCTION, ShouldCollideDHookPre);

	/*if(StrContains(classname, "tf_projectile") != -1) {
		int owner = GetOwner(entity);
		if(IsPlayer(owner)) {
			if(PlayerFF[owner]) {
				DHookEntity(dhCanCollideWithTeammates, false, entity, INVALID_FUNCTION, CanCollideWithTeammatesPre);
			}
		}
	}*/
}

#define COLLISION_GROUP_PLAYER_MOVEMENT 8
#define TFCOLLISION_GROUP_ROCKETS 24
#define CONTENTS_REDTEAM 0x800
#define CONTENTS_BLUETEAM 0x1000

/*
stock int ShouldCollideHelper(int owner, int other, int collisiongroup, int contentsmask)
{
	if(IsPlayer(owner)) {
		if(IsPlayer(other)) {
			int owner_team = GetEntityTeam(owner);
			int other_team = GetEntityTeam(other);
			if(owner_team == other_team) {
				if(PlayerFF[owner] || PlayerFF[other]) {
					return 1;
				}
			}
		}

		if(collisiongroup != -1 && contentsmask != -1) {
			if(collisiongroup == COLLISION_GROUP_PLAYER_MOVEMENT) {
				if(PlayerFF[owner]) {
					int team = GetEntityTeam(owner);
					switch(team) {
						case 2: {
							if(!(contentsmask & CONTENTS_REDTEAM)) {
								return 1;
							}
						}
						case 3: {
							if(!(contentsmask & CONTENTS_BLUETEAM)) {
								return 1;
							}
						}
					}
				}
			}
		}
	}

	return -1;
}

stock MRESReturn ShouldCollideDHookPre(int pThis, Handle hReturn, Handle hParams)
{
	int owner = GetOwner(pThis);
	int group = DHookGetParam(hParams, 1);
	int mask = DHookGetParam(hParams, 2);

	int val = ShouldCollideHelper(owner, -1, group, mask);
	if(val != -1) {
		DHookSetReturn(hReturn, val);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

stock MRESReturn CanCollideWithTeammatesPre(int pThis, Handle hReturn)
{
	DHookSetReturn(hReturn, 1);
	return MRES_Supercede;
}

public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
	return Plugin_Continue;
}

public Action CH_ShouldCollide(int ent1, int ent2, bool &result)
{
	int val = ShouldCollideHelper(GetOwner(ent1), GetOwner(ent2), -1, -1);
	if(val != -1) {
		result = (val == 1);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

stock bool ShouldCollideSDKHook(int entity, int collisiongroup, int contentsmask, bool originalResult)
{
	int owner = GetOwner(entity);

	int val = ShouldCollideHelper(owner, -1, collisiongroup, contentsmask);
	if(val != -1) {
		return (val == 1);
	}

	return originalResult;
}*/