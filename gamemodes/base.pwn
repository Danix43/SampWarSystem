#include <a_samp>

#define FIXES_GetMaxPlayersMsg 0

#include <fixes> 
#include <izcmd>
#include <sscanf2>
#include <samp_bcrypt>
#include <a_zone>
#include <tdw_dialog>
#include <strlib>

#define BCRYPT_COST 12

#define DIALOG_LOGIN 1337
#define DIALOG_REGISTER 1338

// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))

enum {
    COLOR_RED = 0xFF0000FF,
        COLOR_GREEN = 0x00FF00FF,
        COLOR_BLUE = 0x00FFFFFF,
        COLOR_PURPLE = 0x8A2BE2FF,
        COLOR_GREY = 0xAAAAAAFF,
        COLOR_WHITE = 0xFFFFFFFF
}

enum {
    RDT = 5,
        SP = 6,
        CIVILIAN = NO_TEAM
}

enum PlayerStats {
    faction,
    rank,
    kills,
    warKills,
    deaths,
    warDeaths,
    kda,
    warKda,
    bests,
    worsts
}
new players[MAX_PLAYERS][PlayerStats];

enum Turf {
    id,
    owner,
    Float:poiX,
    Float:poiY,
    Float:poiZ
}

// all turfs 
new turfs[25][Turf];

// SP
new spVehiclesVw1[10];
new spVehiclesVw2[10];

// RDT
new rdtVehiclesVw1[10];
new rdtVehiclesVw2[10];

#define RDT_CAR_COLOR 121
#define SP_CAR_COLOR 211

#define INTERIOR_RDT 3
#define INTERIOR_SP 18


static DB:connection;

main() {
    print("************************************");
    print("         SAMP War System            ");
    print("               v2.0                 ");
    print("         Made by Danix43            ");
    print("************************************");
}

// -------------------- CALLBACKS --------------------

public OnGameModeInit() {
    SetGameModeText("War");
    UsePlayerPedAnims();
    DisableInteriorEnterExits();

    LimitGlobalChatRadius(20);
    SetNameTagDrawDistance(20);
    LimitPlayerMarkerRadius(20);

    setupRDT();
    setupSP();

    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);

    SetTimer("globalSave", 2700000, true);

    connectToDb();

    loadTurfs();
}

public OnGameModeExit() {
    globalSave();
    disconnectFromDb();
    return 1;
}

public OnPlayerConnect(playerid) {
    if (checkIfBanned(playerid)) {
        SendClientMessage(playerid, COLOR_RED, "Ai fost banat pe acest server!");
        SetTimerEx("KickWithDelay", 1000, false, "i", playerid);
        return 1;
    }

    players[playerid][faction] = CIVILIAN;
    players[playerid][rank] = 0;
    players[playerid][kills] = 0;
    players[playerid][deaths] = 0;
    players[playerid][kda] = 0;
    players[playerid][warKills] = 0;
    players[playerid][warDeaths] = 0;
    players[playerid][warKda] = 0;
    players[playerid][bests] = 0;
    players[playerid][worsts] = 0;
    SetPVarInt(playerid, "areTurfsShown", 0);

    new query[45 + MAX_PLAYER_NAME];

    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    format(query, sizeof(query), "SELECT name FROM 'Players' where name = '%s'", playerName);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result) == 1) {
        OpenDialog(playerid, "loginPlayer", DIALOG_STYLE_PASSWORD, "Login", "Login using your password", "Login", "Cancel");
    } else if (db_num_rows(result) == 0) {
        OpenDialog(playerid, "registerPlayer", DIALOG_STYLE_PASSWORD, "Register", "Register using your password", "Register", "Cancel");
    }
    return 1;
}

public OnPlayerRequestClass(playerid, classid) {
    new playerFaction, playerFactionRank;
    loadPlayerStats(playerid);
    playerFaction = players[playerid][faction];
    playerFactionRank = players[playerid][rank];

    switch (playerFaction) {
        case RDT:
            putRDT(playerid, playerFactionRank);
        case SP:
            putSP(playerid, playerFactionRank);
        case CIVILIAN:
            putCivil(playerid);
    }
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

public OnPlayerDisconnect(playerid, reason) {
    savePlayerStats(playerid);
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if ((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK)) {
        if (GetPlayerInterior(playerid) == 0) {
            // SP HQ
            if (IsPlayerInRangeOfPoint(playerid, 2, 1454.88538, 751.07147, 11.02340)) {
                SetPlayerInterior(playerid, INTERIOR_SP);
                SetPlayerPos(playerid, 1727.2853, -1642.9451, 20.2254);
            }
            // RDT HQ
            if (IsPlayerInRangeOfPoint(playerid, 2, 2633.78174, 1825.46545, 11.02340)) {
                SetPlayerInterior(playerid, INTERIOR_RDT);
                SetPlayerPos(playerid, -2638.8232, 1407.3395, 906.4609);
            }
        } else if (!GetPlayerInterior(playerid) == 0) {
            // SP HQ
            if (GetPlayerInterior(playerid) == INTERIOR_SP && IsPlayerInRangeOfPoint(playerid, 2, 1727.0000, -1637.8649, 20.2230)) {
                SetPlayerInterior(playerid, 0);
                SetPlayerPos(playerid, 1454.88538, 751.07147, 11.02340);
            }
            // RDT HQ
            if (GetPlayerInterior(playerid) == INTERIOR_RDT && IsPlayerInRangeOfPoint(playerid, 2, -2636.8782, 1402.4091, 906.4609)) {
                SetPlayerInterior(playerid, 0);
                SetPlayerPos(playerid, 2633.78174, 1825.46545, 11.02340);
            }
        }
    }
    return 1;
}

// -------------------- DB --------------------

connectToDb() {
    connection = db_open("data.db");

    if (connection) {
        new query[386] =
            "CREATE TABLE IF NOT EXISTS 'Players' (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, password TEXT NOT NULL, isBanned INTEGER DEFAULT 0, banReason TEXT, faction INTEGER NOT NULL DEFAULT 255, factionRank INTEGER NOT NULL DEFAULT 0, kills INTEGER DEFAULT 0, deaths INTEGER DEFAULT 0, kda INTEGER DEFAULT 0, bests INTEGER DEFAULT 0, worsts INTEGER DEFAULT 0);";
        db_free_result(db_query(connection, query));

        query = "CREATE TABLE IF NOT EXISTS 'Turfs' (id INTEGER PRIMARY KEY, name TEXT NOT NULL, number INTEGER NOT NULL, owner INTEGER NOT NULL, minX REAL, minY REAL, maxX REAL, maxY REAL, poiX REAL, poiY REAL, poiZ REAL);";
        db_free_result(db_query(connection, query));
    } else {
        print("failed to connect to db");
    }
}

disconnectFromDb() {
    if (db_close(connection)) {
        connection = DB:0;
    }
}

checkIfBanned(playerid) {
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new query[50 + MAX_PLAYER_NAME];

    format(query, sizeof(query), "SELECT isBanned FROM Players WHERE name = '%s';", playerName);

    new DBResult:queryResult = db_query(connection, query);
    if (db_num_rows(queryResult)) {
        new banStatus;
        banStatus = db_get_field_assoc_int(queryResult, "isBanned");

        if (banStatus == 1) {
            db_free_result(queryResult);
            return true;
        } else {
            db_free_result(queryResult);
            return false;
        }
    } else {
        db_free_result(queryResult);
        return false;
    }

}

loadPlayerStats(playerid) {
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new query[50 + MAX_PLAYER_NAME];
    format(query, sizeof(query), "SELECT * FROM Players WHERE name = '%s';", playerName);

    new DBResult:queryResult = db_query(connection, query);
    if (db_num_rows(queryResult)) {
        new playerFaction, factionRank;
        new playerKills, playerDeaths, playerKda;
        new playerBests, playerWorsts;

        playerFaction = db_get_field_assoc_int(queryResult, "faction");
        factionRank = db_get_field_assoc_int(queryResult, "factionRank");

        playerKills = db_get_field_assoc_int(queryResult, "kills");
        playerDeaths = db_get_field_assoc_int(queryResult, "deaths");
        playerKda = playerKills - playerDeaths;

        playerBests = db_get_field_assoc_int(queryResult, "bests");
        playerWorsts = db_get_field_assoc_int(queryResult, "worsts");

        players[playerid][faction] = playerFaction;
        players[playerid][rank] = factionRank;
        players[playerid][kills] = playerKills;
        players[playerid][deaths] = playerDeaths;
        players[playerid][kda] = playerKda;
        players[playerid][bests] = playerBests;
        players[playerid][worsts] = playerWorsts;

        printf("loadPlayerStats data: faction: %d, rank: %d", players[playerid][faction], players[playerid][rank]);

        SetPlayerTeam(playerid, playerFaction);

    } else {
        // user might not exist
    }
    db_free_result(queryResult);
}

savePlayerStats(playerid) {
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new query[120 + MAX_PLAYER_NAME];
    format(query, sizeof(query),
        "UPDATE Players SET faction = %d, factionRank = %d, kills = %d, deaths = %d, bests = %d, worsts = %d WHERE name = '%s';",
        players[playerid][faction],
        players[playerid][rank],
        players[playerid][kills],
        players[playerid][deaths],
        players[playerid][bests],
        players[playerid][worsts],
        playerName);

    if (db_free_result(db_query(connection, query))) {
        print("PlayerStats stats save done");
    } else {
        print("PlayerStats stats save failed");
    }
}

forward globalSave();
public globalSave() {
    for (new playerid = 0; playerid <= MAX_PLAYERS; playerid++) {
        if (IsPlayerConnected(playerid) == true) {
            savePlayerStats(playerid);
        }
    }
    SendClientMessageToAll(COLOR_GREEN, "Global save done");
}

loadTurfs() {
    new query[60];

    format(query, sizeof(query), "SELECT id, owner, minX, minY, maxX, maxY, poiX, poiY, poiZ FROM Turfs;");

    new DBResult:queryResult = db_query(connection, query);

    if (queryResult) {
        for (new i = 0; i <= 23; i++) {
            new Float:turfMinX, Float:turfMinY, Float:turfMaxX, Float:turfMaxY;

            turfMinX = Float:db_get_field_assoc_float(queryResult, "minX");
            turfMinY = Float:db_get_field_assoc_float(queryResult, "minY");
            turfMaxX = Float:db_get_field_assoc_float(queryResult, "maxX");
            turfMaxY = Float:db_get_field_assoc_float(queryResult, "maxY");

            turfs[i][poiX] = db_get_field_assoc_float(queryResult, "poiX");
            turfs[i][poiY] = db_get_field_assoc_float(queryResult, "poiY");
            turfs[i][poiZ] = db_get_field_assoc_float(queryResult, "poiZ");

            turfs[i][id] = db_get_field_assoc_int(queryResult, "id");
            turfs[i][owner] = db_get_field_assoc_int(queryResult, "owner");

            turfs[i][id] = CreateZone(turfMinX, turfMinY, turfMaxX, turfMaxY);
            CreateZoneBorders(turfs[i][id]);
            CreateZoneNumber(turfs[i][id], turfs[i][id], 0.7);

            db_next_row(queryResult);
        }
    } else {
        print("No turf data loaded");
    }
    db_free_result(queryResult);
}

loadDataForAttack(playerid) {
    new query[100];
    new returnData[650];

    new headers[33];
    headers = "Turf Number\tTurf Name\tOwner\n";
    strcatmid(returnData, headers);

    for (new turfId = 1; turfId <= 24; turfId++) {
        format(query, sizeof(query), "SELECT number, name, owner FROM Turfs WHERE id = %d;", turfId);

        new DBResult:queryResult = db_query(connection, query);
        new dbTurfNumber;
        new turfName[15];
        new dbTurfOwner;

        dbTurfNumber = db_get_field_assoc_int(queryResult, "number");
        db_get_field_assoc(queryResult, "name", turfName, sizeof(turfName));
        dbTurfOwner = db_get_field_assoc_int(queryResult, "owner");

        if (dbTurfOwner == GetPlayerTeam(playerid)) {
            continue;
        }

        new turfOwner[12];
        if (dbTurfOwner == RDT) {
            turfOwner = "{DE0000}RDT";
        } else if (dbTurfOwner == SP) {
            turfOwner = "{DE09DA}SP";
        } else {
            printf("owner data not matching: %s", dbTurfOwner);
        }
        new temp[60];
        format(temp, sizeof(temp), "%d\t%s\t%s\n", dbTurfNumber, turfName, turfOwner);

        strcatmid(returnData, temp);

        db_free_result(queryResult);
    }
    return returnData;
}

dialog attack(playerid, response, listitem, inputtext[]) {
    if (response == 0) {
        return;
    }

    new warStatus;
    warStatus = GetSVarInt("isWarOn");

    if (warStatus == 1) {
        SendClientMessage(playerid, COLOR_RED, "Un war este deja in desfasurare");
        return;
    }

    // startWar(inputtext, playerid);
}

dialog loginPlayer(playerid, response, listitem, inputtext[]) {
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    new query[100];

    format(query, sizeof(query), "SELECT password FROM 'Players' where name = '%s';", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new playerPassword[250];

        db_get_field_assoc(result, "password", playerPassword, 250);

        bcrypt_verify(playerid, "OnPasswordVerify", inputtext, playerPassword);
    }
}

dialog registerPlayer(playerid, response, listitem, inputtext[]) {
    bcrypt_hash(playerid, "OnPasswordHash", inputtext, BCRYPT_COST);
}

forward OnPasswordHash(playerid);
public OnPasswordHash(playerid) {
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    new hashedPass[250];
    bcrypt_get_hash(hashedPass);

    new query[200];

    format(query, sizeof(query),
        "INSERT INTO 'Players' (name, password, faction, factionRank) VALUES ('%s', '%s', 255, '0');", name, hashedPass);

    if (db_free_result(db_query(connection, query)) >= 1) {
        print("Insert query done");
        savePlayerStats(playerid);
    } else {
        print("Insert query failed");
    }
}

forward OnPasswordVerify(playerid, bool:success);
public OnPasswordVerify(playerid, bool:success) {
    if (success) {
        SendClientMessage(playerid, COLOR_GREY, "Te-ai logat cu success!");
    } else {
        SendClientMessage(playerid, COLOR_RED, "Parola incorecta!");
        SetTimerEx("KickWithDelay", 1000, false, "i", playerid);
    }
}

// -------------------- HELPING --------------------

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

    // // vehicles virtual world 2
    rdtVehiclesVw2[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, RDT_CAR_COLOR, RDT_CAR_COLOR); // limordt
    rdtVehiclesVw2[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw2[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, RDT_CAR_COLOR, RDT_CAR_COLOR); // infrdt
    rdtVehiclesVw2[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, RDT_CAR_COLOR, RDT_CAR_COLOR); // nrgrdt
    rdtVehiclesVw2[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, RDT_CAR_COLOR, RDT_CAR_COLOR); // huntleyrdt

    SetVehicleVirtualWorld(rdtVehiclesVw2[0], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[1], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[2], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[3], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[4], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[5], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[6], 2);
    SetVehicleVirtualWorld(rdtVehiclesVw2[7], 2);
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

    SetVehicleVirtualWorld(spVehiclesVw2[0], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[1], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[2], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[3], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[4], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[5], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[6], 2);
    SetVehicleVirtualWorld(spVehiclesVw2[7], 2);
}

putRDT(playerid, playerRank) {
    switch (playerRank) {
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

putSP(playerid, playerRank) {
    switch (playerRank) {
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
    SetPlayerColor(playerid, COLOR_GREY);
    SpawnPlayer(playerid);
}

checkIfCivil(playerid) {
    if (GetPlayerTeam(playerid) == CIVILIAN) {
        return true;
    }
    return false;
}

getPlayerFactionName(playerid) {
    new factionName[9];
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
    factionName = "CIVILIAN";
    return factionName;
}

getPlayerFactionRank(playerid) {
    return players[playerid][rank];
}

getTurfOwnerName(turfOwner) {
    new name[4];
    name = "nul";
    if (turfOwner == RDT) {
        name = "RDT";
    } else if (turfOwner == SP) {
        name = "SP";
    }
    return name;
}

// turfOwner - should give the int of the faction
getTurfOpposedFaction(turfOwner) {
    if (turfOwner == RDT) {
        return SP;
    } else if (turfOwner == SP) {
        return RDT;
    }
    return turfOwner;
}

getTurfOpposedFactionName(turfOwner) {
    new name[4];
    name = "nul";
    if (turfOwner == RDT) {
        name = "SP";
    } else if (turfOwner == SP) {
        name = "RDT";
    }
    return name;
}

forward KickWithDelay(playerid);
public KickWithDelay(playerid) {
    Kick(playerid);
    return 1;
}

// -------------------- FACTION COMMANDS --------------------
COMMAND:attack(playerid, params[]) {
    if (getPlayerFactionRank(playerid) >= 5) {
        new turfData[650];
        turfData = loadDataForAttack(playerid);

        OpenDialog(playerid, "attack", DIALOG_STYLE_TABLIST_HEADERS,
            "Attack Menu",
            turfData,
            "Attack", "");
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul necesar pentru a lansa un atac!");
    }
    return 1;
}

COMMAND:turfs(playerid, params[]) {
    new turfsShownStatus = GetPVarInt(playerid, "areTurfsShown");
    if (turfsShownStatus == 0) {
        for (new turfid = 0; turfid <= 23; turfid++) {
            new turfOwner;
            turfOwner = turfs[turfid][owner];
            switch (turfOwner) {
                case 5:
                    ShowZoneForPlayer(playerid, turfs[turfid][id], 0xFF000099, 0xFFFFFFFF, 0xFFFFFFFF);
                case 6:
                    ShowZoneForPlayer(playerid, turfs[turfid][id], 0x8A2BE299, 0xFFFFFFFF, 0xFFFFFFFF);
            }
        }
        SetPVarInt(playerid, "areTurfsShown", 1);
    } else {
        for (new turfid = 0; turfid <= 23; turfid++) {
            HideZoneForPlayer(playerid, turfs[turfid][id]);
        }
        SetPVarInt(playerid, "areTurfsShown", 0);
    }
    return 1;
}

new inviteTimer[MAX_PLAYERS];
// done testing, may need to update killtimer
COMMAND:invitemember(playerid, params[]) {
    new takerId;
    if (sscanf(params, "i", takerId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /invitemember <id player>");
    } else {
        if (!IsPlayerConnected(takerId)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti invita un jucator care nu este conectat!");
            return 1;
        }

        // check if the inviter is a civil
        if (checkIfCivil(playerid)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti invita un membru ca civil!");
            return 1;
        }

        if (GetPlayerTeam(takerId) == GetPlayerTeam(playerid)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti invita un membru din factiunea ta!");
            return 1;
        }

        // check if the taker is a civilian 
        if (checkIfCivil(takerId)) {
            // the giver should have at least rank 6
            new giverRank = getPlayerFactionRank(playerid);
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
            SendClientMessage(takerId, COLOR_BLUE, "Foloseste /acceptinvite <id inviter>");
            return 1;
        }
    }
    return 1;
}

COMMAND:acceptinvite(playerid, params[]) {
    new giverId;
    if (sscanf(params, "i", giverId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /acceptinvite <id inviter>");
    } else {
        new takerName[30];
        GetPlayerName(playerid, takerName, sizeof(takerName));

        // can't join the civilian
        if (checkIfCivil(giverId) || !IsPlayerConnected(giverId)) {
            return 1;
        }

        // check if the invited player is a civil; check already done in invitemember
        if (checkIfCivil(playerid)) {
            // get the inviter player faction
            new giverFaction, giverFactionName[9];
            giverFaction = GetPlayerTeam(giverId);
            giverFactionName = getPlayerFactionName(giverId);

            new message[25 + MAX_PLAYER_NAME];
            format(message, sizeof(message), "Te-ai alaturat mafiei %s!", giverFactionName);
            SendClientMessage(playerid, COLOR_GREEN, message);
            players[playerid][faction] = giverFaction;
            players[playerid][rank] = 1;
            KillTimer(inviteTimer[giverId]);
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

        // - check if the giver is a civil
        if (checkIfCivil(playerid)) {
            // SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai afara un alt civil!");
            return 1;
        }

        // - faction checking

        if (GetPlayerTeam(playerid) != GetPlayerTeam(takerPlayerId)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da afara un jucator din alta mafie!");
            return 1;
        }

        // - rank checking: an inferior can not resign a superior
        // - rank checking: the giver needs to have at least rank 6
        new giverRank = getPlayerFactionRank(playerid);
        new takerRank = getPlayerFactionRank(takerPlayerId);
        if (giverRank <= takerRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da afara un rank superior!");
            return 1;
        }
        if (5 > giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da afara un membru!");
            return 1;
        }

        // - every step checks up: do update
        new message[35 + MAX_PLAYER_NAME];
        format(message, sizeof(message), "L-ai dat afara pe %s din mafie!", takerPlayerName);
        SendClientMessage(playerid, COLOR_BLUE, message);
        players[takerPlayerId][faction] = CIVILIAN;
        players[takerPlayerId][rank] = 0;
        putCivil(takerPlayerId);
        SpawnPlayer(takerPlayerId);
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

        // check if the target is a civil
        if (checkIfCivil(takerId)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-up unui civil!");
            return 1;
        }

        // - check if the giver is a civil
        if (checkIfCivil(playerid)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai rank-up unui alt civil!");
            return 1;
        }

        // check if the target is the same faction as the giver
        new giverFaction[9];
        giverFaction = getPlayerFactionName(playerid);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerId);

        if (!isequal(takerFaction, giverFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-up unui jucator din alta mafie!");
            return 1;
        }

        // rank checking
        new giverRank = getPlayerFactionRank(playerid);
        new takerRank = getPlayerFactionRank(takerId);
        if (giverRank <= takerRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da sa dai rank-up unui rank superior!");
            return 1;
        }
        if (5 > giverRank) {
            SendClientMessage(playerid, COLOR_RED, "Nu ai rank-ul suficient pentru a da rank-up unui membru!");
            return 1;
        }

        // checking the current rank
        if (takerRank == 6) {
            SendClientMessage(playerid, COLOR_RED, "Membrul are deja rank 6, considera in a-l promova la lider.");
            return 1;
        }
        new newPlayerRank = takerRank + 1;

        players[takerId][rank] = newPlayerRank;
        switch (GetPlayerTeam(takerId)) {
            case RDT:
                putRDT(takerId, players[takerId][rank]);
            case SP:
                putSP(takerId, players[takerId][rank]);
        }
        SpawnPlayer(takerId);

        new messageTaker[100];
        format(messageTaker, sizeof(messageTaker), "Ai primit rank-up. Nou tau rank este: %d", newPlayerRank);
        SendClientMessage(takerId, COLOR_BLUE, messageTaker);

        new messageGiver[100];
        format(messageGiver, sizeof(messageGiver), "I-ai dat rank-ul: %d lui %s.", newPlayerRank, takerPlayerName);
        SendClientMessage(playerid, COLOR_BLUE, messageGiver);
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

        // check if the target is a civil
        if (checkIfCivil(takerId)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-down unui civil!");
            return 1;
        }

        // - check if the giver is a civil
        if (checkIfCivil(playerid)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti sa dai rank-down unui alt civil!");
            return 1;
        }

        // check if the target is the same faction as the giver
        new giverFaction[9];
        giverFaction = getPlayerFactionName(playerid);
        new takerFaction[9];
        takerFaction = getPlayerFactionName(takerId);

        if (!isequal(takerFaction, giverFaction)) {
            SendClientMessage(playerid, COLOR_RED, "Nu poti da rank-down unui jucator din alta mafie!");
            return 1;
        }

        // rank checking
        new giverRank = getPlayerFactionRank(playerid);
        new takerRank = getPlayerFactionRank(takerId);
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

        players[takerId][rank] = newPlayerRank;
        switch (GetPlayerTeam(takerId)) {
            case RDT:
                putRDT(takerId, players[takerId][rank]);
            case SP:
                putSP(takerId, players[takerId][rank]);
        }
        SpawnPlayer(takerId);

        new messageTaker[100];
        format(messageTaker, sizeof(messageTaker), "Ai primit rank-down. Nou tau rank este: %d", newPlayerRank);
        SendClientMessage(takerId, COLOR_BLUE, messageTaker);

        new messageGiver[100];
        format(messageGiver, sizeof(messageGiver), "I-ai dat rank-ul: %d lui %s.", newPlayerRank, takerPlayerName);
        SendClientMessage(playerid, COLOR_BLUE, messageGiver);
    }
    return 1;
}

// -------------------- WAR --------------------

preparePlayersForWar() {
    SendClientMessageToAll(COLOR_PURPLE, "War-urile intre mafii vor incepe incurand!");
    SendClientMessageToAll(COLOR_PURPLE, "Toti mafiotii vor fi respawnati la HQ-uri in cateva secunde");
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (!checkIfCivil(i)) {
            SpawnPlayer(i);
            SetPlayerVirtualWorld(i, 2);
            displayWarTextDraw(i);
            SendClientMessage(i, COLOR_BLUE, "Ai fost respawnat la HQ deoarece va incepe war-ul");
        }
    }
    return 1;
}

prepareTurf(turfIdForWar) {
    SetSVarFloat("poiX", turfs[turfIdForWar][poiX]);
    SetSVarFloat("poiY", turfs[turfIdForWar][poiY]);
    SetSVarFloat("poiZ", turfs[turfIdForWar][poiZ]);

    ZoneFlashForAll(turfs[turfIdForWar][id], 0xFFFFFF99);
}

displayWarTextDraw(playerid) {
    new statsBoxText[2];
    format(statsBoxText, sizeof(statsBoxText), "_");

    new turfNameText[20];
    new turfNr;
    turfNr = GetSVarInt("warTurf");
    format(turfNameText, sizeof(turfNameText), "Turf Number: %d", turfNr);

    new warMafiaRounds[50];
    format(warMafiaRounds, sizeof(warMafiaRounds), "Rounds %s %d - %d %s", "SP", 0, 0, "RDT");

    new warTotalRounds[16];
    format(warTotalRounds, sizeof(warTotalRounds), "Runda %d / 15", 0);

    new warRoundScoreText[50];
    format(warRoundScoreText, sizeof(warRoundScoreText), "%s %d - %d %s", "SP", 0, 0, "RDT");

    new warTurfPlayersText[50];
    format(warTurfPlayersText, sizeof(warTurfPlayersText), "On turf: %s %d - %d %s", "SP", 0, 0, "RDT");

    new warPlayerStatsText[25];
    format(warPlayerStatsText, sizeof(warPlayerStatsText), "Ucideri: %d Morti: %d", 0, 0);
    //     statsBox[playerid] = CreatePlayerTextDraw(playerid, 513.000000, 353.000000, statsBoxText);
    //     PlayerTextDrawFont(playerid, statsBox[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, statsBox[playerid], 0.600000, 7.849992);
    //     PlayerTextDrawTextSize(playerid, statsBox[playerid], 458.000000, 225.500000);
    //     PlayerTextDrawSetOutline(playerid, statsBox[playerid], 1);
    //     PlayerTextDrawSetShadow(playerid, statsBox[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, statsBox[playerid], 2);
    //     PlayerTextDrawColor(playerid, statsBox[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, statsBox[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, statsBox[playerid], 135);
    //     PlayerTextDrawUseBox(playerid, statsBox[playerid], 1);
    //     PlayerTextDrawSetProportional(playerid, statsBox[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, statsBox[playerid], 0);

    //     warTurfNumber[playerid] = CreatePlayerTextDraw(playerid, 559.000000, 365.000000, turfNameText);
    //     PlayerTextDrawFont(playerid, warTurfNumber[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warTurfNumber[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warTurfNumber[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warTurfNumber[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warTurfNumber[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warTurfNumber[playerid], 3);
    //     PlayerTextDrawColor(playerid, warTurfNumber[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warTurfNumber[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warTurfNumber[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warTurfNumber[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warTurfNumber[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warTurfNumber[playerid], 0);

    //     warRoundScore[playerid] = CreatePlayerTextDraw(playerid, 565.000000, 354.000000, warMafiaRounds);
    //     PlayerTextDrawFont(playerid, warRoundScore[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warRoundScore[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warRoundScore[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warRoundScore[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warRoundScore[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warRoundScore[playerid], 3);
    //     PlayerTextDrawColor(playerid, warRoundScore[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warRoundScore[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warRoundScore[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warRoundScore[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warRoundScore[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warRoundScore[playerid], 0);

    //     warRounds[playerid] = CreatePlayerTextDraw(playerid, 559.000000, 376.000000, warTotalRounds);
    //     PlayerTextDrawFont(playerid, warRounds[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warRounds[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warRounds[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warRounds[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warRounds[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warRounds[playerid], 3);
    //     PlayerTextDrawColor(playerid, warRounds[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warRounds[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warRounds[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warRounds[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warRounds[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warRounds[playerid], 0);

    //     warCurrentPoints[playerid] = CreatePlayerTextDraw(playerid, 563.000000, 387.000000, warRoundScoreText);
    //     PlayerTextDrawFont(playerid, warCurrentPoints[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warCurrentPoints[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warCurrentPoints[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warCurrentPoints[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warCurrentPoints[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warCurrentPoints[playerid], 3);
    //     PlayerTextDrawColor(playerid, warCurrentPoints[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warCurrentPoints[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warCurrentPoints[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warCurrentPoints[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warCurrentPoints[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warCurrentPoints[playerid], 0);

    //     warPlayersOnTurf[playerid] = CreatePlayerTextDraw(playerid, 595.000000, 398.000000, warTurfPlayersText);
    //     PlayerTextDrawFont(playerid, warPlayersOnTurf[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warPlayersOnTurf[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warPlayersOnTurf[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warPlayersOnTurf[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warPlayersOnTurf[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warPlayersOnTurf[playerid], 3);
    //     PlayerTextDrawColor(playerid, warPlayersOnTurf[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warPlayersOnTurf[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warPlayersOnTurf[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warPlayersOnTurf[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warPlayersOnTurf[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warPlayersOnTurf[playerid], 0);

    //     warPlayerStats[playerid] = CreatePlayerTextDraw(playerid, 591.000000, 408.000000, warPlayerStatsText);
    //     PlayerTextDrawFont(playerid, warPlayerStats[playerid], 1);
    //     PlayerTextDrawLetterSize(playerid, warPlayerStats[playerid], 0.416666, 1.350000);
    //     PlayerTextDrawTextSize(playerid, warPlayerStats[playerid], 606.500000, 24.500000);
    //     PlayerTextDrawSetOutline(playerid, warPlayerStats[playerid], 0);
    //     PlayerTextDrawSetShadow(playerid, warPlayerStats[playerid], 0);
    //     PlayerTextDrawAlignment(playerid, warPlayerStats[playerid], 3);
    //     PlayerTextDrawColor(playerid, warPlayerStats[playerid], -1);
    //     PlayerTextDrawBackgroundColor(playerid, warPlayerStats[playerid], 255);
    //     PlayerTextDrawBoxColor(playerid, warPlayerStats[playerid], 50);
    //     PlayerTextDrawUseBox(playerid, warPlayerStats[playerid], 0);
    //     PlayerTextDrawSetProportional(playerid, warPlayerStats[playerid], 1);
    //     PlayerTextDrawSetSelectable(playerid, warPlayerStats[playerid], 0);

    //     PlayerTextDrawShow(playerid, PlayerText:statsBox[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warRoundScore[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warTurfNumber[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warRounds[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warCurrentPoints[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warPlayersOnTurf[playerid]);
    //     PlayerTextDrawShow(playerid, PlayerText:warPlayerStats[playerid]);
}

// getPlayersOnTurf(const playerMafia[], Float:poiX, Float:poiY, Float:poiZ) {
//     new playersOnTurf;
//     playersOnTurf = 0;
//     new j = GetPlayerPoolSize();
//     for (new i = 0; i <= j; i++) {
//         if (GetPlayerVirtualWorld(i) == 2) {
//             if (IsPlayerInRangeOfPoint(i, 250, poiX, poiY, poiZ)) {
//                 if (isequal(getPlayerFactionName(i), playerMafia)) {
//                     playersOnTurf = playersOnTurf + 1;
//                 }
//             }
//         }
//     }
//     return playersOnTurf;
// }

// pointFromKill(playerid, killerid) {
//     if (GetPlayerVirtualWorld(playerid) == 2 && GetPlayerVirtualWorld(killerid) == 2) {
//         // both are in war vw
//         new killerFaction[9];
//         killerFaction = getPlayerFactionName(killerid);

//         new rdtName[9], spName[9];
//         rdtName = "RDT";
//         spName = "SP";
//         if (isequal(killerFaction, rdtName)) {
//             new pointRDT = GetSVarInt("pointsRDT");
//             SetSVarInt("pointsRDT", (pointRDT + 1));
//         } else if (isequal(killerFaction, spName)) {
//             new pointSP = GetSVarInt("pointsSP");
//             SetSVarInt("pointsSP", (pointSP + 1));
//         }
//     }
// }

// // showBestPlayer(playerid) {
// //     bestBox[playerid] = CreatePlayerTextDraw(playerid, 195.000000, 89.000000, "_");
// //     PlayerTextDrawFont(playerid, bestBox[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, bestBox[playerid], 0.675000, 29.200008);
// //     PlayerTextDrawTextSize(playerid, bestBox[playerid], 303.500000, 190.000000);
// //     PlayerTextDrawSetOutline(playerid, bestBox[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, bestBox[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, bestBox[playerid], 2);
// //     PlayerTextDrawColor(playerid, bestBox[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, bestBox[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, bestBox[playerid], -121);
// //     PlayerTextDrawUseBox(playerid, bestBox[playerid], 1);
// //     PlayerTextDrawSetProportional(playerid, bestBox[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, bestBox[playerid], 0);

// //     bestPlayerSkinBox[playerid] = CreatePlayerTextDraw(playerid, 114.000000, 101.000000, "Preview_Model");
// //     PlayerTextDrawFont(playerid, bestPlayerSkinBox[playerid], 5);
// //     PlayerTextDrawLetterSize(playerid, bestPlayerSkinBox[playerid], 0.600000, 2.000000);
// //     PlayerTextDrawTextSize(playerid, bestPlayerSkinBox[playerid], 162.500000, 223.000000);
// //     PlayerTextDrawSetOutline(playerid, bestPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetShadow(playerid, bestPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, bestPlayerSkinBox[playerid], 1);
// //     PlayerTextDrawColor(playerid, bestPlayerSkinBox[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, bestPlayerSkinBox[playerid], -2686851);
// //     PlayerTextDrawBoxColor(playerid, bestPlayerSkinBox[playerid], 255);
// //     PlayerTextDrawUseBox(playerid, bestPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, bestPlayerSkinBox[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, bestPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetPreviewModel(playerid, bestPlayerSkinBox[playerid], 3);
// //     PlayerTextDrawSetPreviewRot(playerid, bestPlayerSkinBox[playerid], -10.000000, 0.000000, -13.000000, 1.000000);
// //     PlayerTextDrawSetPreviewVehCol(playerid, bestPlayerSkinBox[playerid], 1, 1);

// //     bestPlayerText[playerid] = CreatePlayerTextDraw(playerid, 119.000000, 85.000000, "Cel mai bun jucator");
// //     PlayerTextDrawFont(playerid, bestPlayerText[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, bestPlayerText[playerid], 0.474999, 2.000000);
// //     PlayerTextDrawTextSize(playerid, bestPlayerText[playerid], 374.500000, 7.000000);
// //     PlayerTextDrawSetOutline(playerid, bestPlayerText[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, bestPlayerText[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, bestPlayerText[playerid], 1);
// //     PlayerTextDrawColor(playerid, bestPlayerText[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, bestPlayerText[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, bestPlayerText[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, bestPlayerText[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, bestPlayerText[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, bestPlayerText[playerid], 0);

// //     bestPlayerName[playerid] = CreatePlayerTextDraw(playerid, 194.000000, 319.000000, "Nume player");
// //     PlayerTextDrawFont(playerid, bestPlayerName[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, bestPlayerName[playerid], 0.600000, 2.000000);
// //     PlayerTextDrawTextSize(playerid, bestPlayerName[playerid], 400.000000, 17.000000);
// //     PlayerTextDrawSetOutline(playerid, bestPlayerName[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, bestPlayerName[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, bestPlayerName[playerid], 2);
// //     PlayerTextDrawColor(playerid, bestPlayerName[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, bestPlayerName[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, bestPlayerName[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, bestPlayerName[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, bestPlayerName[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, bestPlayerName[playerid], 0);

// //     bestPlayerStats[playerid] = CreatePlayerTextDraw(playerid, 119.000000, 337.000000, "Sample KDA");
// //     PlayerTextDrawFont(playerid, bestPlayerStats[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, bestPlayerStats[playerid], 0.433333, 1.500000);
// //     PlayerTextDrawTextSize(playerid, bestPlayerStats[playerid], 400.000000, 17.000000);
// //     PlayerTextDrawSetOutline(playerid, bestPlayerStats[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, bestPlayerStats[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, bestPlayerStats[playerid], 1);
// //     PlayerTextDrawColor(playerid, bestPlayerStats[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, bestPlayerStats[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, bestPlayerStats[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, bestPlayerStats[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, bestPlayerStats[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, bestPlayerStats[playerid], 0);

// //     enum stats {
// //         id,
// //         kda
// //     }

// //     new playersStats[MAX_PLAYERS][stats];

// //     new j = GetPlayerPoolSize();
// //     for (new loopPlayerId = 0; loopPlayerId <= j; loopPlayerId++) {
// //         if (GetPlayerVirtualWorld(loopPlayerId) == 2) {
// //             new playerKills = playerWarKills[loopPlayerId];
// //             new playerDeaths = playerWarDeaths[loopPlayerId];

// //             new playerKDA = playerKills - playerDeaths;
// //             playersStats[loopPlayerId][kda] = playerKDA;
// //             playersStats[loopPlayerId][id] = loopPlayerId;
// //         }
// //     }

// //     new bestMemberKda = playersStats[0][kda];
// //     new bestMemberId = playersStats[0][id];

// //     for (new x = 1; x < MAX_PLAYERS; x++) {
// //         if (playersStats[x][kda] > bestMemberKda) {
// //             bestMemberKda = playersStats[x][kda];
// //             bestMemberId = playersStats[x][id];
// //         }
// //     }

// //     new playerName[30];
// //     GetPlayerName(bestMemberId, playerName, sizeof(playerName));
// //     PlayerTextDrawSetString(playerid, bestPlayerName[playerid], playerName);

// //     new playerSkin;
// //     playerSkin = GetPlayerSkin(bestMemberId);
// //     PlayerTextDrawSetPreviewModel(playerid, bestPlayerSkinBox[playerid], playerSkin);

// //     new playerKDAText[25];
// //     format(playerKDAText, sizeof(playerKDAText), "Cel mai bun scor: %d", bestMemberKda);
// //     PlayerTextDrawSetString(playerid, bestPlayerStats[playerid], playerKDAText);

// //     PlayerTextDrawShow(playerid, bestBox[playerid]);
// //     PlayerTextDrawShow(playerid, bestPlayerSkinBox[playerid]);
// //     PlayerTextDrawShow(playerid, bestPlayerText[playerid]);
// //     PlayerTextDrawShow(playerid, bestPlayerName[playerid]);
// //     PlayerTextDrawShow(playerid, bestPlayerStats[playerid]);
// // }

// // showWorstPlayer(playerid) {
// //     worstBox[playerid] = CreatePlayerTextDraw(playerid, 435.000000, 89.000000, "_");
// //     PlayerTextDrawFont(playerid, worstBox[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, worstBox[playerid], 0.675000, 29.200008);
// //     PlayerTextDrawTextSize(playerid, worstBox[playerid], 303.500000, 190.000000);
// //     PlayerTextDrawSetOutline(playerid, worstBox[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, worstBox[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, worstBox[playerid], 2);
// //     PlayerTextDrawColor(playerid, worstBox[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, worstBox[playerid], 1097458175);
// //     PlayerTextDrawBoxColor(playerid, worstBox[playerid], 135);
// //     PlayerTextDrawUseBox(playerid, worstBox[playerid], 1);
// //     PlayerTextDrawSetProportional(playerid, worstBox[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, worstBox[playerid], 0);

// //     worstPlayerSkinBox[playerid] = CreatePlayerTextDraw(playerid, 354.000000, 101.000000, "Preview_Model");
// //     PlayerTextDrawFont(playerid, worstPlayerSkinBox[playerid], 5);
// //     PlayerTextDrawLetterSize(playerid, worstPlayerSkinBox[playerid], 0.600000, 2.000000);
// //     PlayerTextDrawTextSize(playerid, worstPlayerSkinBox[playerid], 162.500000, 223.000000);
// //     PlayerTextDrawSetOutline(playerid, worstPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetShadow(playerid, worstPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, worstPlayerSkinBox[playerid], 1);
// //     PlayerTextDrawColor(playerid, worstPlayerSkinBox[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, worstPlayerSkinBox[playerid], -16777091);
// //     PlayerTextDrawBoxColor(playerid, worstPlayerSkinBox[playerid], 255);
// //     PlayerTextDrawUseBox(playerid, worstPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, worstPlayerSkinBox[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, worstPlayerSkinBox[playerid], 0);
// //     PlayerTextDrawSetPreviewModel(playerid, worstPlayerSkinBox[playerid], 3);
// //     PlayerTextDrawSetPreviewRot(playerid, worstPlayerSkinBox[playerid], -10.000000, 0.000000, -13.000000, 1.000000);
// //     PlayerTextDrawSetPreviewVehCol(playerid, worstPlayerSkinBox[playerid], 0, 1);

// //     worstPlayerText[playerid] = CreatePlayerTextDraw(playerid, 522.000000, 85.000000, "Cel mai prost jucator");
// //     PlayerTextDrawFont(playerid, worstPlayerText[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, worstPlayerText[playerid], 0.474999, 2.000000);
// //     PlayerTextDrawTextSize(playerid, worstPlayerText[playerid], 374.500000, 7.000000);
// //     PlayerTextDrawSetOutline(playerid, worstPlayerText[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, worstPlayerText[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, worstPlayerText[playerid], 3);
// //     PlayerTextDrawColor(playerid, worstPlayerText[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, worstPlayerText[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, worstPlayerText[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, worstPlayerText[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, worstPlayerText[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, worstPlayerText[playerid], 0);

// //     worstPlayerName[playerid] = CreatePlayerTextDraw(playerid, 436.000000, 319.000000, "Danix43");
// //     PlayerTextDrawFont(playerid, worstPlayerName[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, worstPlayerName[playerid], 0.600000, 2.000000);
// //     PlayerTextDrawTextSize(playerid, worstPlayerName[playerid], 400.000000, 17.000000);
// //     PlayerTextDrawSetOutline(playerid, worstPlayerName[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, worstPlayerName[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, worstPlayerName[playerid], 2);
// //     PlayerTextDrawColor(playerid, worstPlayerName[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, worstPlayerName[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, worstPlayerName[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, worstPlayerName[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, worstPlayerName[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, worstPlayerName[playerid], 0);

// //     worstPlayerStats[playerid] = CreatePlayerTextDraw(playerid, 517.000000, 337.000000, "Ucideri: 23 - Morti: 1");
// //     PlayerTextDrawFont(playerid, worstPlayerStats[playerid], 1);
// //     PlayerTextDrawLetterSize(playerid, worstPlayerStats[playerid], 0.433333, 1.500000);
// //     PlayerTextDrawTextSize(playerid, worstPlayerStats[playerid], 400.000000, 17.000000);
// //     PlayerTextDrawSetOutline(playerid, worstPlayerStats[playerid], 1);
// //     PlayerTextDrawSetShadow(playerid, worstPlayerStats[playerid], 0);
// //     PlayerTextDrawAlignment(playerid, worstPlayerStats[playerid], 3);
// //     PlayerTextDrawColor(playerid, worstPlayerStats[playerid], -1);
// //     PlayerTextDrawBackgroundColor(playerid, worstPlayerStats[playerid], 255);
// //     PlayerTextDrawBoxColor(playerid, worstPlayerStats[playerid], 50);
// //     PlayerTextDrawUseBox(playerid, worstPlayerStats[playerid], 0);
// //     PlayerTextDrawSetProportional(playerid, worstPlayerStats[playerid], 1);
// //     PlayerTextDrawSetSelectable(playerid, worstPlayerStats[playerid], 0);

// //     enum stats {
// //         id,
// //         kda
// //     }

// //     new playersStats[MAX_PLAYERS][stats];

// //     new j = GetPlayerPoolSize();
// //     for (new loopPlayerId = 0; loopPlayerId <= j; loopPlayerId++) {
// //         if (GetPlayerVirtualWorld(loopPlayerId) == 2) {
// //             new playerKills = playerWarKills[loopPlayerId];
// //             new playerDeaths = playerWarDeaths[loopPlayerId];

// //             new playerKDA = playerKills - playerDeaths;
// //             playersStats[loopPlayerId][kda] = playerKDA;
// //             playersStats[loopPlayerId][id] = loopPlayerId;
// //         }
// //     }

// //     new worstMemberKda = playersStats[0][kda];
// //     new worstMemberId = playersStats[0][id];

// //     for (new x = 1; x < MAX_PLAYERS; x++) {
// //         if (playersStats[x][kda] < worstMemberKda) {
// //             worstMemberKda = playersStats[x][kda];
// //             worstMemberId = playersStats[x][id];
// //         }
// //     }

// //     new playerName[30];
// //     GetPlayerName(worstMemberId, playerName, sizeof(playerName));
// //     PlayerTextDrawSetString(playerid, worstPlayerName[playerid], playerName);

// //     new playerSkin;
// //     playerSkin = GetPlayerSkin(worstMemberId);
// //     PlayerTextDrawSetPreviewModel(playerid, worstPlayerSkinBox[playerid], playerSkin);

// //     new playerKDAText[25];
// //     format(playerKDAText, sizeof(playerKDAText), "Cel mai prost scor: %d", worstMemberKda);
// //     PlayerTextDrawSetString(playerid, worstPlayerStats[playerid], playerKDAText);

// //     PlayerTextDrawShow(playerid, worstBox[playerid]);
// //     PlayerTextDrawShow(playerid, worstPlayerSkinBox[playerid]);
// //     PlayerTextDrawShow(playerid, worstPlayerText[playerid]);
// //     PlayerTextDrawShow(playerid, worstPlayerName[playerid]);
// //     PlayerTextDrawShow(playerid, worstPlayerStats[playerid]);
// // }

// new influenceTimer, endWarTimer, roundTimer;
// new updatePlayersOnTurfTdTimer;
// startWar(const turf_id[], attackerid) {
//     new attacker[9];
//     attacker = getPlayerFactionName(attackerid);

//     new defender[9];
//     defender = getPlayerOpposedFaction(attackerid);

//     new attackedTurfId = strval(turf_id);

//     new startMessage[100];
//     format(startMessage, sizeof(startMessage), "%s vor ataca turf-ul cu numarul %d detinut de mafia %s", attacker, attackedTurfId, defender);
//     SendClientMessageToAll(COLOR_PURPLE, startMessage);

//     SetSVarInt("warTurf", attackedTurfId);

//     prepareTurf(attackedTurfId);
//     preparePlayersForWar();

//     SetSVarInt("roundsRDT", 0);
//     SetSVarInt("roundsSP", 0);

//     SetSVarInt("currentRound", 1);

//     SetSVarInt("pointsRDT", 0);
//     SetSVarInt("pointsSP", 0);

//     SetSVarString("isWarOn", "true");
//     SetSVarInt("warWinner", 0);

//     updatePlayersOnTurfTdTimer = SetTimer("updatePlayersOnTurfTdTimer", 7500, true);

//     // prod
//     influenceTimer = SetTimer("pointFromInfluence", 37500, true);
//     roundTimer = SetTimer("advanceRound", 150000, true);

//     endWarTimer = SetTimer("endWar", 2250000, false);

//     // dev
//     // influenceTimer = SetTimer("pointFromInfluence", 10000, true);
//     // roundTimer = SetTimer("advanceRound", 20000, true);

//     // endWarTimer = SetTimer("endWar", 60000, false);
// }

// forward updatePlayersOnTurfTd();
// public updatePlayersOnTurfTd() {
//     new playersRDT, playersSP;
//     new rdtName[9];
//     rdtName = "RDT";
//     new spName[9];
//     spName = "SP";
//     playersRDT = getPlayersOnTurf(rdtName, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));
//     playersSP = getPlayersOnTurf(spName, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));

//     new warTurfPlayersText[50];
//     format(warTurfPlayersText, sizeof(warTurfPlayersText), "On turf: %s %d - %d %s", "SP", playersSP, playersRDT, "RDT");
//     new j = GetPlayerPoolSize();
//     for (new id = 0; id <= j; id++) {
//         if (GetPlayerVirtualWorld(id) == 2) {
//             PlayerTextDrawSetString(id, PlayerText:warPlayersOnTurf[id], warTurfPlayersText);
//         }
//     }
// }

// forward advanceRound();
// public advanceRound() {
//     new rdtRounds = GetSVarInt("roundsRDT");
//     new spRounds = GetSVarInt("roundsSP");
//     if (rdtRounds >= 8) {
//         SetSVarInt("warWinner", RDT);
//         endWar();
//     } else if (spRounds >= 8) {
//         SetSVarInt("warWinner", SP);
//         endWar();
//     }

//     new pointsRDT = GetSVarInt("pointsRDT");
//     new pointsSP = GetSVarInt("pointsSP");

//     if (pointsRDT > pointsSP) {
//         new roundsRDT = GetSVarInt("roundsRDT");
//         SetSVarInt("roundsRDT", (roundsRDT + 1));
//         SetSVarInt("pointsRDT", 0);
//     } else if (pointsRDT < pointsSP) {
//         new roundsSP = GetSVarInt("roundsSP");
//         SetSVarInt("roundsSP", (roundsSP + 1));
//         SetSVarInt("pointsSP", 0);
//     }

//     new warTotalRounds[16];
//     format(warTotalRounds, sizeof(warTotalRounds), "Runda %d / 15", GetSVarInt("currentRound"));

//     new warRoundScoreText[50];
//     format(warRoundScoreText, sizeof(warRoundScoreText), "Rounds %s %d - %d %s", "SP", spRounds, rdtRounds, "RDT");

//     new j = GetPlayerPoolSize();
//     for (new i = 0; i <= j; i++) {
//         if (GetPlayerVirtualWorld(i) == 2) {
//             PlayerTextDrawSetString(i, PlayerText:warRounds[i], warRoundScoreText);
//             PlayerTextDrawSetString(i, PlayerText:warRoundScore[i], warRoundScoreText);
//         }
//     }
// }

// forward pointFromInfluence();
// public pointFromInfluence() {
//     new playersRDT, playersSP;
//     new rdtName[9];
//     rdtName = "RDT";
//     new spName[9];
//     spName = "SP";
//     playersRDT = getPlayersOnTurf(rdtName, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));
//     playersSP = getPlayersOnTurf(spName, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));

//     new pointRDT = GetSVarInt("pointsRDT");
//     new pointSP = GetSVarInt("pointsSP");
//     if (playersRDT > playersSP) {
//         SetSVarInt("pointsRDT", (pointRDT + 1));
//     } else if (playersRDT < playersSP) {
//         SetSVarInt("pointsSP", (pointSP + 1));
//     }

//     new j = GetPlayerPoolSize();
//     for (new i = 0; i <= j; i++) {
//         if (GetPlayerVirtualWorld(i) == 2) {
//             new warTurfPlayersText[50];
//             format(warTurfPlayersText, sizeof(warTurfPlayersText), "On turf: %s %d - %d %s", "SP", playersSP, playersRDT, "RDT");
//             PlayerTextDrawSetString(i, PlayerText:warPlayersOnTurf[i], warTurfPlayersText);
//         }
//     }
// }

// endWar() {
//     // hide text draws
//     new j = GetPlayerPoolSize();
//     for (new i = 0; i <= j; i++) {
//         if (GetPlayerVirtualWorld(i) == 2) {
//             PlayerTextDrawHide(i, PlayerText:statsBox[i]);
//             PlayerTextDrawHide(i, PlayerText:warRoundScore[i]);
//             PlayerTextDrawHide(i, PlayerText:warTurfNumber[i]);
//             PlayerTextDrawHide(i, PlayerText:warRounds[i]);
//             PlayerTextDrawHide(i, PlayerText:warCurrentPoints[i]);
//             PlayerTextDrawHide(i, PlayerText:warPlayersOnTurf[i]);
//             PlayerTextDrawHide(i, PlayerText:warPlayerStats[i]);

//             // showBestPlayer(i);
//             // showWorstPlayer(i);

//             playerWarKills[i] = 0;
//             playerWarDeaths[i] = 0;
//             SetPlayerVirtualWorld(i, 0);
//         }
//     }
//     new warTurfId = GetSVarInt("warTurf");
//     ZoneStopFlashForAll(turfs[warTurfId][turfId]);
//     SetSVarString("isWarOn", "false");

//     new warWinner = GetSVarInt("warWinner");
//     checkTurfWarOwner(warWinner);
//     loadTurfs();

//     KillTimer(influenceTimer);
//     KillTimer(endWarTimer);
//     KillTimer(roundTimer);
//     KillTimer(updatePlayersOnTurfTdTimer);

//     SendClientMessageToAll(COLOR_BLUE, "War-ul s-a incheiat");
// }

// checkTurfWarOwner(winnerMafia) {
//     new warTurf = GetSVarInt("warTurf");

//     new message[100];
//     new oldOwner = turfs[warTurf][owner];
//     new oldOwnerName[4];
//     oldOwnerName = getTurfOwnerName(oldOwner);
//     new opposedMafia = getTurfOpposedFaction(oldOwner);
//     new opposedMafiaName[4];
//     opposedMafiaName = getTurfOpposedFactionName(oldOwner);

//     if (oldOwner == winnerMafia) {
//         format(message, sizeof(message), "Mafia %s a reusit sa apere turf-ul cu numarul %d, fiind atacati de catre %s!", oldOwnerName, warTurf, opposedMafiaName);
//         SendClientMessageToAll(COLOR_GREEN, message);
//     } else {
//         format(message, sizeof(message), "Mafia %s a reusit sa cucereasca turf-ul cu numarul %d de la mafia %s!", opposedMafiaName, warTurf, oldOwnerName);
//         SendClientMessageToAll(COLOR_GREEN, message);

//         new query[100];
//         format(query, sizeof(query), "UPDATE Turfs SET owner = %d WHERE turf_id = %d", opposedMafia, warTurf);

//         new DBResult:queryResult = db_query(connection, query);
//         if (db_num_rows(queryResult) == 1) {
//             print("turf owner update successful");
//         } else {
//             print("turf owner update failed");
//         }
//         db_free_result(queryResult);
//     }
// }

// -------------------- HQ COMMANDS --------------------

COMMAND:heal(playerid) {
    if (GetPlayerInterior(playerid) == INTERIOR_RDT || GetPlayerInterior(playerid) == INTERIOR_SP) {
        SetPlayerHealth(playerid, 101);
        SendClientMessage(playerid, COLOR_GREY, "Ai folosit un medkit din interior!");
    }
    return 1;
}

COMMAND:order1(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 1");
    }
    return 1;
}

COMMAND:order2(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0 && players[playerid][rank] >= 2) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 2");
    }
    return 1;
}

COMMAND:order3(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0 && players[playerid][rank] >= 3) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 3");
    }
    return 1;
}

COMMAND:order4(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0 && players[playerid][rank] >= 4) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        GivePlayerWeapon(playerid, 32, 150);
        GivePlayerWeapon(playerid, 27, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Given order 4");
    }
    return 1;
}