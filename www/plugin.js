var exec = require("cordova/exec");

var PLUGIN_NAME = "CurbsideCordovaPlugin";

var eventListeners = {
    canNotifyMonitoringSessionUserAtSite: [],
    userApproachingSite: [],
    userArrivedAtSite: [],
    encounteredError: [],
    updatedTrackedSites: [],
};

var Curbside = {
    _canNotifyMonitoringSessionUserAtSite: function(site) {
        Curbside.trigger("canNotifyMonitoringSessionUserAtSite", site);
    },
    _userApproachingSite: function(site) {
        Curbside.trigger("userApproachingSite", site);
    },
    _userArrivedAtSite: function(site) {
        Curbside.trigger("userArrivedAtSite", site);
    },
    _encounteredError: function(error) {
        Curbside.trigger("encounteredError", error);
    },
    _updatedTrackedSites: function(sites) {
        Curbside.trigger("updatedTrackedSites", sites);
    },

    setTrackingIdentifier: function(trackingIdentifier, cb) {
        exec(cb, null, PLUGIN_NAME, "setTrackingIdentifier", [trackingIdentifier]);
    },

    startTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        exec(cb, null, PLUGIN_NAME, "startTripToSiteWithIdentifier", [siteID, trackToken]);
    },

    completeTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        exec(cb, null, PLUGIN_NAME, "completeTripToSiteWithIdentifier", [siteID, trackToken]);
    },

    completeAllTrips: function(cb) {
        exec(cb, null, PLUGIN_NAME, "completeAllTrips");
    },

    cancelTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        exec(cb, null, PLUGIN_NAME, "cancelTripToSiteWithIdentifier", [siteID, trackToken]);
    },

    cancelAllTrips: function(cb) {
        exec(cb, null, PLUGIN_NAME, "cancelAllTrips");
    },

    on: function(event, listener) {
        if (!(event in eventListeners)) {
            throw event + " doesn't exist";
        }
        eventListeners[event].push(listener);
    },

    off: function(event, listener) {
        if (!(event in eventListeners)) {
            throw event + " doesn't exist";
        }
        eventListeners[event] = eventListeners[event].filter(function(list) {
            return list != listener;
        });
    },

    trigger: function(event) {
        if (!(event in eventListeners)) {
            throw event + " doesn't exist";
        }
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        eventListeners[event].forEach(function(listener) {
            listener.apply(null, args);
        });
    },
};

module.exports = Curbside;
