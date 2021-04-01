#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <strlib>

#define FILTERSCRIPT

static rdtRankNames[7][15];
static spRankNames[7][15]; 


// --------------------- COMMANDS --------------------- 

COMMAND:setfactionleader(playerid, params[]) {
    return 1;
}

COMMAND:setfactionmember(playerid, params[]) {
    return 1;
}

COMMAND:invitemember(playerid, params[]) {
    return 1;
}

COMMAND:resignmember(playerid, params[]) {
    return 1;
}

COMMAND:rankup(playerid, params[]) {
    return 1;
}

COMMAND:rankdown(playerid, params[]) {
    return 1;
}