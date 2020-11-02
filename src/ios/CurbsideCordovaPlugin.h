#import <Cordova/CDVPlugin.h>

@import Curbside;

@interface CurbsideCordovaPlugin : CDVPlugin {
}

@property (nonatomic, strong) CLLocationManager *locationManager;

- (void)eventListener:(CDVInvokedUrlCommand*)command;

// session

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command;

- (void)getTrackingIdentifier:(CDVInvokedUrlCommand*)command;

// user session

- (void)setUserInfo:(CDVInvokedUrlCommand*)command;

- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)startTripToSiteWithIdentifierAndEta:(CDVInvokedUrlCommand*)command;

- (void)startUserOnTheirWayTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)updateAllTripsWithUserOnTheirWay:(CDVInvokedUrlCommand*)command;

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)completeAllTrips:(CDVInvokedUrlCommand*)command;

- (void)cancelTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)cancelAllTrips:(CDVInvokedUrlCommand*)command;

- (void)getTrackedSites:(CDVInvokedUrlCommand*)command;

- (void)getEtaToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)notifyMonitoringSessionUserOfArrivalAtSite:(CDVInvokedUrlCommand*)command;


// monitoring session

- (void)completeTripForTrackingIdentifier:(CDVInvokedUrlCommand*)command;

- (void)cancelTripForTrackingIdentifier:(CDVInvokedUrlCommand*)command;

- (void)startMonitoringArrivalsToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)stopMonitoringArrivals:(CDVInvokedUrlCommand*)command;

@end
