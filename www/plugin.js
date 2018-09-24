var exec = require("cordova/exec");

var PLUGIN_NAME = "CurbsideCordovaPlugin";

var eventListeners = {
    userStatusUpdates: [],
    canNotifyMonitoringSessionUserAtSite: [],
    userApproachingSite: [],
    userArrivedAtSite: [],
    encounteredError: [],
    updatedTrackedSites: [],
    changedState: [],
};

function execCb(name, cb) {
    var args = [];
    for (var i = 2; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    return new Promise(function(resolve, reject) {
        exec(
            function(params) {
                cb && cb(null, params);
                resolve(params);
            },
            function(error) {
                cb && cb(error);
                reject(error);
            },
            PLUGIN_NAME,
            name,
            args
        );
    });
}

var Curbside = {
    setTrackingIdentifier: function(trackingIdentifier, cb) {
        return execCb("setTrackingIdentifier", cb, trackingIdentifier);
    },

    setUserInfo: function(userInfo, cb) {
        return execCb("setUserInfo", cb, userInfo);
    },

    getUserInfo: function(cb) {
        return execCb("getUserInfo", cb);
    },

    startTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        return execCb("startTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    startTripToSiteWithIdentifierAndEta: function(siteID, trackToken, fromDate, toDate, cb) {
        return execCb("startTripToSiteWithIdentifierAndEta", cb, siteID, trackToken, fromDate, toDate);
    },

    completeTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        return execCb("completeTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    completeAllTrips: function(cb) {
        return execCb("completeAllTrips", cb);
    },

    cancelTripToSiteWithIdentifier: function(siteID, trackToken, cb) {
        return execCb("cancelTripToSiteWithIdentifier", cb, siteID, trackToken);
    },

    cancelAllTrips: function(cb) {
        return execCb("cancelAllTrips", cb);
    },

    getTrackingIdentifier: function(cb) {
        return execCb("getTrackingIdentifier", cb);
    },

    getTrackedSites: function(cb) {
        return execCb("getTrackedSites", cb);
    },

    completeTripForTrackingIdentifier: function(trackingIdentifier, trackTokens, cb) {
        return execCb("completeTripForTrackingIdentifier", cb, trackingIdentifier, trackTokens);
    },

    cancelTripForTrackingIdentifier: function(trackingIdentifier, trackTokens, cb) {
        return execCb("cancelTripForTrackingIdentifier", cb, trackingIdentifier, trackTokens);
    },

    startMonitoringArrivalsToSiteWithIdentifier: function(siteID, cb) {
        return execCb("startMonitoringArrivalsToSiteWithIdentifier", cb, siteID);
    },

    on: function(event, listener) {
        initEventListener();
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

var eventListenerStarted = false;

function initEventListener() {
    if (!eventListenerStarted) {
        exec(
            function(args) {
                trigger(args.event, args.result);
            },
            function(args) {
                trigger("encounteredError", args.result);
            },
            PLUGIN_NAME,
            "eventListener"
        );
        eventListenerStarted = true;
    }
}

module.exports = Curbside;
