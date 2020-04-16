Handle dhFPlayerCanTakeDamage = null;

stock void FPlayerCanTakeDamageCreate(GameData gamedata)
{
    dhFPlayerCanTakeDamage = DHookCreateFromConf(gamedata, "CTeamplayRules::FPlayerCanTakeDamage");
}

stock void FPlayerCanTakeDamageMapStart()
{
	if(dhFPlayerCanTakeDamage != null) {
		DHookGamerules(dhFPlayerCanTakeDamage, false, INVALID_FUNCTION, FPlayerCanTakeDamagePre);
	}
}

stock MRESReturn FPlayerCanTakeDamagePre(int pThis, Handle hReturn, Handle hParams)
{
	int owner = GetOwner(DHookGetParam(hParams, 2));
	int other = GetOwner(DHookGetParam(hParams, 1));

	Call_StartForward(fwCanDamage);
	Call_PushCell(owner);
	Call_PushCell(other);

	bool dmg = false;
	Call_PushCellRef(dmg);

	Action result = Plugin_Continue;
	Call_Finish(result);

	if(result == Plugin_Changed) {
		DHookSetReturn(hReturn, dmg);
		return MRES_Supercede;
	}

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
			DHookSetReturn(hReturn, 1);
			return MRES_Supercede;
		}
	}

	return MRES_Ignored;
}