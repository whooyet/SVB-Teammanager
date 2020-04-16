Handle dhStrikeTarget = null;

stock void StrikeTargetCreate(GameData gamedata)
{
	dhStrikeTarget = DHookCreateFromConf(gamedata, "CTFProjectile_Arrow::StrikeTarget");

	DHookEnableDetour(dhStrikeTarget, false, StrikeTargetPre);
	DHookEnableDetour(dhStrikeTarget, true, StrikeTargetPost);
}

int StrikeTargetTempTeam = -1;

stock bool IsHealingBolt(int type)
{
	return (type == 11 || type == 32);
}

stock bool IsBuildingBolt(int type)
{
	return (type == 18);
}

stock MRESReturn StrikeTargetPre(int pThis, Handle hReturn, Handle hParams)
{
	int projtype = GetEntProp(pThis, Prop_Send, "m_iProjectileType");

	if(IsHealingBolt(projtype) || IsBuildingBolt(projtype)) {
		int owner = GetOwner(pThis);
		int other = DHookGetParam(hParams, 2);
		int other_owner = GetOwner(other);

		if(IsBuildingBolt(projtype) && IsPlayer(other)) {
			return MRES_Ignored;
		}

		if(IsHealingBolt(projtype) && !IsPlayer(other)) {
			return MRES_Ignored;
		}

		Call_StartForward(fwCanHeal);
		Call_PushCell(owner);
		Call_PushCell(other_owner);

		bool heal = false;
		Call_PushCellRef(heal);

		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result != Plugin_Changed) {
			return MRES_Ignored;
		}

		if(heal) {
			int owner_team = GetEntityTeam(owner);
			StrikeTargetTempTeam = GetEntityTeam(other_owner);
			SetEntityTeam(other, owner_team, true);
		}
	}

	return MRES_Ignored;
}

stock MRESReturn StrikeTargetPost(int pThis, Handle hReturn, Handle hParams)
{
	if(StrikeTargetTempTeam != -1) {
		int other = DHookGetParam(hParams, 2);
		SetEntityTeam(other, StrikeTargetTempTeam, true);
		StrikeTargetTempTeam = -1;
	}

	return MRES_Ignored;
}