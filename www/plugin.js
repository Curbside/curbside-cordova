var exec = require("cordova/exec");

var PLUGIN_NAME = "CurbsideCordovaPlugin";

var eventListeners = {
    canNotifyMonitoringSessionUserAtSite: [],
    userApproachingSite: [],
    userArrivedAtSite: [],
    encounteredError: [],
    updatedTrackedSites: [],
};

function execCb(name, cb) {
    var args = [];
    for (var i = 2; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    exec(
        function(params) {
            cb && cb(null, params);
        },
        function(error) {
            cb && cb(error);
        },
        PLUGIN_NAME,
        name,
        args,
    );
}

var Curbside = {
    setTrackingIdentifier: function(trackingIdentifier, cb) {
        execCb("setTrackingIdentifier", cb, trackingIdentifier);
    },

    startTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        exec("startTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    completeTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        execCb("completeTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    completeAllTrips: function(cb) {
        execCb("completeAllTrips", cb);
    },

    cancelTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        execCb("cancelTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    cancelAllTrips: function(cb) {
        execCb("cancelAllTrips", cb);
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
};

function trigger(event) {
    if (!(event in eventListeners)) {
        throw event + " doesn't exist";
    }
    var args = [];
    for (var i = 1; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    eventListeners[event].forEach(function(listener) {
        listener.apply(null, args);
    });
}

exec(
    function(args) {
        trigger(args.event, args.result);
    },
    function() {
        trigger("encounteredError", args.result);
    },
    PLUGIN_NAME,
    "eventListener",
);

module.exports = Curbside;
