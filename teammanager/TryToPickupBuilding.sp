Handle dhTryToPickupBuilding = null;
Handle dhStartBuilding = null;
Handle callAddObject = null;
Handle callRemoveObject = null;

stock void TryToPickupBuildingCreate(GameData gamedata)
{
	dhTryToPickupBuilding = DHookCreateFromConf(gamedata, "CTFPlayer::TryToPickupBuilding");
	dhStartBuilding = DHookCreateFromConf(gamedata, "CBaseObject::StartBuilding");

	DHookEnableDetour(dhTryToPickupBuilding, false, TryToPickupBuildingPre);
	DHookEnableDetour(dhTryToPickupBuilding, true, TryToPickupBuildingPost);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::AddObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	callAddObject = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	callRemoveObject = EndPrepSDKCall();
}

int TryToPickupBuildingTempEntity = -1;
int TryToPickupBuildingTempTeam = -1;
int TryToPickupBuildingTempOwner[MAXPLAYERS+1] = {-1, ...};
int StartBuildingTempIDPre[MAXPLAYERS+1] = {-1, ...};
int StartBuildingTempIDPost[MAXPLAYERS+1] = {-1, ...};

stock void TryToPickupBuildingDisconnect(int client)
{
	if(StartBuildingTempIDPre[client] != -1) {
		DHookRemoveHookID(StartBuildingTempIDPre[client]);
		StartBuildingTempIDPre[client] = -1;
	}
	if(StartBuildingTempIDPost[client] != -1) {
		DHookRemoveHookID(StartBuildingTempIDPost[client]);
		StartBuildingTempIDPost[client] = -1;
	}
	TryToPickupBuildingTempOwner[client] = -1;
}

stock bool BuildingEnum(int entity)
{
	if(IsValidEntity(entity)) {
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));

		if(StrContains(classname, "obj_") != -1) {
			TryToPickupBuildingTempEntity = entity;
			return false;
		}
	}
	return true;
}

stock MRESReturn TryToPickupBuildingPre(int pThis)
{
	float eye[3];
	GetClientEyeAngles(pThis, eye);

	float fwd[3];
	GetAngleVectors(eye, fwd, NULL_VECTOR, NULL_VECTOR);

	float start[3];
	GetClientEyePosition(pThis, start);

	ScaleVector(fwd, 150.0);

	float end[3];
	AddVectors(end, start, end);
	AddVectors(end, fwd, end);

	TryToPickupBuildingTempEntity = -1;
	TR_EnumerateEntities(start, end, PARTITION_SOLID_EDICTS, RayType_EndPoint, BuildingEnum, TryToPickupBuildingTempEntity);

	if(TryToPickupBuildingTempEntity != -1) {
		int owner = GetOwner(TryToPickupBuildingTempEntity);
		if(!IsPlayer(owner)) {
			TryToPickupBuildingTempEntity = -1;
			return MRES_Ignored;
		}

		Call_StartForward(fwCanPickupBuilding);
		Call_PushCell(pThis);
		Call_PushCell(owner);

		bool pick = false;
		Call_PushCellRef(pick);

		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result != Plugin_Changed) {
			TryToPickupBuildingTempEntity = -1;
			return MRES_Ignored;
		}

		if(pick) {
			TryToPickupBuildingTempTeam = GetEntityTeam(pThis);
			TryToPickupBuildingTempOwner[pThis] = owner;
			SetEntityTeam(pThis, GetEntityTeam(TryToPickupBuildingTempEntity), true);
			SDKCall(callAddObject, pThis, TryToPickupBuildingTempEntity);
		}
	}

	return MRES_Ignored;
}

stock MRESReturn TryToPickupBuildingPost(int pThis)
{
	if(TryToPickupBuildingTempEntity != -1) {
		SDKCall(callRemoveObject, pThis, TryToPickupBuildingTempEntity);
		if(StartBuildingTempIDPre[pThis] != -1) {
			DHookRemoveHookID(StartBuildingTempIDPre[pThis]);
		}
		if(StartBuildingTempIDPost[pThis] != -1) {
			DHookRemoveHookID(StartBuildingTempIDPost[pThis]);
		}
		StartBuildingTempIDPre[pThis] = DHookEntity(dhStartBuilding, false, TryToPickupBuildingTempEntity, INVALID_FUNCTION, StartBuildingPre);
		StartBuildingTempIDPost[pThis] = DHookEntity(dhStartBuilding, true, TryToPickupBuildingTempEntity, INVALID_FUNCTION, StartBuildingPost);
		TryToPickupBuildingTempEntity = -1;
	}

	if(TryToPickupBuildingTempTeam != -1) {
		SetEntityTeam(pThis, TryToPickupBuildingTempTeam, true);
		TryToPickupBuildingTempTeam = -1;
	}

	return MRES_Ignored;
}

stock void TryToPickupBuildingDestroyed(int entity)
{
	if(entity == TryToPickupBuildingTempEntity) {
		TryToPickupBuildingTempEntity = -1;
	}
}

stock MRESReturn StartBuildingPre(int pThis, Handle hReturn, Handle hParams)
{
	int fake_owner = GetOwner(pThis);
	int real_owner = TryToPickupBuildingTempOwner[fake_owner];
	if(real_owner != -1) {
		TryToPickupBuildingTempOwner[real_owner] = fake_owner;
		SetEntPropEnt(pThis, Prop_Send, "m_hBuilder", real_owner);
		SetEntPropEnt(pThis, Prop_Send, "m_iObjectMode", 0);
		TryToPickupBuildingTempOwner[fake_owner] = -1;
	}
	return MRES_Ignored;
}

stock MRESReturn StartBuildingPost(int pThis, Handle hReturn, Handle hParams)
{
	int real_owner = GetOwner(pThis);
	int fake_owner = TryToPickupBuildingTempOwner[real_owner];
	if(fake_owner != -1) {
		SDKCall(callRemoveObject, fake_owner, pThis);
		TryToPickupBuildingTempOwner[real_owner] = -1;
	}
	return MRES_Ignored;
}