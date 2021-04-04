#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <strlib>

#define FILTERSCRIPT

/*
TODO: - Fix chat colors 
      - Check all cmds
*/


enum {
    RDT = 5,
        SP = 6,
        CIVILIAN = NO_TEAM
}

enum {
    COLOR_RED = 0xFF0000,
        COLOR_GREEN = 0x00FF00,
        COLOR_BLUE = 0x00CCFF,
        COLOR_PURPLE = 0xFF33FF
}


// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))

#define RDT_CAR_COLOR 121
#define SP_CAR_COLOR 211

// SP
new spvehicles[10];

// RDT
new rdtvehicles[10];

static DB:connection;


// ----------------------- GAME CALLBACKS ----------------------- 
public OnFilterScriptInit() {
    loadDB();

    // SP
    addHQSP();
    addVehiclesSP();

    // RDT
    addHQRDT();
    addVehiclesRDT();
}

public OnFilterScriptExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
    return 1;
}

public OnPlayerRequestClass(playerid, classid) {
    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    new query[100];

    format(query, sizeof(query), "SELECT player_faction, faction_rank FROM 'Players' WHERE player_name = '%s'", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new playerFaction[20];
        new playerRank[10];

        db_get_field_assoc(result, "player_faction", playerFaction, sizeof(playerFaction));
        db_get_field_assoc(result, "faction_rank", playerRank, sizeof(playerRank));

        if (isequal(playerFaction, "RDT")) {
            putRDT(playerid);
        } else if (isequal(playerFaction, "SP")) {
            putSP(playerid);
        } else {
            putCivil(playerid);
        }
    }
    db_free_result(result);
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if ((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK)) {
        if (GetPlayerInterior(playerid) == 0) {
            // SP HQ
            if (IsPlayerInRangeOfPoint(playerid, 10, 1454.88538, 751.07147, 11.02340)) {
                SetPlayerInterior(playerid, 18);
                SetPlayerPos(playerid, 1727.2853, -1642.9451, 20.2254);
            }
            // RDT HQ
            if (IsPlayerInRangeOfPoint(playerid, 10, 2633.78174, 1825.46545, 11.02340)) {
                SetPlayerInterior(playerid, 3);
                SetPlayerPos(playerid, -2638.8232, 1407.3395, 906.4609);
            }
        }
        // SP HQ
        if (GetPlayerInterior(playerid) == 18) {
            SetPlayerInterior(playerid, 0);
            SetPlayerPos(playerid, 1454.88538, 751.07147, 11.02340);
        }
        // RDT HQ
        if (GetPlayerInterior(playerid) == 3) {
            SetPlayerInterior(playerid, 0);
            SetPlayerPos(playerid, 2633.78174, 1825.46545, 11.02340);
        }
    }
}

// ----------------------- CORE ----------------------- 

putRDT(playerid) {
    SetSpawnInfo(playerid, RDT, 0, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
    SetPlayerColor(playerid, COLOR_RED);
    SetPlayerInterior(playerid, 3);
    SpawnPlayer(playerid);
}

putSP(playerid) {
    SetSpawnInfo(playerid, SP, 0, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
    SetPlayerColor(playerid, COLOR_PURPLE);
    SetPlayerInterior(playerid, 18);
    SpawnPlayer(playerid);
}

putCivil(playerid) {
    SetSpawnInfo(playerid, CIVILIAN, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
    SetPlayerColor(playerid, -1);
    SpawnPlayer(playerid);
}

checkIfCivil(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT player_faction FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:queryResult = db_query(connection, query);

    if (db_num_rows(queryResult) == 1) {
        new playerFaction[10];

        db_get_field_assoc(queryResult, "player_faction", playerFaction, sizeof(playerFaction));

        db_free_result(queryResult);
        if (isequal(playerFaction, "Civilian")) {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

getPlayerFactionName(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT player_faction, faction_rank FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result) == 1) {
        new playerFaction[9];

        db_get_field_assoc(result, "player_faction", playerFaction, sizeof(playerFaction));

        db_free_result(result);

        return playerFaction;
    } else {
        new response[9];
        response = "Civilian";
        return response;
    }
}

getPlayerFactionRank(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT faction_rank FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result) == 1) {
        new factionRank = db_get_field_assoc_int(result, "faction_rank");

        db_free_result(result);

        return factionRank;
    } else {
        return 0;
    }
}

// ----------------------- SETUPS ----------------------- 

loadDB() {
    connection = db_open("data.db");

    if (connection) {} else {
        print("failed to connect to db");
    }
    new query[256] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank INTEGER NOT NULL)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, owner TEXT NOT NULL, owner_color TEXT NOT NULL, minX INTEGER, minY INTEGER, maxX INTEGER, maxY INTEGER)";
    db_free_result(db_query(connection, query));
}

addVehiclesSP() {
    spvehicles[0] = AddStaticVehicle(522, 1412.7795, 746.3126, 10.3922, 267.8583, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp1
    spvehicles[1] = AddStaticVehicle(522, 1413.5082, 749.2159, 10.3936, 272.6732, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp2
    spvehicles[2] = AddStaticVehicle(522, 1412.5800, 755.8980, 10.3909, 271.5344, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp3
    spvehicles[3] = AddStaticVehicle(522, 1413.1470, 759.3210, 10.3994, 275.6730, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp4
    spvehicles[4] = AddStaticVehicle(411, 1445.7037, 762.5338, 10.5474, 89.8119, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spvehicles[5] = AddStaticVehicle(411, 1445.6853, 743.2895, 10.5474, 90.9583, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spvehicles[6] = AddStaticVehicle(409, 1446.6243, 751.2015, 10.6203, 359.1673, SP_CAR_COLOR, SP_CAR_COLOR); // limosp
    spvehicles[7] = AddStaticVehicle(579, 1413.0048, 752.7371, 10.6317, 269.8256, SP_CAR_COLOR, SP_CAR_COLOR); // huntleysp
}

addHQSP() {
    CreateObject(1239, 1454.88538, 751.07147, 11.02340, 0.00000, 0.00000, 0.00000);
}

addHQRDT() {
    CreateObject(1239, 2633.78174, 1825.46545, 11.02340, 0.00000, 0.00000, 0.00000);
}

addVehiclesRDT() {
    rdtvehicles[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, RDT_CAR_COLOR, RDT_CAR_COLOR); // limordt
    rdtvehicles[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtvehicles[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtvehicles[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtvehicles[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtvehicles[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtvehicles[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtvehicles[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, RDT_CAR_COLOR, RDT_CAR_COLOR); // huntleyrdt
}

// --------------------- COMMANDS --------------------- 

COMMAND:fvr(playerid, params[]) {
    new playerName[30];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new playerFactionRank = getPlayerFactionRank(playerName);


    if (GetPlayerTeam(playerid) == RDT) {
        if (playerFactionRank == 7 ||
            playerFactionRank == 6 ||
            playerFactionRank == 5) {
            new i;
            for (i = 0; i <= 10; i++) {
                SetVehicleToRespawn(rdtvehicles[i]);
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul necesar pentru FVR!");
        }
    } else if (GetPlayerTeam(playerid) == SP) {
        if (playerFactionRank == 7 ||
            playerFactionRank == 6 ||
            playerFactionRank == 5) {
            new i;
            for (i = 0; i <= 10; i++) {
                SetVehicleToRespawn(spvehicles[i]);
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul necesar pentru FVR!");
        }
    }
    return 1;
}

COMMAND:heal(playerid, params[]) {
    if (GetPlayerInterior(playerid) == 3 || GetPlayerInterior(playerid) == 18) {
        SendClientMessage(playerid, 0xFF0000, "Ai luat cox si ai primit heal!");
        SetPlayerHealth(playerid, 100);
    }
    return 1;
}

// needs testing
COMMAND:invitemember(playerid, params[]) {
    new input[2];
    if (sscanf(params, "ii", input[0], input[1])) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /invitemember <id player> <rank>");
    } else {
        new invitedPlayerId = input[0];
        new rank = input[1];

        new invitedName[30];
        GetPlayerName(invitedPlayerId, invitedName, sizeof(invitedName));

        new inviterName[30];
        GetPlayerName(playerid, inviterName, sizeof(inviterName));

        if (checkIfCivil(inviterName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti invita un membru ca civil!");
            return 1;
        }

        new inviterFaction[9];
        inviterFaction = getPlayerFactionName(inviterName);
        new invitedPlayerFaction[9];
        invitedPlayerFaction = getPlayerFactionName(invitedName);

        if (!isequal(invitedPlayerFaction, inviterFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa inviti un jucator din alta mafie!");
            return 1;
        }

        new inviterRank = getPlayerFactionRank(inviterName);

        if (inviterRank < 5) {
            printf("Inviter rank: %d", inviterRank);
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient de mare pentru a invita un player!");
            return 1;
        }
        SetTimerEx("cmd_acceptinvite", 30000, false, "i", playerid);
        SendClientMessage(input[0], COLOR_BLUE, "Ai 30 de secunde pentru a accepta invitatia de a intra in factiune!");
        SendClientMessage(input[0], COLOR_BLUE, "Foloseste /acceptinvite <id lider>");
    }
    return 1;
}

COMMAND:acceptinvite(playerid, params[]) {
    new input[2];
    if (sscanf(params, "i", input[0])) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /acceptinvite <id player>");
    } else {
        new name[30];
        GetPlayerName(input[0], name, sizeof(name));

        if (checkIfCivil(name)) {
            new query[150];
            new playerFaction[5];
            GetPVarString(playerid, "playerFaction", playerFaction, sizeof(playerFaction));

            print(playerFaction);

            format(query, sizeof(query),
                "UPDATE 'Players' SET player_faction = '%s', faction_rank = '%d' WHERE player_name = '%s'", playerFaction, input[1], name);
            if (db_free_result(db_query(connection, query)) >= 1) {
                print("update done");
                new message[50];
                format(message, sizeof(message), "Te-ai alaturat mafiei %s!", playerFaction);
                SendClientMessage(playerid, COLOR_GREEN, message);
            } else {
                print("update failed");
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Player-ul este deja intr-o mafie!");
        }
    }
    return 1;
}

// done testing
COMMAND:resignmember(playerid, params[]) {
    new takerPlayerId;
    if (sscanf(params, "i", takerPlayerId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /resignmember <id player>");
    } else {

        // - get names from players
        new takerPlayerName[30];
        GetPlayerName(takerPlayerId, takerPlayerName, sizeof(takerPlayerName));

        new giverPlayerName[30];
        GetPlayerName(playerid, giverPlayerName, sizeof(giverPlayerName));

        // - check if the giver is a civil
        if (checkIfCivil(giverPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai afara un alt civil!");
            return 1;
        }

        // - faction checking
        new giverFaction[9];
        giverFaction = getPlayerFactionName(giverPlayerName);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerPlayerName);

        if (!isequal(takerFaction, giverFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da afara un jucator din alta mafie!");
            return 1;
        }

        // - rank checking: an inferior can not resign a superior
        // - rank checking: the giver needs to have at least rank 6
        new giverRank = getPlayerFactionRank(giverPlayerName);
        new takerRank = getPlayerFactionRank(takerPlayerName);
        if (giverRank <= takerRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da afara un rank superior!");
            return 1;
        }

        if (5 < giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da afara un membru!");
            return 1;
        }

        new query[150];
        format(query, sizeof(query), "UPDATE 'Players' SET player_faction = 'Civilian', faction_rank = '0' WHERE player_name = '%s'", takerPlayerName);
        if (db_free_result(db_query(connection, query)) >= 1) {
            print("update done");
            new message[100];
            format(message, sizeof(message), "L-ai dat afara pe %s din mafie!", takerPlayerName);
            SendClientMessage(playerid, COLOR_BLUE, message);
        } else {
            print("update failed");
        }
    }
    return 1;
}

COMMAND:rankup(playerid, params[]) {
    return 1;
}

COMMAND:rankdown(playerid, params[]) {
    return 1;
}

// order ranks 
// rank 1:
// rank 2:
// rank 3:
// rank 4:
// rank 5:
// rank 6:

COMMAND:order1(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 1");
    }
    return 1;
}

COMMAND:order2(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 2");
    }
    return 1;
}

COMMAND:order3(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 3");
    }
    return 1;
}

COMMAND:order4(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        GivePlayerWeapon(playerid, 32, 150);
        GivePlayerWeapon(playerid, 27, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 4");
    }
    return 1;
}