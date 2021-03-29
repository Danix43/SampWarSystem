#include <a_samp>
#include <izcmd>
#include <strlib>

#define FILTERSCRIPT

new spvehicles[10];
new rdtvehicles[10];

main() {
    print("Filterscript loaded in main");
}

public OnFilterScriptInit() {
    print("Mafia HQs and Vehicles filterscript loaded");
    addVehiclesRDT();
    addVehiclesSP();
}

// color 149
addVehiclesSP() {
    spvehicles[0] = AddStaticVehicle(522, 1414.0022, 746.0696, 10.3935, 268.8127, 211, 255); // nrgsp
    spvehicles[1] = AddStaticVehicle(522, 1413.1940, 759.2654, 10.3908, 275.5480, 211, 255); // nrgsp
    spvehicles[2] = AddStaticVehicle(522, 1413.4996, 752.7795, 10.3900, 271.2432, 211, 255); // nrgsp
    spvehicles[3] = AddStaticVehicle(522, 1412.1112, 755.6467, 10.3892, 270.0812, 211, 255); // nrgsp
    spvehicles[4] = AddStaticVehicle(411, 1445.7037, 762.5338, 10.5474, 89.8119, 211, 255); // infsp
    spvehicles[5] = AddStaticVehicle(409, 1446.6243, 751.2015, 10.6203, 359.1673, 211, 255); // limosp
    spvehicles[6] = AddStaticVehicle(411, 1445.6853, 743.2895, 10.5474, 90.9583, 211, 255); // infsp
    spvehicles[7] = AddStaticVehicle(579, 1413.0048, 752.7371, 10.6317, 269.8256, 211, 255); // huntleysp
}

// color 161
addVehiclesRDT() {
    rdtvehicles[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, 161, 255); // limordt
    rdtvehicles[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, 161, 255); // infrdt
    rdtvehicles[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, 161, 255); // infrdt
    rdtvehicles[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, 161, 255); // nrgrdt
    rdtvehicles[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, 161, 255); // nrgrdt
    rdtvehicles[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, 161, 255); // nrgrdt
    rdtvehicles[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, 161, 255); // nrgrdt
    rdtvehicles[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, 161, 255); // huntleyrdt
}

public OnFilterScriptExit() {
    print("Mafia HQs and Vehicles filterscript unloaded");
}


// -------------------- COMMANDS --------------------  

COMMAND:fvr(playerid, params[]) {
    if (isequal(params[0], "rdt")) {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(rdtvehicles[i]);
        }
    } else if (isequal(params[0], "sp")) {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(spvehicles[i]);
        }
    } else {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(spvehicles[i]);
        }
        new j;
        for (j = 0; j <= 10; j++) {
            SetVehicleToRespawn(rdtvehicles[j]);
        }
    }
    return 1;
}