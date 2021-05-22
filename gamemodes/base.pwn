#include <a_samp>

#define FIXES_GetMaxPlayersMsg 0

#include <fixes> 
#include <streamer>
// #include "nex-ac"
#include <izcmd>
#include <sscanf2>
#include <samp_bcrypt>
#include <a_zone>
#include <tdw_dialog>
#include <strlib>

#define BCRYPT_COST 12

#define DIALOG_LOGIN 1337
#define DIALOG_REGISTER 1338

/*
TODO: - fix war textdraws
*/

// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))

enum {
    COLOR_RED = 0xFF0000FF,
        COLOR_GREEN = 0x00FF00FF,
        COLOR_BLUE = 0x00FFFFFF,
        COLOR_PURPLE = 0x8A2BE2FF,
        COLOR_GREY = 0xAAAAAAFF,
        COLOR_WHITE = 0xFFFFFFFF,
        COLOR_YELLOW = 0xFFFF00FF
}

enum {
    RDT = 5,
        SP = 6,
        CIVILIAN = NO_TEAM
}

enum PlayerStats {
    name[MAX_PLAYER_NAME],
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
    Float:poiZ,
    name[30]
}

// warTextDraws
new PlayerText:tdWarBox2[MAX_PLAYERS];
new PlayerText:tdWarLocation[MAX_PLAYERS];
new PlayerText:tdWarBox[MAX_PLAYERS];
new PlayerText:tdWarScore[MAX_PLAYERS];
new PlayerText:tdWarRoundsCount[MAX_PLAYERS];
new PlayerText:tdWarOnTurf[MAX_PLAYERS];
new PlayerText:tdWarStats[MAX_PLAYERS];

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
    return 1;
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
    return 1;
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
    SetPVarInt(playerid, "presentOnWar", 0);

    new query[45 + MAX_PLAYER_NAME];

    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    players[playerid][name] = playerName;

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
    loadPlayerStats(playerid);

    switch (players[playerid][faction]) {
        case RDT:
            putRDT(playerid, players[playerid][rank]);
        case SP:
            putSP(playerid, players[playerid][rank]);
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
        }
        if (GetPlayerInterior(playerid) != 0) {
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

public OnPlayerDeath(playerid, killerid, reason) {
    new tdWarStatsText[30];
    if (GetPlayerVirtualWorld(playerid) == 2 && GetPlayerVirtualWorld(killerid)) {
        if (killerid != INVALID_PLAYER_ID) {
            players[killerid][warKills]++;

            players[playerid][warDeaths]++;

            SendDeathMessage(killerid, playerid, reason);
            pointFromKill(killerid);

            format(tdWarStatsText, sizeof(tdWarStatsText), "Ucideri: %d Morti: %d", players[killerid][warKills], players[killerid][warDeaths]);
            PlayerTextDrawSetString(killerid, PlayerText:tdWarStats[killerid], tdWarStatsText);
            format(tdWarStatsText, sizeof(tdWarStatsText), "Ucideri: %d Morti: %d", players[playerid][warKills], players[playerid][warDeaths]);
            PlayerTextDrawSetString(playerid, PlayerText:tdWarStats[playerid], tdWarStatsText);

            createHealthDrop(playerid);
            createWeaponDrop(playerid);
        }
    }
    players[playerid][deaths]++;
    if (killerid != INVALID_PLAYER_ID) {
        players[killerid][kills]++;
    }
    return 1;
}

new healthDrops;
new ammoDrops;
public OnPlayerPickUpDynamicPickup(playerid, pickupid) {
    if (pickupid == healthDrops) {
        new Float:playerHp;
        GetPlayerHealth(playerid, playerHp);

        if (playerHp >= 25) {
            SetPlayerHealth(playerid, 100);
        } else {
            SetPlayerHealth(playerid, (playerHp + 25));
        }
        SendClientMessage(playerid, COLOR_GREEN, "Ai gasit o pastila pe jos si ai primit 25 HP!");
    } else if (pickupid == ammoDrops) {
        for (new i = 0; i <= 12; i++) {
            new weaponId, weaponAmmo;
            GetPlayerWeaponData(playerid, i, weaponId, weaponAmmo);

            if (weaponAmmo == 0) {
                continue;
            }
            SetPlayerAmmo(playerid, weaponId, (weaponAmmo + 100));
        }
        SendClientMessage(playerid, COLOR_GREEN, "Ai gasit niste arme pe jos si ai luat 100 de gloante!");
    }
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

    players[playerid][name] = playerName;

    new DBResult:queryResult = db_query(connection, query);
    if (db_num_rows(queryResult)) {
        players[playerid][faction] = db_get_field_assoc_int(queryResult, "faction");
        players[playerid][rank] = db_get_field_assoc_int(queryResult, "factionRank");

        players[playerid][kills] = db_get_field_assoc_int(queryResult, "kills");
        players[playerid][deaths] = db_get_field_assoc_int(queryResult, "deaths");
        players[playerid][kda] = players[playerid][kills] - players[playerid][deaths];

        players[playerid][bests] = db_get_field_assoc_int(queryResult, "bests");
        players[playerid][worsts] = db_get_field_assoc_int(queryResult, "worsts");

        printf("loadPlayerStats data: faction: %d, rank: %d", players[playerid][faction], players[playerid][rank]);

        SetPlayerTeam(playerid, players[playerid][faction]);

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
        if (IsPlayerConnected(playerid)) {
            savePlayerStats(playerid);
        }
    }
    new query[50];
    for (new turf = 0; turf <= 23; turf++) {
        format(query, sizeof(query), "UPDATE Turfs SET owner = %d where id = %d;", turfs[turf][owner], (turfs[turf][id] + 1));
        db_free_result(db_query(connection, query));
    }
    SendClientMessageToAll(COLOR_GREEN, "Global save done");
}

loadTurfs() {
    new query[21];

    format(query, sizeof(query), "SELECT * FROM Turfs;");

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

            new turfName[30];
            db_get_field_assoc(queryResult, "name", turfName, sizeof(turfName));

            turfs[i][name] = turfName;

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
    new returnData[650];

    new headers[33];
    headers = "Turf Number\tTurf Name\tOwner\n";
    strcatmid(returnData, headers);

    for (new turfId = 0; turfId <= 23; turfId++) {
        new turfOwner;

        turfOwner = turfs[turfId][owner];

        if (turfOwner == GetPlayerTeam(playerid)) {
            continue;
        }

        new displayTurfOwner[12];
        if (turfOwner == RDT) {
            displayTurfOwner = "{DE0000}RDT";
        } else if (turfOwner == SP) {
            displayTurfOwner = "{DE09DA}SP";
        } else {
            printf("owner data not matching: %s", displayTurfOwner);
        }
        new temp[60];
        format(temp, sizeof(temp), "%d\t%s\t%s\n", turfs[turfId][id], displayTurfOwner, turfs[turfId][name]);

        strcatmid(returnData, temp);
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

    startWar(inputtext, playerid);
}

dialog loginPlayer(playerid, response, listitem, inputtext[]) {
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new query[100];

    format(query, sizeof(query), "SELECT password FROM 'Players' where name = '%s';", playerName);

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
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new hashedPass[250];
    bcrypt_get_hash(hashedPass);

    new query[200];

    format(query, sizeof(query),
        "INSERT INTO 'Players' (name, password, faction, factionRank) VALUES ('%s', '%s', 255, '0');", playerName, hashedPass);

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
    new gangName[4];
    gangName = "nul";
    if (turfOwner == RDT) {
        gangName = "RDT";
    } else if (turfOwner == SP) {
        gangName = "SP";
    }
    return gangName;
}

getTurfOpposedFaction(turfOwner) {
    if (turfOwner == RDT) {
        return SP;
    } else if (turfOwner == SP) {
        return RDT;
    }
    return turfOwner;
}

getTurfOpposedFactionName(turfOwner) {
    new gangName[4];
    gangName = "nul";
    if (turfOwner == RDT) {
        gangName = "SP";
    } else if (turfOwner == SP) {
        gangName = "RDT";
    }
    return gangName;
}

getPlayerOpposedFaction(playerid) {
    new factionName[9];
    switch (GetPlayerTeam(playerid)) {
        case RDT:  {
            factionName = "SP";
            return factionName;
        }
        case SP:  {
            factionName = "RDT";
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

forward KickWithDelay(playerid);
public KickWithDelay(playerid) {
    Kick(playerid);
    return 1;
}

createHealthDrop(deadPlayerId) {
    new Float:deadPosX, Float:deadPosY, Float:deadPosZ;
    GetPlayerPos(deadPlayerId, deadPosX, deadPosY, deadPosZ);

    healthDrops = CreateDynamicPickup(1249, 19, deadPosX, deadPosY, (deadPosZ + 5));
}

createWeaponDrop(deadPlayerId) {
    new Float:deadPosX, Float:deadPosY, Float:deadPosZ;
    GetPlayerPos(deadPlayerId, deadPosX, deadPosY, deadPosZ);

    ammoDrops = CreateDynamicPickup(19832, 19, deadPosX, deadPosY, deadPosZ);
}

buildMembersList(playerFaction) {
    new returnData[500];
    new query[100];

    new headers[13];
    headers = "Rank\tNume\n";
    strcatmid(returnData, headers);

    if (playerFaction == RDT) {
        format(query, sizeof(query), "SELECT name, factionRank FROM Players WHERE faction = %d ORDER BY factionRank DESC;", RDT);
        new DBResult:queryResult = db_query(connection, query);
        do {
            new playerName[MAX_PLAYER_NAME];
            new playerFactionRank;

            db_get_field_assoc(queryResult, "name", playerName, sizeof(playerName));
            playerFactionRank = db_get_field_assoc_int(queryResult, "factionRank");

            new displayPlayerFactionRank[25];

            if (playerFactionRank == 7) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Dragon Leader", 7);
            } else if (playerFactionRank == 6) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Mountain Master", playerFactionRank);
            } else if (playerFactionRank == 4 || playerFactionRank == 5) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "White Paper Fan", playerFactionRank);
            } else if (playerFactionRank == 3) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Red Pole", playerFactionRank);
            } else if (playerFactionRank == 1 || playerFactionRank == 2) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Blue Lantern", playerFactionRank);
            }

            new temp[60];
            format(temp, sizeof(temp), "%s\t%s\n", displayPlayerFactionRank, playerName);
            strcatmid(returnData, temp);
        } while (db_next_row(queryResult));
        db_free_result(queryResult);
        return returnData;
    }

    if (playerFaction == SP) {
        format(query, sizeof(query), "SELECT name, factionRank FROM Players ORDER BY factionRank DESC WHERE faction = %d;", SP);
        new DBResult:queryResult = db_query(connection, query);
        while (db_num_rows(queryResult)) {
            new playerName[MAX_PLAYER_NAME];
            new playerFactionRank;

            db_get_field_assoc(queryResult, "name", playerName, sizeof(playerName));
            playerFactionRank = db_get_field_assoc_int(queryResult, "factionRank");

            new displayPlayerFactionRank[25];

            if (playerFactionRank == 7) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Pimp Boss", 7);
            } else if (playerFactionRank == 6) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Pimp", playerFactionRank);
            } else if (playerFactionRank == 4 || playerFactionRank == 5) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Wikkid", playerFactionRank);
            } else if (playerFactionRank == 3) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Fattam", playerFactionRank);
            } else if (playerFactionRank == 1 || playerFactionRank == 2) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "City Fish", playerFactionRank);
            }

            new temp[60];
            format(temp, sizeof(temp), "%s\t%s\n", displayPlayerFactionRank, playerName);
            strcatmid(returnData, temp);
        }
        db_free_result(queryResult);
        return returnData;
    }
    return returnData;

}

// -------------------- FACTION COMMANDS --------------------
COMMAND:joinwar(playerid, params[]) {
    new warStatus = GetSVarInt("isWarOn");
    if (warStatus == 1) {
        new isPlayerOnWar = GetPVarInt(playerid, "presentOnWar");
        if (isPlayerOnWar == 0) {
            if (!checkIfCivil(playerid)) {
                new attackedTurfId = GetSVarInt("warTurf");
                SetPlayerVirtualWorld(playerid, 2);
                SpawnPlayer(playerid);
                displayWarTextDraw(playerid);
                SetPVarInt(playerid, "presentOnWar", 1);
                ZoneFlashForAll(turfs[attackedTurfId][id], 0xFFFFFFAA);
                SendClientMessage(playerid, COLOR_BLUE, "Ai fost respawnat la HQ deoarece va incepe war-ul");
                return 1;
            }
        } else {
            SendClientMessage(playerid, COLOR_RED, "Deja esti prezent la war!");
            return 1;
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu este niciun war in desfasurare!");
        return 1;
    }
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

COMMAND:f(playerid, params[]) {
    new message[100];
    if (sscanf(params, "s[100]", message)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /f [mesaj]");
        return 1;
    } else {
        new messageToChat[144];

        new displayPlayerFactionRank[25];

        new playerFactionRank = players[playerid][rank];

        if (players[playerid][faction] == RDT) {
            if (playerFactionRank == 7) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Dragon Leader", 7);
            } else if (playerFactionRank == 6) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Mountain Master", playerFactionRank);
            } else if (playerFactionRank == 4 || playerFactionRank == 5) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "White Paper Fan", playerFactionRank);
            } else if (playerFactionRank == 3) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Red Pole", playerFactionRank);
            } else if (playerFactionRank == 1 || playerFactionRank == 2) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Blue Lantern", playerFactionRank);
            }
        }
        if (players[playerid][faction] == SP) {
            if (playerFactionRank == 7) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Pimp Boss", 7);
            } else if (playerFactionRank == 6) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Pimp", playerFactionRank);
            } else if (playerFactionRank == 4 || playerFactionRank == 5) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Wikkid", playerFactionRank);
            } else if (playerFactionRank == 3) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "Fattam", playerFactionRank);
            } else if (playerFactionRank == 1 || playerFactionRank == 2) {
                format(displayPlayerFactionRank, sizeof(displayPlayerFactionRank), "%s (%d)", "City Fish", playerFactionRank);
            }
        }
        if (players[playerid][faction] == CIVILIAN) {
            SendClientMessage(playerid, COLOR_RED, "Nu faci parte dintr-o mafie!");
            return 1;
        }

        format(messageToChat, sizeof(messageToChat), "** (%s) %s : (( %s )) **", displayPlayerFactionRank, players[playerid][name], message);

        new playerFaction = players[playerid][faction];

        for (new loopPlayerId = 0; loopPlayerId <= GetPlayerPoolSize(); loopPlayerId++) {
            if (playerFaction == players[loopPlayerId][faction]) {
                SendClientMessage(loopPlayerId, COLOR_BLUE, messageToChat);
            }
        }
        return 1;
    }
}

new selledGun[MAX_PLAYERS];
new acceptgunTimer;
COMMAND:sellgun(playerid, params[]) {
    new takerId;
    new weaponName[7];
    if (sscanf(params, "us[7]", takerId, weaponName)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /sellgun [nume / id player] [nume arma]!");
        return 1;
    } else {
        if (takerId == playerid) {
            SendClientMessage(playerid, COLOR_RED, "Nu iti poti vinde arme tie insuti!");
            return 1;
        }

        new takerName[MAX_PLAYER_NAME];
        GetPlayerName(takerId, takerName, sizeof(takerName));

        new giverName[MAX_PLAYER_NAME];
        GetPlayerName(playerid, giverName, sizeof(giverName));

        new nameDeagle[7], nameM4[7], nameRifle[7];
        nameDeagle = "Deagle";
        nameM4 = "M4";
        nameRifle = "Rifle";

        new Float:takerPosX, Float:takerPosY, Float:takerPosZ;
        GetPlayerPos(takerId, takerPosX, takerPosY, takerPosZ);

        if (IsPlayerInRangeOfPoint(playerid, 20, takerPosX, takerPosY, takerPosZ)) {
            new message[45 + MAX_PLAYER_NAME];
            if (isequal(weaponName, nameDeagle)) {
                selledGun[takerId] = 24;
                format(message, sizeof(message), "Ai asamblat un Deagle si i l-ai dat lui %s!", takerName);
                SendClientMessage(playerid, COLOR_BLUE, message);
                format(message, sizeof(message), "Foloseste: [/acceptgun %d] pentru a primi un Deagle de la %s!", playerid, giverName);
                SendClientMessage(takerId, COLOR_BLUE, message);
                acceptgunTimer = SetTimerEx("cmd_acceptgun", 30000, false, "i", playerid);
            } else if (isequal(weaponName, nameM4)) {
                selledGun[takerId] = 31;
                format(message, sizeof(message), "Ai asamblat un M4 si i l-ai dat lui %s!", takerName);
                SendClientMessage(playerid, COLOR_BLUE, message);
                format(message, sizeof(message), "Foloseste: [/acceptgun %d] pentru a primi un M4 de la %s!", playerid, giverName);
                SendClientMessage(takerId, COLOR_BLUE, message);
                acceptgunTimer = SetTimerEx("cmd_acceptgun", 30000, false, "i", playerid);
            } else if (isequal(weaponName, nameRifle)) {
                selledGun[takerId] = 33;
                format(message, sizeof(message), "Ai asamblat o Rifle si i l-ai dat lui %s!", takerName);
                SendClientMessage(playerid, COLOR_BLUE, message);
                format(message, sizeof(message), "Foloseste: [/acceptgun %d] pentru a primi o Rifle de la %s!", playerid, giverName);
                SendClientMessage(takerId, COLOR_BLUE, message);
                acceptgunTimer = SetTimerEx("cmd_acceptgun", 30000, false, "i", playerid);
            }
        } else {
            new message[52 + MAX_PLAYER_NAME];
            format(message, sizeof(message), "Esti prea departe de %s pentru a-i da arma!", takerName);
            SendClientMessage(playerid, COLOR_RED, message);
            return 1;
        }
    }
    return 1;
}

COMMAND:acceptgun(playerid, params[]) {
    new giverId;
    if (sscanf(params, "u", giverId)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /acceptgun [nume / id player]");
        return 1;
    } else {
        new giverName[MAX_PLAYER_NAME];
        GetPlayerName(giverId, giverName, sizeof(giverName));

        new Float:giverPosX, Float:giverPosY, Float:giverPosZ;
        GetPlayerPos(playerid, giverPosX, giverPosY, giverPosZ);

        if (IsPlayerInRangeOfPoint(playerid, 20, giverPosX, giverPosY, giverPosZ)) {
            new message[50 + MAX_PLAYER_NAME];
            if (selledGun[playerid] == 24) {
                GivePlayerWeapon(playerid, 24, 100);
                format(message, sizeof(message), "Ai primit un Deagle de la %s!", giverName);
                SendClientMessage(playerid, COLOR_BLUE, message);
            } else if (selledGun[playerid] == 31) {
                GivePlayerWeapon(playerid, 31, 100);
                format(message, sizeof(message), "Ai primit un M4 de la %s!", giverName);
                SendClientMessage(playerid, COLOR_BLUE, message);
            } else if (selledGun[playerid] == 33) {
                GivePlayerWeapon(playerid, 33, 100);
                format(message, sizeof(message), "Ai primit o Rifle de la %s!", giverName);
                SendClientMessage(playerid, COLOR_BLUE, message);
            }
        } else {
            new message[52 + MAX_PLAYER_NAME];
            format(message, sizeof(message), "Te-ai indepartat prea mult de %s pentru a primi arma!", giverName);
            SendClientMessage(playerid, COLOR_RED, message);
            return 1;
        }

    }
    return 1;
}

#define DRUGTIMER 1125000
COMMAND:usedrugs(playerid, params[]) {
    new drugUsed[8];
    if (sscanf(params, "s[8]", drugUsed)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /usedrugs <meth | cocaine | cox>");
        return 1;
    } else {
        new Float:oldHealth;
        GetPlayerHealth(playerid, oldHealth);
        new drugMeth[8], drugCocaine[8], drugCox[8];
        drugMeth = "meth";
        drugCocaine = "cocaine";
        drugCox = "cox";
        if (isequal(drugUsed, drugMeth)) {
            new Float:newHealth = oldHealth + 20;
            if (newHealth > 100) {
                SendClientMessage(playerid, COLOR_RED, "Nu poti lua drogul acum!");
                return 1;
            }
            TogglePlayerControllable(playerid, 0);
            ApplyAnimation(playerid, "int_house", "bed_loop_l", 4.1, 1, 0, 1, 0, 15000, 0);
            SetPlayerDrunkLevel(playerid, 5000);
            SetTimerEx("clearDrugsEffect", 15000, false, "i", playerid);

            SetPlayerHealth(playerid, newHealth);

            SetTimerEx("damageFromDrugs", DRUGTIMER, false, "ii", playerid, 1);
        } else if (isequal(drugUsed, drugCocaine)) {
            new Float:newHealth = oldHealth + 30;
            if (newHealth > 100) {
                SendClientMessage(playerid, COLOR_RED, "Nu poti lua drogul acum!");
                return 1;
            }
            TogglePlayerControllable(playerid, 0);
            ApplyAnimation(playerid, "int_house", "bed_loop_l", 4.1, 1, 0, 1, 0, 15000, 0);
            SetPlayerDrunkLevel(playerid, 5000);
            SetTimerEx("clearDrugsEffect", 15000, false, "i", playerid);

            SetPlayerHealth(playerid, newHealth);

            SetTimerEx("damageFromDrugs", DRUGTIMER, false, "ii", playerid, 2);
        } else if (isequal(drugUsed, drugCox)) {
            new Float:newHealth = oldHealth + 40;
            if (newHealth > 100) {
                SendClientMessage(playerid, COLOR_RED, "Nu poti lua drogul acum!");
                return 1;
            }
            TogglePlayerControllable(playerid, 0);
            ApplyAnimation(playerid, "int_house", "bed_loop_l", 4.1, 1, 0, 1, 0, 15000, 0);
            SetPlayerDrunkLevel(playerid, 5000);
            SetTimerEx("clearDrugsEffect", 15000, false, "i", playerid);

            SetPlayerHealth(playerid, newHealth);

            SetTimerEx("damageFromDrugs", DRUGTIMER, false, "ii", playerid, 3);
        }
        return 1;
    }
}

forward clearDrugsEffect(playerid);
public clearDrugsEffect(playerid) {
    SetPlayerDrunkLevel(playerid, 0);
    ClearAnimations(playerid, 0);
    TogglePlayerControllable(playerid, 1);
}

forward damageFromDrugs(playerid, drugUsed);
public damageFromDrugs(playerid, drugUsed) {
    new Float:oldHealth;
    GetPlayerHealth(playerid, oldHealth);
    if (drugUsed == 1) {
        SetPlayerHealth(playerid, (oldHealth - 20));
        SendClientMessage(playerid, COLOR_RED, "Din cauza meth-ului ai pierdut 20 hp!");
    } else if (drugUsed == 2) {
        SetPlayerHealth(playerid, (oldHealth - 30));
        SendClientMessage(playerid, COLOR_RED, "Din cauza cocainei ai pierdut 30 hp!");
    } else if (drugUsed == 3) {
        SetPlayerHealth(playerid, (oldHealth - 40));
        SendClientMessage(playerid, COLOR_RED, "Din cauza cox-ului ai pierdut 40 hp!");
    }
}

COMMAND:members(playerid) {
    if (checkIfCivil(playerid)) {
        SendClientMessage(playerid, COLOR_RED, "Nu faci parte din nicio factiune!");
        return 1;
    }
    new playerFaction = players[playerid][faction];
    switch (playerFaction) {
        case RDT:  {
            new membersData[500];
            membersData = buildMembersList(RDT);
            // printf("membersData: %s", membersData);

            OpenDialog(playerid, "", DIALOG_STYLE_TABLIST_HEADERS,
                "Membrii mafiei {D40000}Red Dragons Triad",
                membersData,
                "Close", "");
        }
        case SP:  {
            new membersData[500];
            membersData = buildMembersList(SP);

            OpenDialog(playerid, "", DIALOG_STYLE_TABLIST_HEADERS,
                "Membrii mafiei {D415D1}Southern Pimps",
                membersData,
                "Close", "");
        }
    }
    return 1;
}

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

COMMAND:turfs(playerid) {
    new turfsShownStatus = GetPVarInt(playerid, "areTurfsShown");
    if (turfsShownStatus == 0) {
        for (new turfid = 0; turfid <= 23; turfid++) {
            new turfOwner;
            turfOwner = turfs[turfid][owner];
            switch (turfOwner) {
                case RDT:
                    ShowZoneForPlayer(playerid, turfs[turfid][id], 0xFF000099, 0xFFFFFFFF, 0xFFFFFFFF);
                case SP:
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

displayWarTextDraw(playerid) {
    new statsBoxText[2];
    format(statsBoxText, sizeof(statsBoxText), "_");

    new turfNameText[30];
    new turfNr = GetSVarInt("warTurf");
    format(turfNameText, sizeof(turfNameText), "Turf: %s", turfs[turfNr][name]);

    new warMafiaRounds[50];
    format(warMafiaRounds, sizeof(warMafiaRounds), "Rounds %s %d - %d %s", "SP", 0, 0, "RDT");

    new warTotalRounds[16];
    format(warTotalRounds, sizeof(warTotalRounds), "Runda %d / 15", 0);

    new warRoundScoreText[50];
    format(warRoundScoreText, sizeof(warRoundScoreText), "%s %d - %d %s", "SP", 0, 0, "RDT");

    new warTurfPlayersText[50];
    format(warTurfPlayersText, sizeof(warTurfPlayersText), "Pe turf: %s %d - %d %s", "SP", 0, 0, "RDT");

    new warPlayerStatsText[25];
    format(warPlayerStatsText, sizeof(warPlayerStatsText), "Ucideri: %d Morti: %d", 0, 0);

    tdWarBox2[playerid] = CreatePlayerTextDraw(playerid, 555.000000, 350.000000, "_");
    PlayerTextDrawFont(playerid, tdWarBox2[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarBox2[playerid], 0.466666, 8.000001);
    PlayerTextDrawTextSize(playerid, tdWarBox2[playerid], 281.500000, 117.500000);
    PlayerTextDrawSetOutline(playerid, tdWarBox2[playerid], 2);
    PlayerTextDrawSetShadow(playerid, tdWarBox2[playerid], 1);
    PlayerTextDrawAlignment(playerid, tdWarBox2[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarBox2[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarBox2[playerid], -16776961);
    PlayerTextDrawBoxColor(playerid, tdWarBox2[playerid], -236);
    PlayerTextDrawUseBox(playerid, tdWarBox2[playerid], 1);
    PlayerTextDrawSetProportional(playerid, tdWarBox2[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarBox2[playerid], 0);

    tdWarLocation[playerid] = CreatePlayerTextDraw(playerid, 555.000000, 349.000000, turfNameText);
    PlayerTextDrawFont(playerid, tdWarLocation[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarLocation[playerid], 0.341666, 1.500000);
    PlayerTextDrawTextSize(playerid, tdWarLocation[playerid], 485.000000, 174.500000);
    PlayerTextDrawSetOutline(playerid, tdWarLocation[playerid], 0);
    PlayerTextDrawSetShadow(playerid, tdWarLocation[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdWarLocation[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarLocation[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarLocation[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdWarLocation[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdWarLocation[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdWarLocation[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarLocation[playerid], 0);

    tdWarBox[playerid] = CreatePlayerTextDraw(playerid, 555.000000, 351.000000, "_");
    PlayerTextDrawFont(playerid, tdWarBox[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarBox[playerid], 0.433333, 7.700006);
    PlayerTextDrawTextSize(playerid, tdWarBox[playerid], 283.500000, 115.000000);
    PlayerTextDrawSetOutline(playerid, tdWarBox[playerid], 2);
    PlayerTextDrawSetShadow(playerid, tdWarBox[playerid], 1);
    PlayerTextDrawAlignment(playerid, tdWarBox[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarBox[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarBox[playerid], -16776961);
    PlayerTextDrawBoxColor(playerid, tdWarBox[playerid], 90);
    PlayerTextDrawUseBox(playerid, tdWarBox[playerid], 1);
    PlayerTextDrawSetProportional(playerid, tdWarBox[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarBox[playerid], 0);

    tdWarScore[playerid] = CreatePlayerTextDraw(playerid, 555.000000, 362.000000, "SP 0 - 0 RDT");
    PlayerTextDrawFont(playerid, tdWarScore[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarScore[playerid], 0.283333, 1.649999);
    PlayerTextDrawTextSize(playerid, tdWarScore[playerid], 360.000000, 182.000000);
    PlayerTextDrawSetOutline(playerid, tdWarScore[playerid], 0);
    PlayerTextDrawSetShadow(playerid, tdWarScore[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdWarScore[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarScore[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarScore[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdWarScore[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdWarScore[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdWarScore[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarScore[playerid], 0);

    tdWarRoundsCount[playerid] = CreatePlayerTextDraw(playerid, 555.000000, 376.000000, "Round 1 / 15");
    PlayerTextDrawFont(playerid, tdWarRoundsCount[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarRoundsCount[playerid], 0.254166, 1.500000);
    PlayerTextDrawTextSize(playerid, tdWarRoundsCount[playerid], 355.000000, 102.000000);
    PlayerTextDrawSetOutline(playerid, tdWarRoundsCount[playerid], 0);
    PlayerTextDrawSetShadow(playerid, tdWarRoundsCount[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdWarRoundsCount[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarRoundsCount[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarRoundsCount[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdWarRoundsCount[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdWarRoundsCount[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdWarRoundsCount[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarRoundsCount[playerid], 0);

    tdWarOnTurf[playerid] = CreatePlayerTextDraw(playerid, 556.000000, 390.000000, "Pe turf: SP 0 - 0 RDT");
    PlayerTextDrawFont(playerid, tdWarOnTurf[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarOnTurf[playerid], 0.237498, 1.699998);
    PlayerTextDrawTextSize(playerid, tdWarOnTurf[playerid], 355.000000, 117.000000);
    PlayerTextDrawSetOutline(playerid, tdWarOnTurf[playerid], 0);
    PlayerTextDrawSetShadow(playerid, tdWarOnTurf[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdWarOnTurf[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarOnTurf[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarOnTurf[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdWarOnTurf[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdWarOnTurf[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdWarOnTurf[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarOnTurf[playerid], 0);

    tdWarStats[playerid] = CreatePlayerTextDraw(playerid, 557.000000, 405.000000, "Ucideri: 0 Morti: 0");
    PlayerTextDrawFont(playerid, tdWarStats[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdWarStats[playerid], 0.295832, 1.649999);
    PlayerTextDrawTextSize(playerid, tdWarStats[playerid], 355.000000, 102.000000);
    PlayerTextDrawSetOutline(playerid, tdWarStats[playerid], 0);
    PlayerTextDrawSetShadow(playerid, tdWarStats[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdWarStats[playerid], 2);
    PlayerTextDrawColor(playerid, tdWarStats[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdWarStats[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdWarStats[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdWarStats[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdWarStats[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdWarStats[playerid], 0);

    PlayerTextDrawShow(playerid, PlayerText:tdWarBox2[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarLocation[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarBox[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarScore[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarRoundsCount[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarOnTurf[playerid]);
    PlayerTextDrawShow(playerid, PlayerText:tdWarStats[playerid]);
}

preparePlayersForWar(attackedTurfId) {
    SendClientMessageToAll(COLOR_PURPLE, "War-urile intre mafii vor incepe incurand!");
    SendClientMessageToAll(COLOR_PURPLE, "Toti mafiotii vor fi respawnati la HQ-uri in cateva secunde");

    new j = GetPlayerPoolSize();
    for (new playerid = 0; playerid <= j; playerid++) {
        if (!checkIfCivil(playerid)) {
            SetPlayerVirtualWorld(playerid, 2);
            SpawnPlayer(playerid);
            displayWarTextDraw(playerid);
            SetPVarInt(playerid, "presentOnWar", 1);
            ZoneFlashForAll(turfs[attackedTurfId][id], 0xFFFFFFAA);
            SendClientMessage(playerid, COLOR_BLUE, "Ai fost respawnat la HQ deoarece va incepe war-ul");
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

pointFromKill(killerid) {
    if (GetPlayerTeam(killerid) == RDT) {
        new pointRDT = GetSVarInt("pointsRDT");
        SetSVarInt("pointsRDT", (pointRDT + 1));
    } else if (GetPlayerTeam(killerid) == SP) {
        new pointSP = GetSVarInt("pointsSP");
        SetSVarInt("pointsSP", (pointSP + 1));
    }
}

new influenceTimer, endWarTimer, roundTimer;
new updatePlayersOnTurfTdTimer;
startWar(const turf_id[], attackerid) {
    new attacker[9];
    attacker = getPlayerFactionName(attackerid);

    new defender[9];
    defender = getPlayerOpposedFaction(attackerid);

    new attackedTurfId = strval(turf_id);

    new startMessage[100];
    format(startMessage, sizeof(startMessage), "%s vor ataca turf-ul cu numarul %d detinut de mafia %s", attacker, attackedTurfId, defender);
    SendClientMessageToAll(COLOR_PURPLE, startMessage);

    SetSVarInt("warTurf", attackedTurfId);

    prepareTurf(attackedTurfId);
    preparePlayersForWar(attackedTurfId);

    SetSVarInt("roundsRDT", 0);
    SetSVarInt("roundsSP", 0);

    SetSVarInt("currentRound", 1);

    SetSVarInt("pointsRDT", 0);
    SetSVarInt("pointsSP", 0);

    SetSVarInt("isWarOn", 1);
    SetSVarInt("warWinner", 0);

    updatePlayersOnTurfTdTimer = SetTimer("updatePlayersOnTurfTdTimer", 7500, true);

    // prod
    // influenceTimer = SetTimer("pointFromInfluence", 37500, true);
    // roundTimer = SetTimer("advanceRound", 150000, true);

    // endWarTimer = SetTimer("endWar", 2250000, false);

    // dev
    influenceTimer = SetTimer("pointFromInfluence", 10000, true);
    roundTimer = SetTimer("advanceRound", 20000, true);

    endWarTimer = SetTimer("endWar", 60000, false);
}

getPlayersOnTurf(playerMafia, Float:turfPoiX, Float:turfPoiY, Float:turfPoiZ) {
    new playersOnTurf;
    playersOnTurf = 0;
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (GetPlayerVirtualWorld(i) == 2) {
            if (IsPlayerInRangeOfPoint(i, 250, turfPoiX, turfPoiY, turfPoiZ)) {
                if (GetPlayerTeam(i) == playerMafia) {
                    playersOnTurf = playersOnTurf + 1;
                }
            }
        }
    }
    return playersOnTurf;
}

forward updatePlayersOnTurfTd();
public updatePlayersOnTurfTd() {
    new playersRDT, playersSP;

    playersRDT = getPlayersOnTurf(RDT, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));
    playersSP = getPlayersOnTurf(SP, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));

    new warTurfPlayersText[50];
    format(warTurfPlayersText, sizeof(warTurfPlayersText), "Pe turf: %s %d - %d %s", "SP", playersSP, playersRDT, "RDT");

    new warPoints[15];
    new spPoints = GetSVarInt("pointsSP");
    new rdtPoints = GetSVarInt("pointsRDT");
    format(warPoints, sizeof(warPoints), "SP %d - %d RDT", spPoints, rdtPoints);

    new j = GetPlayerPoolSize();
    for (new playerId = 0; playerId <= j; playerId++) {
        if (GetPlayerVirtualWorld(playerId) == 2) {
            PlayerTextDrawSetString(playerId, PlayerText:tdWarOnTurf[playerId], warTurfPlayersText);
            PlayerTextDrawSetString(playerId, PlayerText:tdWarScore[playerId], warPoints);
        }
    }
}

forward advanceRound();
public advanceRound() {
    // new rdtRounds = GetSVarInt("roundsRDT");
    // new spRounds = GetSVarInt("roundsSP");
    // if (rdtRounds >= 8) {
    //     SetSVarInt("warWinner", RDT);
    //     endWar();
    // } else if (spRounds >= 8) {
    //     SetSVarInt("warWinner", SP);
    //     endWar();
    // }
    new rdtRounds = GetSVarInt("roundsRDT");
    new spRounds = GetSVarInt("roundsSP");
    new totalRounds = GetSVarInt("currentRound");
    if (totalRounds == 15) {
        if (rdtRounds >= spRounds) {
            SetSVarInt("warWinner", RDT);
            endWar();
        } else if (rdtRounds <= spRounds) {
            SetSVarInt("warWinner", SP);
            endWar();
        }
    }

    new pointsRDT = GetSVarInt("pointsRDT");
    new pointsSP = GetSVarInt("pointsSP");

    if (pointsRDT > pointsSP) {
        new roundsRDT = GetSVarInt("roundsRDT");
        SetSVarInt("roundsRDT", (roundsRDT + 1));
        SetSVarInt("pointsRDT", 0);
    } else if (pointsRDT < pointsSP) {
        new roundsSP = GetSVarInt("roundsSP");
        SetSVarInt("roundsSP", (roundsSP + 1));
        SetSVarInt("pointsSP", 0);
    }

    new oldRoundCount = GetSVarInt("currentRound");
    SetSVarInt("currentRound", (oldRoundCount + 1));

    new warRoundScoreText[50];
    format(warRoundScoreText, sizeof(warRoundScoreText), "%s %d - %d %s", "SP", spRounds, rdtRounds, "RDT");

    new warTotalRounds[16];
    format(warTotalRounds, sizeof(warTotalRounds), "Runda %d / 15", GetSVarInt("currentRound"));

    new j = GetPlayerPoolSize();
    for (new playerid = 0; playerid <= j; playerid++) {
        if (GetPlayerVirtualWorld(playerid) == 2) {
            PlayerTextDrawSetString(playerid, PlayerText:tdWarScore[playerid], warRoundScoreText);
            PlayerTextDrawSetString(playerid, PlayerText:tdWarRoundsCount[playerid], warTotalRounds);
        }
    }
}

forward pointFromInfluence();
public pointFromInfluence() {
    new playersRDT, playersSP;

    playersRDT = getPlayersOnTurf(RDT, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));
    playersSP = getPlayersOnTurf(SP, GetSVarFloat("poiX"), GetSVarFloat("poiY"), GetSVarFloat("poiZ"));

    new pointRDT = GetSVarInt("pointsRDT");
    new pointSP = GetSVarInt("pointsSP");
    if (playersRDT > playersSP) {
        SetSVarInt("pointsRDT", (pointRDT + 1));
    } else if (playersRDT < playersSP) {
        SetSVarInt("pointsSP", (pointSP + 1));
    }

    new j = GetPlayerPoolSize();
    for (new playerid = 0; playerid <= j; playerid++) {
        if (GetPlayerVirtualWorld(playerid) == 2) {
            new warTurfPlayersText[50];
            format(warTurfPlayersText, sizeof(warTurfPlayersText), "On turf: %s %d - %d %s", "SP", playersSP, playersRDT, "RDT");
            PlayerTextDrawSetString(playerid, PlayerText:tdWarOnTurf[playerid], warTurfPlayersText);
        }
    }
}

endWar() {
    // hide text draws
    new j = GetPlayerPoolSize();
    for (new playerid = 0; playerid <= j; playerid++) {
        if (GetPlayerVirtualWorld(playerid) == 2) {
            PlayerTextDrawHide(playerid, PlayerText:tdWarBox2[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarLocation[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarBox[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarScore[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarRoundsCount[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarOnTurf[playerid]);
            PlayerTextDrawHide(playerid, PlayerText:tdWarStats[playerid]);

            // showBestPlayer(i);
            // showWorstPlayer(i);

            SetPlayerVirtualWorld(playerid, 0);
            SpawnPlayer(playerid);
        }
    }
    new warTurfId = GetSVarInt("warTurf");
    ZoneStopFlashForAll(turfs[warTurfId][id]);
    SetSVarInt("isWarOn", 0);

    new warWinner = GetSVarInt("warWinner");
    checkTurfWarOwner(warWinner);

    KillTimer(influenceTimer);
    KillTimer(endWarTimer);
    KillTimer(roundTimer);
    KillTimer(updatePlayersOnTurfTdTimer);

    SendClientMessageToAll(COLOR_BLUE, "War-ul s-a incheiat");
}

checkTurfWarOwner(winnerMafia) {
    new warTurf = GetSVarInt("warTurf");

    new message[100];
    new oldOwner = turfs[warTurf][owner];
    new oldOwnerName[4];
    oldOwnerName = getTurfOwnerName(oldOwner);
    new opposedMafia = getTurfOpposedFaction(oldOwner);
    new opposedMafiaName[4];
    opposedMafiaName = getTurfOpposedFactionName(oldOwner);

    if (oldOwner == winnerMafia) {
        format(message, sizeof(message), "Mafia %s a reusit sa apere turf-ul cu numarul %d, fiind atacati de catre %s!", oldOwnerName, warTurf, opposedMafiaName);
        SendClientMessageToAll(COLOR_GREEN, message);
    } else {
        format(message, sizeof(message), "Mafia %s a reusit sa cucereasca turf-ul cu numarul %d de la mafia %s!", opposedMafiaName, warTurf, oldOwnerName);
        SendClientMessageToAll(COLOR_GREEN, message);

        turfs[warTurf][owner] = opposedMafia;
        updateTurfData(warTurf);

        new query[100];
        format(query, sizeof(query), "UPDATE Turfs SET owner = %d WHERE id = %d;", opposedMafia, (turfs[warTurf][id] + 1));
        db_free_result(db_query(connection, query));
    }
}

updateTurfData(turfId) {
    switch (turfs[turfId][owner]) {
        case RDT:  {
            for (new playerid = 0; playerid <= GetPlayerPoolSize(); playerid++) {
                HideZoneForPlayer(playerid, turfs[turfId][id]);
                ShowZoneForPlayer(playerid, turfs[turfId][id], 0xFF000099, 0xFFFFFFFF, 0xFFFFFFFF);
            }
        }
        case SP:  {
            for (new playerid = 0; playerid <= GetPlayerPoolSize(); playerid++) {
                HideZoneForPlayer(playerid, turfs[turfId][id]);
                ShowZoneForPlayer(playerid, turfs[turfId][id], 0x8A2BE299, 0xFFFFFFFF, 0xFFFFFFFF);
            }
        }
    }

}

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
        SendClientMessage(playerid, COLOR_BLUE, "Ai luat din seif un Deagle!");
    }
    return 1;
}

COMMAND:order2(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0 && players[playerid][rank] >= 2) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Ai luat din seif un Deagle si un M4!");
    }
    return 1;
}

COMMAND:order3(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0 && players[playerid][rank] >= 3) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        SendClientMessage(playerid, COLOR_BLUE, "Ai luat din seif un Deagle, M4 si un Rifle!");
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
        SendClientMessage(playerid, COLOR_BLUE, "Ai luat din seif un Deagle, M4, Combat, Tec-uri si un Rifle!");
    }
    return 1;
}

// -------------------- ADMIN COMMANDS --------------------

COMMAND:setfactionleader(playerid, params[]) {
    new input[3];
    if (sscanf(params, "rs[4]", input[0], input[1])) {
        SendClientMessage(playerid, 0xFF0000FF, "Foloseste: /setfactionleader <id lider> <RDT | SP>");
    } else {
        if (IsPlayerAdmin(playerid)) {
            if (IsPlayerConnected(input[0])) {
                new playerName[30];
                GetPlayerName(input[0], playerName, sizeof(playerName));

                new spFaction[4], rdtFaction[4];
                spFaction = "SP";
                rdtFaction = "RDT";
                if (isequal(input[1], spFaction)) {
                    players[input[0]][faction] = SP;
                    players[input[0]][rank] = 7;
                    putSP(input[0], players[input[0]][rank]);
                } else if (isequal(input[1], rdtFaction)) {
                    players[input[0]][faction] = RDT;
                    players[input[0]][rank] = 7;
                    putRDT(input[0], players[input[0]][rank]);
                }

                new message[150];
                format(message, sizeof(message), "Noul lider al mafiei %s este %s. Felicitari!", input[1], playerName);
                SendClientMessageToAll(COLOR_GREEN, message);
            }
        }
    }
    return 1;
}

COMMAND:setfactionmember(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        new takerRank;
        new takerMafia[4];
        if (sscanf(params, "urs[4]", takerId, takerRank, takerMafia)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /setfactionmember <id | nume player> <rank> <SP | RDT>");
            return 1;
        } else {
            new playerName[MAX_PLAYER_NAME];
            GetPlayerName(takerId, playerName, sizeof(playerName));

            new spFaction[4], rdtFaction[4];
            spFaction = "SP";
            rdtFaction = "RDT";
            if (isequal(takerMafia, spFaction)) {
                players[takerId][faction] = SP;
                players[takerId][rank] = takerRank;
                putSP(takerId, players[takerId][rank]);
            } else if (isequal(takerMafia, rdtFaction)) {
                players[takerId][faction] = RDT;
                players[takerId][rank] = takerRank;
                putRDT(takerId, players[takerId][rank]);
            }
            return 1;
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu este admin pentru a folosi aceasta comanda!");
        return 1;
    }
}