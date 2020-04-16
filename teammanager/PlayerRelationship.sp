Handle dhPlayerRelationship = null;

stock void PlayerRelationshipCreate(GameData gamedata)
{
	dhPlayerRelationship = DHookCreateFromConf(gamedata, "CTeamplayRules::PlayerRelationship");
}

stock void PlayerRelationshipMapStart()
{
	if(dhPlayerRelationship != null) {
		DHookGamerules(dhPlayerRelationship, false, INVALID_FUNCTION, PlayerRelationshipPre);
	}
}

#define GR_NOTTEAMMATE 0
#define GR_TEAMMATE 1
#define GR_ENEMY 2
#define GR_ALLY 3
#define GR_NEUTRAL 4

stock MRESReturn PlayerRelationshipPre(int pThis, Handle hReturn, Handle hParams)
{
	int owner = GetOwner(DHookGetParam(hParams, 2));

	if(IsPlayer(owner)) {
		int other = GetOwner(DHookGetParam(hParams, 1));

		int owner_team = GetEntityTeam(owner);
		int other_team = GetEntityTeam(other);
		if(owner_team == other_team) {
			bool other_ff = false;
			if(IsPlayer(other)) {
				if(PlayerFF[other]) {
					other_ff = true;
				}
			}
			if(PlayerFF[owner] || other_ff) {
				DHookSetReturn(hReturn, GR_ENEMY);
				return MRES_Supercede;
			}
		}
	}

	return MRES_Ignored;
}