Handle dhCouldHealTarget = null;

void CouldHealTargetCreate(GameData gamedata)
{
    dhCouldHealTarget = DHookCreateFromConf(gamedata, "CObjectDispenser::CouldHealTarget");

    DHookEnableDetour(dhCouldHealTarget, false, CouldHealTargetPre);
    DHookEnableDetour(dhCouldHealTarget, true, CouldHealTargetPost);
}

int CouldHealTargetTempTeam = -1;

MRESReturn CouldHealTargetPre(int pThis, Handle hReturn, Handle hParams)
{
    int owner = GetOwner(pThis);
    int other = DHookGetParam(hParams, 1);

    Call_StartForward(fwCanHeal);
    Call_PushCell(owner);
    Call_PushCell(other);

    bool heal = false;
    Call_PushCellRef(heal);

    Action result = Plugin_Continue;
    Call_Finish(result);

    if(result != Plugin_Changed) {
        return MRES_Ignored;
    }

    if(heal) {
        int owner_team = GetEntityTeam(owner);

        CouldHealTargetTempTeam = GetEntityTeam(other);
        SetEntityTeam(other, owner_team, true);
    } else {
        DHookSetReturn(hReturn, 0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn CouldHealTargetPost(int pThis, Handle hReturn, Handle hParams)
{
    int other = DHookGetParam(hParams, 1);

    if(CouldHealTargetTempTeam != -1) {
        SetEntityTeam(other, CouldHealTargetTempTeam, true);
        CouldHealTargetTempTeam = -1;
    }

    return MRES_Ignored;
}