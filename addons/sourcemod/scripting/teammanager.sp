#include <sdktools>
#include <dhooks>
#include <tf2>
#include <tf2_stocks>
#include <teammanager>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
//#include <sendproxy>
//#include <collisionhook>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

//#define DEBUG

public Plugin myinfo =
{
	name = "Teammanager",
	author = "Arthurdead",
	description = "Api pra coisas de time",
	version = "$$GIT_COMMIT$$",
	url = ""
};

int PlayerFakeTeam[MAXPLAYERS+1] = {-1, ...};
bool PlayerTeamZero[MAXPLAYERS+1] = {false, ...};
bool PlayerFF[MAXPLAYERS+1] = {false, ...};
ConVar mp_friendlyfire = null;
ConVar tf_avoidteammates = null;
ConVar tf_avoidteammates_pushaway = null;
Handle hAddPlayer = null;
Handle hRemovePlayer = null;
//bool bSendProxy = false;
//bool bCollisionHook = false;
bool PlayerInVGUI[MAXPLAYERS+1] = {false, ...};
bool TeamInDeath[MAXPLAYERS+1] = {false, ...};
bool TeamInClass[MAXPLAYERS+1] = {false, ...};

#include "teammanager/stocks.inc"

GlobalForward fwCanHeal = null;
GlobalForward fwCanDamage = null;
GlobalForward fwInSameTeam = null;
GlobalForward fwCanPickupBuilding = null;
GlobalForward fwCanChangeTeam = null;
GlobalForward fwCanChangeClass = null;

#include "teammanager/AllowedToHealTarget.sp"
#include "teammanager/CouldHealTarget.sp"
#include "teammanager/Smack.sp"
#include "teammanager/InSameTeam.sp"
#include "teammanager/StrikeTarget.sp"
#include "teammanager/TryToPickupBuilding.sp"
#include "teammanager/FPlayerCanTakeDamage.sp"
#include "teammanager/PlayerRelationship.sp"
#include "teammanager/ShouldCollide.sp"

#include "teammanager/GetTeamID.sp"
#include "teammanager/JarExplode.sp"
#include "teammanager/IsValidRoboSapperTarget.sp"
#include "teammanager/PlayerCanBeTeleported.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int length)
{
	fwCanHeal = new GlobalForward("TeamManager_CanHeal", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	fwCanDamage = new GlobalForward("TeamManager_CanDamage", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	fwInSameTeam = new GlobalForward("TeamManager_InSameTeam", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	fwCanPickupBuilding = new GlobalForward("TeamManager_CanPickupBuilding", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	fwCanChangeTeam = new GlobalForward("TeamManager_CanChangeTeam", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	fwCanChangeClass = new GlobalForward("TeamManager_CanChangeClass", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);

	CreateNative("TeamManager_GetEntityTeam", Native_TeamManager_GetEntityTeam);
	CreateNative("TeamManager_GetEntityFakeTeam", Native_TeamManager_GetEntityFakeTeam);

	CreateNative("TeamManager_SetEntityTeam", Native_TeamManager_SetEntityTeam);
	CreateNative("TeamManager_SetEntityFakeTeam", Native_TeamManager_SetEntityFakeTeam);

	CreateNative("TeamManager_SetPlayerFF", Native_TeamManager_SetPlayerFF);

	RegPluginLibrary("teammanager");

	/*if(LibraryExists("sendproxy")) {
		bSendProxy = true;
	} else {
		if(GetExtensionFileStatus("sendproxy.ext") == 1) {
			bSendProxy = true;
		}
	}

	if(LibraryExists("collisionhook")) {
		bCollisionHook = true;
	} else {
		if(GetExtensionFileStatus("collisionhook.ext") == 1) {
			bCollisionHook = true;
		}
	}*/

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	/*if(StrEqual(name, "sendproxy")) {
		bSendProxy = true;
	} else if(StrEqual(name, "collisionhook")) {
		bCollisionHook = true;
	}*/
}

public void OnLibraryRemoved(const char[] name)
{
	/*if(StrEqual(name, "sendproxy")) {
		bSendProxy = false;
	} else if(StrEqual(name, "collisionhook")) {
		bCollisionHook = false;
	}*/
}

public void OnPluginStart()
{
	GameData gamedata = new GameData("teammanager");

	AllowedToHealTargetCreate(gamedata);
	InSameTeamCreate(gamedata);
	SmackCreate(gamedata);
	CouldHealTargetCreate(gamedata);
	StrikeTargetCreate(gamedata);
	TryToPickupBuildingCreate(gamedata);
	//FPlayerCanTakeDamageCreate(gamedata);
	PlayerRelationshipCreate(gamedata);
	ShouldCollideCreate(gamedata);

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hAddPlayer = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hRemovePlayer = EndPrepSDKCall();

	delete gamedata;

	AddCommandListener(ConCommand_JoinTeam, "changeteam");
	AddCommandListener(ConCommand_JoinTeam, "jointeam");
	AddCommandListener(ConCommand_JoinTeam, "jointeam_nomenus");
	AddCommandListener(ConCommand_JoinTeam, "join_team");

	AddCommandListener(ConCommand_JoinClass, "changeclass");
	AddCommandListener(ConCommand_JoinClass, "joinclass");
	AddCommandListener(ConCommand_JoinClass, "join_class");

	AddCommandListener(ConCommand_ClassMenu, "menuopen");
	AddCommandListener(ConCommand_ClassMenu, "menuclosed");

	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_team", Event_Team, EventHookMode_Post);
	//HookEvent("player_class", Event_Class, EventHookMode_Post);
	//HookEvent("player_changeclass", Event_Class, EventHookMode_Post);
	HookEvent("player_builtobject", Event_BuiltObject, EventHookMode_Post);

	HookUserMessage(GetUserMessageId("VGUIMenu"), VGUIMenu, true, INVALID_FUNCTION);
	//HookUserMessage(GetUserMessageId("ShowMenu"), ShowMenu, true, INVALID_FUNCTION);

	for(int i = 1; i < MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
			OnEntityCreated(i, "player");
		}
	}

	RegAdminCmd("sm_ff2", ConCommand_FF2, ADMFLAG_GENERIC, "");

	mp_friendlyfire = FindConVar("mp_friendlyfire");
	tf_avoidteammates_pushaway = FindConVar("tf_avoidteammates_pushaway");
	tf_avoidteammates = FindConVar("tf_avoidteammates");
}

stock Action VGUIMenu(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char name[32];
	msg.ReadString(name, sizeof(name), false);

	if(StrEqual(name, "class_blue") ||
		StrEqual(name, "class_red") ||
		StrEqual(name, "class")) {
		int player = players[0];
		PlayerInVGUI[player] = true;
	}

	return Plugin_Continue;
}

stock bool IsPlayerTeamZero(int client)
{
	return (PlayerTeamZero[client]/* || GetEntityTeam(client) == 0*/);
}

public void OnPluginEnd()
{
	for(int i = 1; i < MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientDisconnect(i);
			if(!IsFakeClient(i)) {
				SendConVarValue(i, mp_friendlyfire, "0");
				SendConVarValue(i, tf_avoidteammates, "1");
				SendConVarValue(i, tf_avoidteammates_pushaway, "1");
			}
			/*if(PlayerFakeTeam[i] != -1 || IsPlayerTeamZero(i)) {
				SetEntProp(i, Prop_Send, "m_bForcedSkin", 0);
				SetEntProp(i, Prop_Send, "m_nForcedSkin", 0);
			}*/
			if(IsPlayerTeamZero(i)) {
				SetEntityTeam(i, GetRandomInt(2, 3), false);
				TF2_RespawnPlayer(i);
			}
		}
	}
}

stock int Native_TeamManager_GetEntityTeam(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	return GetEntityTeam(entity);
}

stock int Native_TeamManager_GetEntityFakeTeam(Handle plugin, int params)
{
	int entity = GetNativeCell(1);

	if(!IsPlayer(entity)) {
		return -1;
	}

	return PlayerFakeTeam[entity];
}

/*stock void PostThinkPost(int client)
{
	int team = PlayerFakeTeam[client];
	if(team == -1 && IsPlayerTeamZero(client)) {
		team = 0;
	}
	if(team != -1) {
		int skin = GetEntProp(client, Prop_Send, "m_nSkin");

		bool uber = false;
		if(skin == 2 || skin == 3) {
			uber = true;
		} else if(skin == 0 || skin == 1) {
			uber = false;
		}

		if(team == 2) {
			if(uber) {
				skin = 2;
			} else {
				skin = 0;
			}
		} else if(team == 3) {
			if(uber) {
				skin = 3;
			} else {
				skin = 1;
			}
		} else if(team == 0) {
			if(uber) {
				skin = GetRandomInt(2, 3);
			} else {
				skin = GetRandomInt(0, 1);
			}
		}

		SetEntProp(client, Prop_Send, "m_nForcedSkin", skin);
	}
}

stock Action TeamNumProxy(int entity, const char[] PropName, int &iValue, int element)
{
	int owner = GetOwner(entity);
	int team = -1;
	if(IsPlayer(owner)) {
		team = PlayerFakeTeam[owner];
		if(team == -1 && IsPlayerTeamZero(owner)) {
			team = 0;
		}
	}
	if(team == 0) {
		if(IsPlayer(entity) && PlayerInVGUI[entity]) {
			iValue = 2;
			return Plugin_Changed;
		} else {
			iValue = GetRandomInt(2, 3);
			return Plugin_Changed;
		}
	} else if(team != -1) {
		iValue = team;
		return Plugin_Changed;
	} else {
		return Plugin_Continue;
	}
}*/

stock int Native_TeamManager_SetEntityTeam(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	int team = GetNativeCell(2);
	bool raw = GetNativeCell(3);

	SetEntityTeam(entity, team, raw);

	if(IsPlayer(entity)) {
		if(team == 0) {
			PlayerTeamZero[entity] = true;
			//SetEntProp(entity, Prop_Send, "m_bForcedSkin", 1);
		} else {
			PlayerTeamZero[entity] = false;
			/*if(PlayerFakeTeam[entity] == -1) {
				SetEntProp(entity, Prop_Send, "m_bForcedSkin", 0);
			}*/
		}
	}

	return 1;
}

public void OnClientPutInServer(int client)
{
	/*SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
	if(bSendProxy) {
		SendProxy_Hook(client, "m_iTeamNum", Prop_Int, TeamNumProxy);
	}*/
}

stock int Native_TeamManager_SetEntityFakeTeam(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	int faketeam = GetNativeCell(2);

	if(!IsPlayer(entity)) {
		return 0;
	}

	PlayerFakeTeam[entity] = faketeam;

	/*if(faketeam != -1) {
		SetEntProp(entity, Prop_Send, "m_bForcedSkin", 1);
	} else {
		SetEntProp(entity, Prop_Send, "m_bForcedSkin", 0);
	}*/

	return 1;
}

stock int Native_TeamManager_SetPlayerFF(Handle plugin, int params)
{
	int player = GetNativeCell(1);
	bool ff = GetNativeCell(2);

	PlayerFF[player] = ff;

	if(IsClientInGame(player) && !IsFakeClient(player)) {
		if(ff) {
			SendConVarValue(player, mp_friendlyfire, "1");
			SendConVarValue(player, tf_avoidteammates, "0");
			SendConVarValue(player, tf_avoidteammates_pushaway, "0");
		} else {
			SendConVarValue(player, mp_friendlyfire, "0");
			SendConVarValue(player, tf_avoidteammates, "1");
			SendConVarValue(player, tf_avoidteammates_pushaway, "1");
		}
	}

	return 1;
}

stock Action ConCommand_FF2(int client, int args)
{
	if(args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_ff2 <player/filter> <1/0>");
		return Plugin_Handled;
	}

	char filter[64];
	GetCmdArg(1, filter, sizeof(filter));

	char value[5];
	GetCmdArg(2, value, sizeof(value));

	int intvalue = StringToInt(value);

	char name[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS];
	bool isml = false;
	int count = ProcessTargetString(filter, client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, name, sizeof(name), isml);
	if(count == 0) {
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for(int i = 0; i < count; i++) {
		int target = targets[i];

		TeamManager_SetPlayerFF(target, (intvalue > 0));
	}

	return Plugin_Handled;
}

stock Action ConCommand_JoinTeam(int client, const char[] command, int args)
{
	char arg[32];
	if(args >= 1) {
		GetCmdArg(1, arg, sizeof(arg));
	}

	Call_StartForward(fwCanChangeTeam);
	Call_PushCell(client);
	Call_PushCell(GetTeamIndex(arg));

	bool change = false;
	Call_PushCellRef(change);

	Action result = Plugin_Continue;
	Call_Finish(result);

	if(result == Plugin_Changed) {
		if(!change) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

stock Action ConCommand_ClassMenu(int client, const char[] command, int args)
{
	if(StrEqual(command, "menuopen")) {
		PlayerInVGUI[client] = true;
	} else if(StrEqual(command, "menuclosed")) {
		PlayerInVGUI[client] = false;
	}

	return Plugin_Continue;
}

stock Action ConCommand_JoinClass(int client, const char[] command, int args)
{
	if(StrEqual(command, "changeclass")) {
		if(IsPlayerTeamZero(client)) {
			PlayerInVGUI[client] = true;
		}
	}

	char arg[32];
	if(args >= 1) {
		GetCmdArg(1, arg, sizeof(arg));
	}

	Call_StartForward(fwCanChangeClass);
	Call_PushCell(client);
	Call_PushCell(TF2_GetClass(arg));

	bool change = false;
	Call_PushCellRef(change);

	Action result = Plugin_Continue;
	Call_Finish(result);

	if(result == Plugin_Changed) {
		if(!change) {
			return Plugin_Handled;
		}
	}

	if(IsPlayerTeamZero(client)) {
		TeamInClass[client] = true;
		SetEntityTeam(client, GetRandomInt(2, 3), true);
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
#if defined DEBUG
	Precache();
#endif

	FPlayerCanTakeDamageMapStart();
	PlayerRelationshipMapStart();
}

/*stock void SpawnPost(int entity)
{
	int owner = GetOwner(entity);
	if(IsPlayer(owner)) {
		if(PlayerFakeTeam[owner] != -1 || IsPlayerTeamZero(owner)) {
			if(HasEntProp(entity, Prop_Send, "m_iTeamNumber")) {
				SendProxy_Hook(entity, "m_iTeamNumber", Prop_Int, TeamNumProxy);
			}
			SendProxy_Hook(entity, "m_iTeamNum", Prop_Int, TeamNumProxy);
		}
	}
}*/

public void OnEntityCreated(int entity, const char[] classname)
{
	ShouldCollideEntityCreated(entity, classname);

	/*if(bSendProxy) {
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}*/
}

public void OnEntityDestroyed(int entity)
{
    if(entity < 0) {
        return;
    }

    TryToPickupBuildingDestroyed(entity);
}

stock Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(/*IsPlayerTeamZero(client) || */TeamInClass[client]) {
		TeamInClass[client] = false;
		SetEntityTeam(client, 0, true);
	}

	return Plugin_Continue;
}

stock Action Event_BuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	/*if(bSendProxy) {
		int client = GetClientOfUserId(event.GetInt("userid"));
		int entity = event.GetInt("index");

		if(IsPlayerTeamZero(client)) {
			SendProxy_Hook(entity, "m_iTeamNum", Prop_Int, TeamNumProxy);
		}
	}*/

	return Plugin_Continue;
}

stock Action Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	int old_team = event.GetInt("oldteam");

	if(IsPlayerTeamZero(client) || old_team == 0) {
		if(!TeamInDeath[client]) {
			if(team != 0) {
				PlayerTeamZero[client] = false;
				/*if(PlayerFakeTeam[client] == -1) {
					SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
				}*/
			}
		}
		TeamInDeath[client] = false;
	}

	/*if(team == 0) {
		PlayerTeamZero[client] = true;
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
	}*/

	return Plugin_Continue;
}

stock Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int flags = event.GetInt("death_flags");

	TryToPickupBuildingDisconnect(client);

	if(!(flags & TF_DEATHFLAG_DEADRINGER)) {
		if(IsPlayerTeamZero(client) || TeamInClass[client]) {
			TeamInClass[client] = false;
			TeamInDeath[client] = true;
			if(PlayerFakeTeam[client] != -1) {
				SetEntityTeam(client, PlayerFakeTeam[client], true);
			} else {
				SetEntityTeam(client, GetRandomInt(2, 3), true);
			}
		}
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	TryToPickupBuildingDisconnect(client);

	PlayerTeamZero[client] = false;
	PlayerFF[client] = false;
	PlayerFakeTeam[client] = -1;
	PlayerInVGUI[client] = false;
	TeamInDeath[client] = false;
	TeamInClass[client] = false;
}
