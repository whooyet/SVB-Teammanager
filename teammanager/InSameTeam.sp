Handle dhInSameTeam = null;

stock void InSameTeamCreate(GameData gamedata)
{
	dhInSameTeam = DHookCreateFromConf(gamedata, "CBaseEntity::InSameTeam");

	DHookEnableDetour(dhInSameTeam, false, InSameTeamPre);
}

stock MRESReturn InSameTeamPre(int pThis, Handle hReturn, Handle hParams)
{
	int owner = GetOwner(pThis);
	int other = GetOwner(DHookGetParam(hParams, 1));

	if(IsPlayer(owner)) {
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
				DHookSetReturn(hReturn, 0);
				return MRES_Supercede;
			}
		}
	}

	Call_StartForward(fwInSameTeam);
	Call_PushCell(owner);
	Call_PushCell(other);

	bool team = false;
	Call_PushCellRef(team);

	Action result = Plugin_Continue;
	Call_Finish(result);

	if(result != Plugin_Changed) {
		return MRES_Ignored;
	}

	if(team) {
		DHookSetReturn(hReturn, 1);
		return MRES_Supercede;
	} else {
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
}