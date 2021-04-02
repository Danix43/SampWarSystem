#include <a_samp>
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

static DB:connection;

// all turfs 
new turfs[25];

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
    return 1;
}

public OnGameModeExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
    return 1;
}


loadTurfs() {
    turfs[0] = CreateZone(1233.0001831054688, 618.5, 1687.0001831054688, 1082.5);
    CreateZoneBorders(turfs[0]);
    turfs[1] = CreateZone(1687.0000457763672, 618.5, 2118.000045776367, 1082.5);
    CreateZoneBorders(turfs[1]);
    turfs[2] = CreateZone(2118.0000915527344, 618.5, 2549.0000915527344, 1082.5);
    CreateZoneBorders(turfs[2]);
    turfs[3] = CreateZone(2548.0003051757812, 619.5, 2934.0003051757812, 1082.5);
    CreateZoneBorders(turfs[3]);
    turfs[4] = CreateZone(2548.0003051757812, 1082.5, 2934.0003051757812, 1545.5);
    CreateZoneBorders(turfs[4]);
    turfs[5] = CreateZone(2118.000289916992, 1082.5, 2549.000289916992, 1546.5);
    CreateZoneBorders(turfs[5]);

    turfs[6] = CreateZone(1688.0002899169922, 1082.5, 2119.000289916992, 1546.5);
    CreateZoneBorders(turfs[6]);
    turfs[7] = CreateZone(1257.0001220703125, 1082.5, 1688.0001220703125, 1546.5);
    CreateZoneBorders(turfs[7]);
    turfs[8] = CreateZone(826.0001831054688, 1081.5, 1256.0001831054688, 1546.5);
    CreateZoneBorders(turfs[8]);
    turfs[9] = CreateZone(1258.0003051757812, 2010.4999694824219, 1689.0003051757812, 2474.499969482422);
    CreateZoneBorders(turfs[9]);
    turfs[10] = CreateZone(825.0000610351562, 1546.5, 1256.0000610351562, 2010.5);
    CreateZoneBorders(turfs[10]);
    turfs[11] = CreateZone(1256.0001220703125, 1546.5, 1687.0001220703125, 2010.5);
    CreateZoneBorders(turfs[11]);

    turfs[12] = CreateZone(1687.0003051757812, 1546.5, 2118.0003051757812, 2010.5);
    CreateZoneBorders(turfs[12]);
    turfs[13] = CreateZone(2117.0003662109375, 1545.5, 2548.0003662109375, 2009.5);
    CreateZoneBorders(turfs[13]);
    turfs[14] = CreateZone(2548.0003662109375, 1545.5, 2979.0003662109375, 2009.5);
    CreateZoneBorders(turfs[14]);
    turfs[15] = CreateZone(2548.0003051757812, 2009.5, 2979.0003051757812, 2473.5);
    CreateZoneBorders(turfs[15]);
    turfs[16] = CreateZone(2118.0003051757812, 2009.5, 2549.0003051757812, 2473.5);
    CreateZoneBorders(turfs[16]);
    turfs[17] = CreateZone(1688.0002899169922, 2010.5, 2119.000289916992, 2474.5);
    CreateZoneBorders(turfs[17]);

    turfs[18] = CreateZone(826.9999389648438, 2010.4999771118164, 1257.9999389648438, 2474.4999771118164);
    CreateZoneBorders(turfs[18]);
    turfs[19] = CreateZone(2548.0003662109375, 2473.5, 2979.0003662109375, 2910.5);
    CreateZoneBorders(turfs[19]);
    turfs[20] = CreateZone(2117.0003662109375, 2473.4999809265137, 2548.0003662109375, 2910.4999809265137);
    CreateZoneBorders(turfs[20]);
    turfs[21] = CreateZone(1688.0002899169922, 2474.4999809265137, 2119.000289916992, 2911.4999809265137);
    CreateZoneBorders(turfs[21]);
    turfs[22] = CreateZone(1350.9921875, 2474.5, 1688.9921875, 2911.5);
    CreateZoneBorders(turfs[22]);
    turfs[23] = CreateZone(1037.98046875, 2474.5, 1352.98046875, 2911.5);
    CreateZoneBorders(turfs[23]);
}

public OnPlayerRequestClass(playerid, classid) {
    // SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
    // SpawnPlayer(playerid);
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

// ----------------------- DB RELATED ----------------------- 

createDBs() {
    connection = db_open("data.db");

    if (connection) {
        print("connected to db");
    } else {
        print("failed to connect to db");
    }

    new query[256] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank TEXT NOT NULL)";
    db_free_result(db_query(connection, query));
    print("player database loaded");
    //                                                                                                                                  Float:gzMinX, Float:gzMinY, Float:gzMaxX, Float:gzMaxY
    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, owner TEXT NOT NULL, owner_color TEXT NOT NULL, minX INTEGER, minY INTEGER, maxX INTEGER, maxY INTEGER)";
    db_free_result(db_query(connection, query));
    print("turfs database loaded");
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
        SendClientMessage(playerid, 0x0000FF, "Your logged in!");
    } else {
        SendClientMessage(playerid, 0xFF0000, "Login failed!");
        SetTimerEx("KickWithDelay", 1000, false, "i", playerid);
    }
}

forward KickWithDelay(playerid);
public KickWithDelay(playerid) {
    Kick(playerid);
    return 1;
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

COMMAND:turfs(playerid, params[]) {
    for (new i = 0; i < 23; i++) {
        ShowZoneForPlayer(playerid, turfs[i], 0xFF000073, 0xFFFFFFAA, 0xFFFFFFAA);
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
        SendClientMessage(playerid, 0xFF0000FF, "Foloseste: /id [id|nume player]");
    } else {
        
    }
    return 1;
}