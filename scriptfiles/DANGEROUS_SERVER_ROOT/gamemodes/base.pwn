#include <a_samp>

#define FIXES_ServerVarMsg 0
#define FIXES_GetMaxPlayersMsg 0

#include <fixes> 
#include <izcmd>
#include <sscanf2>
#include <a_zone>
#include <strlib>
#include <samp_bcrypt>
#include <tdw_dialog>

#define BCRYPT_COST 12

#define DIALOG_LOGIN 1337
#define DIALOG_REGISTER 1338

// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))

#define RDT_CAR_COLOR 121
#define SP_CAR_COLOR 211

enum {
    COLOR_RED = 0xFF0000,
        COLOR_GREEN = 0x7FFF00,
        COLOR_BLUE = 0x0FFFF,
        COLOR_PURPLE = 0x8A2BE2
}

enum {
    RDT = 5,
        SP = 6,
        CIVILIAN = NO_TEAM
}

enum Player {
    mafia[9],
        rank,
        kills,
        deaths,
        bests,
        worths
}

// SP
new spVehiclesVw1[10];
new spVehiclesVw2[10];

// RDT
new rdtVehiclesVw1[10];
new rdtVehiclesVw2[10];

// all turfs 
new turfs[24];

static DB:connection;

main() {
    print("\n----------------------------------");
    print("      War Between Mafia System");
    print("             By Danix43");
    print("----------------------------------\n");
}

public OnGameModeInit() {
    SetGameModeText("War Between Mafia System");
    UsePlayerPedAnims();
    DisableInteriorEnterExits();
    createDBs();
    loadTurfs();

    setupRDT();
    setupSP();
    return 1;
}

public OnGameModeExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
    return 1;
}

public OnPlayerConnect(playerid) {
    new query[100];

    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    format(query, sizeof(query), "SELECT player_name FROM 'Players' where player_name = '%s'", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result) == 1) {
        OpenDialog(playerid, "loginPlayer", DIALOG_STYLE_PASSWORD, "Login", "Login using your password", "Login", "Cancel");
    } else if (db_num_rows(result) == 0) {
        OpenDialog(playerid, "registerPlayer", DIALOG_STYLE_PASSWORD, "Register", "Register using your password", "Register", "Cancel");
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
    SendDeathMessage(killerid, playerid, reason);

    if (killerid != INVALID_PLAYER_ID) {
        new playerKills = GetPVarInt(killerid, "kills");
        SetPVarInt(killerid, "kills", playerKills++);
        pointFromKill(playerid, killerid);
    }

    new playerDeaths = GetPVarInt(playerid, "deaths");
    SetPVarInt(playerid, "deaths", playerDeaths++);

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
        new playerRank;

        db_get_field_assoc(result, "player_faction", playerFaction, sizeof(playerFaction));
        playerRank = db_get_field_assoc_int(result, "faction_rank");

        if (isequal(playerFaction, "RDT")) {
            putRDT(playerid, playerRank);
        } else if (isequal(playerFaction, "SP")) {
            putSP(playerid, playerRank);
        } else {
            putCivil(playerid);
        }
    }
    db_free_result(result);
    return 1;
}

public OnPlayerSpawn(playerid) {
    switch (GetPlayerTeam(playerid)) {
        case RDT:
            SetPlayerInterior(playerid, 3);
        case SP:
            SetPlayerInterior(playerid, 18);
        case CIVILIAN:
            SetPlayerInterior(playerid, 0);
    }
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

// ----------------------- SETUPS ----------------------- 

setupRDT() {
    // hq object
    CreateObject(1239, 2633.78174, 1825.46545, 11.02340, 0.00000, 0.00000, 0.00000);

    // vehicles virtual world 1
    rdtVehiclesVw1[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, RDT_CAR_COLOR, RDT_CAR_COLOR); // limordt
    rdtVehiclesVw1[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw1[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw1[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw1[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw1[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw1[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw1[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, RDT_CAR_COLOR, RDT_CAR_COLOR); // huntleyrdt

    // vehicles virtual world 2
    rdtVehiclesVw2[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, RDT_CAR_COLOR, RDT_CAR_COLOR); // limordt
    rdtVehiclesVw2[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw2[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw2[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, RDT_CAR_COLOR, RDT_CAR_COLOR); // huntleyrdt
}

setupSP() {
    // hq object
    CreateObject(1239, 1454.88538, 751.07147, 11.02340, 0.00000, 0.00000, 0.00000);

    // vehicles virtual world 1
    spVehiclesVw1[0] = AddStaticVehicle(522, 1412.7795, 746.3126, 10.3922, 267.8583, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp1
    spVehiclesVw1[1] = AddStaticVehicle(522, 1413.5082, 749.2159, 10.3936, 272.6732, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp2
    spVehiclesVw1[2] = AddStaticVehicle(522, 1412.5800, 755.8980, 10.3909, 271.5344, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp3
    spVehiclesVw1[3] = AddStaticVehicle(522, 1413.1470, 759.3210, 10.3994, 275.6730, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp4
    spVehiclesVw1[4] = AddStaticVehicle(411, 1445.7037, 762.5338, 10.5474, 89.8119, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spVehiclesVw1[5] = AddStaticVehicle(411, 1445.6853, 743.2895, 10.5474, 90.9583, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spVehiclesVw1[6] = AddStaticVehicle(409, 1446.6243, 751.2015, 10.6203, 359.1673, SP_CAR_COLOR, SP_CAR_COLOR); // limosp
    spVehiclesVw1[7] = AddStaticVehicle(579, 1413.0048, 752.7371, 10.6317, 269.8256, SP_CAR_COLOR, SP_CAR_COLOR); // huntleysp

    // vehicles virtual world 2
    spVehiclesVw2[0] = AddStaticVehicle(522, 1412.7795, 746.3126, 10.3922, 267.8583, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp1
    spVehiclesVw2[1] = AddStaticVehicle(522, 1413.5082, 749.2159, 10.3936, 272.6732, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp2
    spVehiclesVw2[2] = AddStaticVehicle(522, 1412.5800, 755.8980, 10.3909, 271.5344, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp3
    spVehiclesVw2[3] = AddStaticVehicle(522, 1413.1470, 759.3210, 10.3994, 275.6730, SP_CAR_COLOR, SP_CAR_COLOR); // nrgsp4
    spVehiclesVw2[4] = AddStaticVehicle(411, 1445.7037, 762.5338, 10.5474, 89.8119, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spVehiclesVw2[5] = AddStaticVehicle(411, 1445.6853, 743.2895, 10.5474, 90.9583, SP_CAR_COLOR, SP_CAR_COLOR); // infsp
    spVehiclesVw2[6] = AddStaticVehicle(409, 1446.6243, 751.2015, 10.6203, 359.1673, SP_CAR_COLOR, SP_CAR_COLOR); // limosp
    spVehiclesVw2[7] = AddStaticVehicle(579, 1413.0048, 752.7371, 10.6317, 269.8256, SP_CAR_COLOR, SP_CAR_COLOR); // huntleysp
}

// ----------------------- CORE ----------------------- 

putRDT(playerid, rank) {
    switch (rank) {
        case 1:
            SetSpawnInfo(playerid, RDT, 117, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 2:
            SetSpawnInfo(playerid, RDT, 118, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 3:
            SetSpawnInfo(playerid, RDT, 118, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 4:
            SetSpawnInfo(playerid, RDT, 208, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 5:
            SetSpawnInfo(playerid, RDT, 208, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 6:
            SetSpawnInfo(playerid, RDT, 120, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        case 7:
            SetSpawnInfo(playerid, RDT, 120, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
        default:
            SetSpawnInfo(playerid, RDT, 2, -2638.8232, 1407.3395, 906.4609, 269.15, 0, 0, 0, 0, 0, 0);
    }
    SetPlayerInterior(playerid, 3);
    SetPlayerColor(playerid, COLOR_RED);
    SpawnPlayer(playerid);
}

putSP(playerid, rank) {
    switch (rank) {
        case 1:
            SetSpawnInfo(playerid, SP, 104, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 2:
            SetSpawnInfo(playerid, SP, 102, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 3:
            SetSpawnInfo(playerid, SP, 102, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 4:
            SetSpawnInfo(playerid, SP, 185, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 5:
            SetSpawnInfo(playerid, SP, 185, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 6:
            SetSpawnInfo(playerid, SP, 296, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        case 7:
            SetSpawnInfo(playerid, SP, 296, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
        default:
            SetSpawnInfo(playerid, SP, 4, 1727.2853, -1642.9451, 20.2254, 269.15, 0, 0, 0, 0, 0, 0);
    }
    SetPlayerInterior(playerid, 18);
    SetPlayerColor(playerid, COLOR_PURPLE);
    SpawnPlayer(playerid);
}

putCivil(playerid) {
    SetSpawnInfo(playerid, CIVILIAN, 24, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
    SetPlayerColor(playerid, -1);
    SpawnPlayer(playerid);
}

checkIfCivil(playerid) {
    if (GetPlayerTeam(playerid) == CIVILIAN) {
        return true;
    }
    return false;
}

getPlayerFactionName(playerid) {
    new factionName[4];
    switch (GetPlayerTeam(playerid)) {
        case RDT:  {
            factionName = "RDT";
            return factionName;
        }
        case SP:  {
            factionName = "SP";
            return factionName;
        }
        case CIVILIAN:  {
            factionName = "CIVILIAN";
            return factionName;
        }
    }
}

getPlayerFactionRank(playerid) {
    new playerName[30];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new query[150];

    format(query, sizeof(query), "SELECT faction_rank FROM 'Players' WHERE player_name = '%s'", playerName);

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result) == 1) {
        new factionRank = db_get_field_assoc_int(result, "faction_rank");

        db_free_result(result);

        return factionRank;
    } else {
        return 0;
    }
}

// ----------------------- DB RELATED ----------------------- 

createDBs() {
    connection = db_open("data.db");

    if (connection) {} else {
        print("failed to connect to db");
    }

    new query[386] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank INTEGER NOT NULL, player_kills INTEGER, player_deaths INTEGER, player_bests INTEGER, player_worths INTEGER)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, turf_name TEXT NOT NULL, turf_number INTEGER NOT NULL, owner TEXT NOT NULL, attacked TEXT NOT NULL DEFAULT 'false', minX REAL, minY REAL, maxX REAL, maxY REAL, poiX REAL, poiY REAL, poiZ REAL)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Wars' (war_id INTEGER PRIMARY KEY, turf_id INTEGER NOT NULL, defender TEXT NOT NULL, attacker TEXT NOT NULL, count INTEGER, FOREIGN KEY (turf_id) REFERENCES Turfs (turf_id))";
    db_free_result(db_query(connection, query));
}

loadTurfs() {
    new query[50];

    for (new i = 0; i <= 24; i++) {
        format(query, sizeof(query), "SELECT turf_number, minX, minY, maxX, maxY FROM 'Turfs' WHERE turf_id = %d", i);

        new DBResult:queryResult = db_query(connection, query);
        if (db_num_rows(queryResult)) {
            new turfNumber;
            new Float:turfMinX;
            new Float:turfMinY;
            new Float:turfMaxX;
            new Float:turfMaxY;

            turfNumber = db_get_field_assoc_int(queryResult, "turf_number");
            turfMinX = Float:db_get_field_assoc_float(queryResult, "minX");
            turfMinY = Float:db_get_field_assoc_float(queryResult, "minY");
            turfMaxX = Float:db_get_field_assoc_float(queryResult, "maxX");
            turfMaxY = Float:db_get_field_assoc_float(queryResult, "maxY");

            turfs[turfNumber] = CreateZone(turfMinX, turfMinY, turfMaxX, turfMaxY);
            CreateZoneBorders(turfs[turfNumber]);
            CreateZoneNumber(turfs[turfNumber], turfNumber, 0.7);

            db_next_row(queryResult);
        }
        db_free_result(queryResult);
    }
}

loadDataForAttack() {
    new query[100];
    new returnData[550];

    new headers[33];
    headers = "Turf Number\tTurf Name\tOwner\n";
    strcatmid(returnData, headers);

    for (new i = 1; i <= 24; i++) {
        format(query, sizeof(query), "SELECT turf_name, turf_number, owner, attacked FROM 'Turfs' WHERE turf_number = %d", i);

        new DBResult:queryResult = db_query(connection, query);
        if (db_num_rows(queryResult)) {
            new turfAttacked[6];

            db_get_field_assoc(queryResult, "attacked", turfAttacked, sizeof(turfAttacked));

            new trueStr[6];
            trueStr = "true";
            if (isequal(turfAttacked, trueStr)) {
                db_next_row(queryResult);
            }

            new turfName[15];
            new turfNumber;
            new turfOwner[5];

            db_get_field_assoc(queryResult, "turf_name", turfName, sizeof(turfName));
            turfNumber = db_get_field_assoc_int(queryResult, "turf_number");
            db_get_field_assoc(queryResult, "owner", turfOwner, sizeof(turfOwner));

            new temp[60];
            format(temp, sizeof(temp), "%d\t%s\t%s\n", turfNumber, turfName, turfOwner);

            strcatmid(returnData, temp);

            db_next_row(queryResult);
        }
        db_free_result(queryResult);
    }
    return returnData;
}

forward savePlayerStats(playerid);
public savePlayerStats(playerid) {

}

dialog loginPlayer(playerid, response, listitem, inputtext[]) {
    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    new query[512];

    format(query, sizeof(query), "SELECT player_password FROM 'Players' where player_name = '%s'", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new playerPassword[250];

        db_get_field_assoc(result, "player_password", playerPassword, 250);

        bcrypt_verify(playerid, "OnPasswordVerify", inputtext, playerPassword);
    }
}

dialog registerPlayer(playerid, response, listitem, inputtext[]) {
    bcrypt_hash(playerid, "OnPasswordHash", inputtext, BCRYPT_COST);
}

dialog attack(playerid, response, listitem, inputtext[]) {
    if (response == 0) {
        return;
    }

    new message[100];
    format(message, sizeof(message), "Input: response: %d, listitem: %d, inputtext: %s", response, listitem, inputtext);

    SendClientMessage(playerid, 0xFFFFFFFF, message);
}

forward OnPasswordHash(playerid);
public OnPasswordHash(playerid) {
    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    new hashedPass[250];
    bcrypt_get_hash(hashedPass);

    new query[512];

    format(query, sizeof(query),
        "INSERT INTO 'Players' (player_name, player_password, player_faction, faction_rank) VALUES ('%s', '%s', 'Civilian', '0')", name, hashedPass);

    if (db_free_result(db_query(connection, query)) >= 1) {
        print("Insert query done");
    } else {
        print("Insert query failed");
    }
}

forward OnPasswordVerify(playerid, bool:success);
public OnPasswordVerify(playerid, bool:success) {
    if (success) {
        SendClientMessage(playerid, -1, "Your logged in!");
    } else {
        SendClientMessage(playerid, 0xFF0000FF, "Login failed!");
        SetTimerEx("KickWithDelay", 1000, false, "i", playerid);
    }
}

forward KickWithDelay(playerid);
public KickWithDelay(playerid) {
    Kick(playerid);
    return 1;
}

preparePlayersForWar() {
    SendClientMessageToAll(COLOR_PURPLE, "War-urile intre mafii vor incepe incurand!");
    SendClientMessageToAll(COLOR_PURPLE, "Toti mafiotii vor fi respawnati la HQ-uri in cateva secunde");
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (IsPlayerConnected(i)) {
            new playerName[30];
            GetPlayerName(i, playerName, sizeof(playerName));

            if (!checkIfCivil(playerName)) {
                SpawnPlayer(i);
                SetPlayerVirtualWorld(i, 2);

                SendClientMessage(i, COLOR_PURPLE, "Ai fost respawnat la HQ deoarece va incepe war-ul");
                displayWarTextDraw(i);
            }
        }
    }
}

prepareTurf(turfIdForWar) {
    new query[150];
    format(query, sizeof(query), "SELECT turf_number FROM Turfs WHERE turf_id = %d", turfIdForWar);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new turfNumber;
        turfNumber = db_get_field_assoc_int(result, "turf_number");
        GangZoneFlashForAll(turfs[turfNumber], 0xFFFFFFAA);
    }
    db_free_result(result);
}

displayWarTextDraw(playerid) {

}

getPlayersOnTurf(playerMafia[], poiX, poiY, poiZ) {
    new players;
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (GetPlayerVirtualWorld(i) == 2) {
            new playerName[30];
            GetPlayerName(i, playerName, sizeof(playerName));

            if (IsPlayerInRangeOfPoint(i, 250, poiX, poiY, poiZ)) {
                if (isequal(getPlayerFactionName(playerName), playerMafia)) {
                    players = players + 1;
                }
            }
        }
    }
    return players;
}

pointFromKill(playerid, killerid) {
    if (GetPlayerVirtualWorld(playerid) == 2 && GetPlayerVirtualWorld(killerid) == 2) {
        // both are in war vw
        new killerFaction[9];
        killerFaction = getPlayerFactionName(killerid);

        new rdtName[9], spName[9];
        rdtName = "RDT";
        spName = "SP";
        if (isequal(killerFaction, rdtName)) {
            new pointRDT = GetSVarInt("pointsRDT");
            SetSVarInt("pointsRDT", (pointRDT + 1));
        } else if (isequal(killerFaction, spName)) {
            new pointSP = GetSVarInt("pointsSP");
            SetSVarInt("pointsSP", (pointSP + 1));
        }
    }
}

calculateBestPlayer(playerid) {
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (GetPlayerVirtualWorld(playerid) == 2) {
            new playerKills = GetPVarInt(playerid, "kills");
            new playerDeaths = GetPVarInt(playerid, "deaths");

            new playerKDA = playerKills - playerDeaths;
        }
    }
}

calculateWorstPlayer(playerid) {

}

/*
use setimerex for time related activs
ex: settimerex(pointforinfluence, 30000);
    pointforinfluence() {
        checks for total players on turf 
        gives point for most of the same mafia on turf
    }
*/
new influenceTimer;
startWar() {
    new query[150];

    format(query, sizeof(query), "SELECT * FROM 'Wars' ORDER BY war_id ASC LIMIT 1");

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result)) {
        new defender[4];
        new attacker[4];
        new warCount;
        new turfId;

        db_get_field_assoc(result, "attacker", attacker, sizeof(attacker));
        db_get_field_assoc(result, "defender", defender, sizeof(defender));
        warCount = db_get_field_assoc_int(result, "count");
        turfId = db_get_field_assoc_int(result, "turf_id");

        new startMessage[50];
        format(startMessage, sizeof(startMessage), "%s vor ataca turf-ul %d detinut de mafia %s", attacker, turfId, defender);
        SendClientMessageToAll(COLOR_PURPLE, startMessage);

        prepareTurf(turfId);
        SetSVarInt("pointsRDT", 0);
        SetSVarInt("pointsSP", 0);
        SetSVarString("isWarOn", "true");

        influenceTimer = SetTimer("pointFromInfluence", 37500, true);

    } else {
        SendClientMessageToAll(COLOR_RED, "Nu exista war-uri pentru azi");
    }
    db_free_result(result);
}

forward pointFromInfluence(turfIdForWar);
public pointFromInfluence(turfIdForWar) {
    new query[150];
    format(query, sizeof(query), "SELECT poiX, poiY, poiZ FROM Turfs WHERE turf_id = %d", turfIdForWar);
    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new Float:poiX, Float:poiY, Float:poiZ;

        poiX = db_get_field_assoc_float(result, "poiX");
        poiY = db_get_field_assoc_float(result, "poiY");
        poiZ = db_get_field_assoc_float(result, "poiZ");

        new playersRDT, playersSP;
        new rdtName[9];
        rdtName = "RDT";
        new spName[9];
        spName = "SP";
        playersRDT = getPlayersOnTurf(rdtName, poiX, poiY, poiZ);
        playersSP = getPlayersOnTurf(spName, poiX, poiY, poiZ);

        if (playersRDT > playersSP) {
            new pointRDT = GetSVarInt("pointsRDT");
            SetSVarInt("pointsRDT", (pointRDT + 1));
        } else if (playersRDT < playersSP) {
            new pointSP = GetSVarInt("pointsSP");
            SetSVarInt("pointsSP", (pointSP + 1));
        } else {}
    }
}

/*
should delete the played war from db
*/
endWar() {

}

// ----------------------- COMMANDS ----------------------- 

COMMAND:setskin(playerid, params[]) {
    new skinid;
    if (sscanf(params, "i", skinid)) {
        SendClientMessage(playerid, -1, "Foloseste: /setskin [skinid]");
    } else {
        SetPlayerSkin(playerid, skinid);
    }
    return 1;
}

COMMAND:help(playerid) {
    SendClientMessage(playerid, 0xF5E342FF, "Comenzi disponibile: ");
    SendClientMessage(playerid, 0xF5E342FF, "- /turfs - arata turfurile mafiilor");
    SendClientMessage(playerid, 0xF5E342FF, "- /order1-4 - pentru arme");
    SendClientMessage(playerid, 0xF5E342FF, "- /fvr - pentru a respawna toate masinile");
    SendClientMessage(playerid, 0xF5E342FF, "- /fvr (rdt / sp) - pentru a respawna masinile unei mafii");
    SendClientMessage(playerid, 0xF5E342FF, "- /setskin id - pentru a primi skinul dorit");
    SendClientMessage(playerid, 0xF5E342FF, "- /heal - pentru a primi heal");
    return 1;
}

COMMAND:id(playerid, params[]) {
    new id;
    if (sscanf(params, "u", id)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /id [id|nume player]");
    } else {
        SendClientMessage(playerid, COLOR_GREEN, "Inca nu s-a adaugat, asa ca asteapta in morti tai");
    }
    return 1;
}

COMMAND:turfs(playerid, params[]) {
    new query[150];

    format(query, sizeof(query), "SELECT turf_number, owner FROM 'Turfs'");

    new DBResult:result = db_query(connection, query);
    for (new i = 1; i <= db_num_rows(result); i++) {
        new turfNumber;
        new turfOwner[4];

        turfNumber = db_get_field_assoc_int(result, "turf_number");
        db_get_field_assoc(result, "owner", turfOwner, sizeof(turfOwner));

        new rdtName[4];
        rdtName = "RDT";
        new spName[4];
        spName = "SP";

        if (isequal(turfOwner, rdtName)) {
            ShowZoneForPlayer(playerid, turfs[turfNumber], 0xFF0000AA, 0xFFFFFFFF, 0xFFFFFFFF);
        } else if (isequal(turfOwner, spName)) {
            ShowZoneForPlayer(playerid, turfs[turfNumber], 0x9400D3AA, 0xFFFFFFFF, 0xFFFFFFFF);
        }
        db_next_row(result);
    }
    db_free_result(result);
    return 1;
}

COMMAND:testwar1(playerid, params[]) {
    preparePlayersForWar();
}

/*
 - attack a turf
 should be only 4 attacks on a sesh
*/
COMMAND:attack(playerid, params[]) {
    new turfData[550];
    turfData = loadDataForAttack();

    OpenDialog(playerid, "attack", DIALOG_STYLE_TABLIST_HEADERS,
        "Attack Menu",
        turfData,
        "Attack", "");
    return 1;
}

COMMAND:fvr(playerid, params[]) {
    new playerFactionRank = getPlayerFactionRank(playerid);

    if (GetPlayerTeam(playerid) == RDT) {
        if (playerFactionRank == 7 ||
            playerFactionRank == 6 ||
            playerFactionRank == 5) {
            new i;
            for (i = 0; i <= 10; i++) {
                SetVehicleToRespawn(rdtVehiclesVw1[i]);
                SetVehicleToRespawn(rdtVehiclesVw2[i]);
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
                SetVehicleToRespawn(spVehiclesVw1[i]);
                SetVehicleToRespawn(spVehiclesVw2[i]);
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul necesar pentru FVR!");
        }
    }
    return 1;
}

COMMAND:heal(playerid, params[]) {
    if (GetPlayerInterior(playerid) == 3 || GetPlayerInterior(playerid) == 18) {
        SendClientMessage(playerid, COLOR_GREEN, "Ai luat cox si ai primit heal!");
        SetPlayerHealth(playerid, 100);
    }
    return 1;
}

new inviteTimer[1000];
// done testing, may need to update killtimer
COMMAND:invitemember(playerid, params[]) {
    new takerId;
    if (sscanf(params, "i", takerId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /invitemember <id player>");
    } else {
        // - get names from players
        new takerPlayerName[30];
        GetPlayerName(takerId, takerPlayerName, sizeof(takerPlayerName));

        new giverPlayerName[30];
        GetPlayerName(playerid, giverPlayerName, sizeof(giverPlayerName));

        // check if the inviter is a civil
        if (checkIfCivil(giverPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti invita un membru ca civil!");
            return 1;
        }

        // get the faction from the players
        new giverFaction[9];
        giverFaction = getPlayerFactionName(giverPlayerName);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerPlayerName);

        // check if the taker is a civilian 
        new civilianFaction[9];
        civilianFaction = "Civilian";
        if (isequal(takerFaction, civilianFaction)) {
            // the giver should have at least rank 6
            new giverRank = getPlayerFactionRank(giverPlayerName);
            if (giverRank < 5) {
                SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient de mare pentru a invita un player!");
                return 1;
            }

            // all conditions met, sending request
            new message[50];
            format(message, sizeof(message), "Ai trimis o invitatie catre id: %d", takerId);
            SendClientMessage(playerid, COLOR_BLUE, message);
            inviteTimer[playerid] = SetTimerEx("cmd_acceptinvite", 30000, false, "i", playerid);
            SendClientMessage(takerId, COLOR_BLUE, "Ai 30 de secunde pentru a accepta invitatia de a intra in factiune!");
            SendClientMessage(takerId, COLOR_BLUE, "Foloseste /acceptinvite <id lider>");
            return 1;
        }
    }
    return 1;
}

COMMAND:acceptinvite(playerid, params[]) {
    new giverId;
    if (sscanf(params, "i", giverId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /acceptinvite <id player>");
    } else {
        new giverName[30];
        GetPlayerName(giverId, giverName, sizeof(giverName));

        new takerName[30];
        GetPlayerName(playerid, takerName, sizeof(takerName));

        // can't join the civilian
        if (checkIfCivil(giverName)) {
            return 1;
        }

        // check if the invited player is a civil; check already done in invitemember
        if (checkIfCivil(takerName)) {
            // get the inviter player faction
            new giverFaction[9];
            giverFaction = getPlayerFactionName(giverName);

            new query[150];
            format(query, sizeof(query),
                "UPDATE 'Players' SET player_faction = '%s', faction_rank = 1 WHERE player_name = '%s'", giverFaction, takerName);

            if (db_free_result(db_query(connection, query)) >= 1) {
                new message[60];
                format(message, sizeof(message), "Te-ai alaturat mafiei %s!", giverFaction);
                SendClientMessage(playerid, COLOR_GREEN, message);
                KillTimer(inviteTimer[giverId]);
            } else {
                print("update failed");
                KillTimer(inviteTimer[giverId]);
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Player-ul este deja intr-o mafie!");
            KillTimer(inviteTimer[giverId]);
        }
    }
    return 1;
}

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
        if (5 > giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da afara un membru!");
            return 1;
        }

        // - every step checks up: do update
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
    new takerId;
    if (sscanf(params, "i", takerId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /rankup <id player>");
    } else {
        new takerPlayerName[30];
        GetPlayerName(takerId, takerPlayerName, sizeof(takerPlayerName));

        new giverPlayerName[30];
        GetPlayerName(playerid, giverPlayerName, sizeof(giverPlayerName));

        // check if the target is a civil
        if (checkIfCivil(takerPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-up unui civil!");
            return 1;
        }

        // - check if the giver is a civil
        if (checkIfCivil(giverPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai rank-up unui alt civil!");
            return 1;
        }

        // check if the target is the same faction as the giver
        new giverFaction[9];
        giverFaction = getPlayerFactionName(giverPlayerName);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerPlayerName);

        if (!isequal(takerFaction, giverFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-up unui jucator din alta mafie!");
            return 1;
        }

        // rank checking
        new giverRank = getPlayerFactionRank(giverPlayerName);
        new takerRank = getPlayerFactionRank(takerPlayerName);
        if (giverRank <= takerRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da sa dai rank-up un rank superior!");
            return 1;
        }
        if (5 > giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da rank-up unui membru!");
            return 1;
        }

        // checking the current rank
        if (takerRank == 6) {
            SendClientMessage(playerid, COLOR_RED, "Membrul are deja rank 6, considera de a-l promova la lider.");
            return 1;
        }
        new newPlayerRank = takerRank + 1;

        // - every step checks up: do update
        new query[150];
        format(query, sizeof(query), "UPDATE 'Players' SET faction_rank = %d WHERE player_name = '%s'", newPlayerRank, takerPlayerName);
        if (db_free_result(db_query(connection, query)) >= 1) {
            print("update done");
            new messageTaker[100];
            format(messageTaker, sizeof(messageTaker), "Ai primit rank-up. Nou tau rank este: %d", newPlayerRank);
            SendClientMessage(takerId, COLOR_BLUE, messageTaker);
            new messageGiver[100];
            format(messageGiver, sizeof(messageGiver), "I-ai dat rank-ul: %d lui %s.", newPlayerRank, takerPlayerName);
            SendClientMessage(takerId, COLOR_BLUE, messageGiver);
        } else {
            print("update failed");
        }
    }
    return 1;
}

COMMAND:rankdown(playerid, params[]) {
    new takerId;
    if (sscanf(params, "i", takerId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /rankdown <id player>");
    } else {
        new takerPlayerName[30];
        GetPlayerName(takerId, takerPlayerName, sizeof(takerPlayerName));

        new giverPlayerName[30];
        GetPlayerName(playerid, giverPlayerName, sizeof(giverPlayerName));

        // check if the target is a civil
        if (checkIfCivil(takerPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-down unui civil!");
            return 1;
        }

        // - check if the giver is a civil
        if (checkIfCivil(giverPlayerName)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai rank-down unui alt civil!");
            return 1;
        }

        // check if the target is the same faction as the giver
        new giverFaction[9];
        giverFaction = getPlayerFactionName(giverPlayerName);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerPlayerName);

        if (!isequal(takerFaction, giverFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-down unui jucator din alta mafie!");
            return 1;
        }

        // rank checking
        new giverRank = getPlayerFactionRank(giverPlayerName);
        new takerRank = getPlayerFactionRank(takerPlayerName);
        if (giverRank <= takerRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da sa dai rank-down un rank superior!");
            return 1;
        }
        if (5 > giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da rank-down unui membru!");
            return 1;
        }

        // checking the current rank
        if (takerRank == 1) {
            SendClientMessage(playerid, COLOR_RED, "Membrul are deja rank 1, considera de a-l da afara din mafie.");
            return 1;
        }
        new newPlayerRank = takerRank - 1;

        // - every step checks up: do update
        new query[150];
        format(query, sizeof(query), "UPDATE 'Players' SET faction_rank = %d WHERE player_name = '%s'", newPlayerRank, takerPlayerName);
        if (db_free_result(db_query(connection, query)) >= 1) {
            print("update done");
            new messageTaker[100];
            format(messageTaker, sizeof(messageTaker), "Ai primit rank-down. Nou tau rank este: %d", newPlayerRank);
            SendClientMessage(takerId, COLOR_BLUE, messageTaker);
            new messageGiver[100];
            format(messageGiver, sizeof(messageGiver), "I-ai dat rank-ul: %d lui %s.", newPlayerRank, takerPlayerName);
            SendClientMessage(takerId, COLOR_BLUE, messageGiver);
        } else {
            print("update failed");
        }
    }
    return 1;
}

// show the upcoming wars
// display on chat as plain text
// or inside dialogs 
COMMAND:upcomingwars(playerid, params[]) {
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