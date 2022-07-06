#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgo_colors>

#define PERCENTS 50

bool bDeagle;

bool bVote[MAXPLAYERS+1];

int iCurrentVotes;

Handle hTimer[MAXPLAYERS+1];

public Plugin myinfo = 
{ 
    name = "My Plugin", 
    author = "Quake1011", 
    description = "No desc", 
    version = "1.0", 
    url = "https://github.com/Quake1011/"
}

public void OnPluginStart()
{
    iCurrentVotes = 0;

    HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
    RegAdminCmd("sm_deagle", ToogleDeagle, ADMFLAG_ROOT);
    RegConsoleCmd("sm_deagleon", VotingDeagleOn);
    RegConsoleCmd("sm_deagleoff", VotingDeagleOff);

    LoadTranslations("deagletoggle.phrases.txt")
}

public void OnMapStart()
{
    for(int i = 1;i < MAXPLAYERS+1; i++)
    {
        bVote[i] = false;
    }
    
    iCurrentVotes = 0;
}

public void OnClientDisconnect_Post(client)
{
    bVote[client] = false;
    iCurrentVotes -= 1;
}

public Action VotingDeagleOff(int client, int args)
{
    if(!bVote[client] && bDeagle)
    {
        float fTotal;
        for(int i = 1;i <= MaxClients; i++)
        {
            if(IsClientInGame(i))
            {
                fTotal++;
            }
        }
        char value[10];
        FloatToString(fTotal/100*PERCENTS, value, sizeof(value))
        int iTotal = StringToInt(value);
        iCurrentVotes += 1;
        CGOPrintToChatAll("%t", "player_voted_off", client, iCurrentVotes, iTotal);
        bVote[client] = true;
        for(int j = 1;j <= MaxClients; j++)
        {
            if(IsClientInGame(j) && IsPlayerAlive(j))
            {
                hTimer[j] = CreateTimer(0.1, TimerDel, j, TIMER_FLAG_NO_MAPCHANGE);
                iCurrentVotes = 0;
                bVote[j] = false;
            }
        }
        bDeagle = false;
    }
    else CGOPrintToChat(client, "%t", "off_yet");
    
    return Plugin_Continue;
}

public Action VotingDeagleOn(int client, int args)
{
    if(!bVote[client] && !bDeagle)
    {
        float fTotal;
        for(int i = 1;i <= MaxClients; i++)
        {
            if(IsClientInGame(i))
            {
                fTotal++;
            }
        }
        char value[10];
        FloatToString(fTotal/100*PERCENTS, value, sizeof(value))
        int iTotal = StringToInt(value);
        iCurrentVotes++;
        CGOPrintToChatAll("%t", "player_voted_on", client, iCurrentVotes, iTotal);
        bVote[client] = true;
        if(iCurrentVotes == iTotal)
        {
            for(int j = 1;j <= MaxClients; j++)
            {
                if(IsClientInGame(j) && IsPlayerAlive(j))
                {
                    float fOrig[3];
                    int deagle;
                    GetClientAbsOrigin(j, fOrig);
                    deagle = CreateEntityByName("weapon_deagle");
                    DispatchKeyValueVector(deagle, "origin", fOrig);
                    DispatchSpawn(deagle);
                    iCurrentVotes = 0;
                    bVote[j] = false;
                }
            }
            bDeagle = true;
        }
    }
    else CGOPrintToChat(client, "%t", "on_yet");

    return Plugin_Continue;
}

public Action ToogleDeagle(int client, int args)
{
    if(!bDeagle)
    {
        for(int i = 1;i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i))
            {
                float fOrig[3];
                int deagle;
                GetClientAbsOrigin(i, fOrig);
                deagle = CreateEntityByName("weapon_deagle");
                DispatchKeyValueVector(deagle, "origin", fOrig);
                DispatchSpawn(deagle);
                iCurrentVotes = 0;
                bVote[i] = false;
            }
        }
        bDeagle = true;
    }
    else
    {
        for(int i = 1;i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i))
            {
                hTimer[i] = CreateTimer(0.1, TimerDel, i, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        bDeagle = false;
    }
    CGOPrintToChatAll("%t %t", "deagle", bDeagle?"on":"off");
    return Plugin_Continue;
}

public void EventPlayerSpawn(Event hEvent, const char[] sEvent, bool bdb)
{
    int i = GetClientOfUserId(hEvent.GetInt("userid"));
    hTimer[i] = CreateTimer(0.2, TimerDel, i, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerDel(Handle NewTimer, client)
{
    if(!bDeagle)
    {
        if(client)
        {
            if(IsClientInGame(client))
            {
                if(IsPlayerAlive(client))
                {
                    char weapon[20];
                    int idx = GetPlayerWeaponSlot(client, 1);
                    if(IsValidEntity(idx))
                    {
                        GetEntityClassname(idx, weapon, sizeof(weapon));
                        if(StrEqual(weapon, "weapon_deagle"))
                        {
                            CS_DropWeapon(client, idx, true);
                            RemoveEntity(idx);
                            bVote[client] = false;
                        }
                    } 
                }
            }
        }
        if(hTimer[client]!=INVALID_HANDLE)
        {
            KillTimer(hTimer[client]);
            hTimer[client]=null;        
        }
    }
    return Plugin_Continue;
}
