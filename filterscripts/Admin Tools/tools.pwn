#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <strlib>

#define FILTERSCRIPT

static DB:connection;

// ----------------------- GAME CALLBACKS ----------------------- 

public OnFilterScriptInit() {
    loadDB();
    print("Admin Components loaded");
}

public OnFilterScriptExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
}

// ----------------------- SETUPS ----------------------- 

loadDB() {
    connection = db_open("data.db");

    if (connection) {

    } else {
        print("failed to connect to db");
    }

    new query[256] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank TEXT NOT NULL)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, owner TEXT NOT NULL, owner_color TEXT NOT NULL, minX INTEGER, minY INTEGER, maxX INTEGER, maxY INTEGER)";
    db_free_result(db_query(connection, query));
}

// --------------------- COMMANDS --------------------- 

COMMAND:spec(playerid, params[]) {
    return 1;
}

COMMAND:ban(playerid, params[]) {
    return 1;
}

COMMAND:kick(playerid, params[]) {
    return 1;
}

COMMAND:slap(playerid, params[]) {
    return 1;
}

COMMAND:skemamilsugiana(playerid, params[]) {
    return 1;
}

COMMAND:setfactionleader(playerid, params[]) {
    new input[3];
    if (sscanf(params, "rs[4]", input[0], input[1])) {
        SendClientMessage(playerid, 0xFF0000FF, "Foloseste: /setfactionleader <id lider> <RDT | SP>");
    } else {
        if (IsPlayerAdmin(playerid)) {
            if (IsPlayerConnected(input[0])) {
                new name[30];
                GetPlayerName(input[0], name, sizeof(name));
                new query[150];
                format(query, sizeof(query),
                    "UPDATE Players SET player_faction = '%s', faction_rank = '%s' WHERE player_name = '%s'",
                    input[1], "7", name);
                if (db_free_result(db_query(connection, query)) == 1) {
                    new message[150];
                    format(message, sizeof(message), "Noul lider al mafiei %s este %s. Felicitari!", input[1], name);
                    SendClientMessageToAll(0x00FF00FF, message);
                }
            }
        }
    }
    return 1;
}

COMMAND:setfactionmember(playerid, params[]) {
    return 1;
}