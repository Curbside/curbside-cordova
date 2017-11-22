#import <Cordova/CDVPlugin.h>

@import Curbside;

@interface CurbsideCordovaPlugin : CDVPlugin {
}

@property (nonatomic, strong) CLLocationManager *locationManager;

- (void)eventListener:(CDVInvokedUrlCommand*)command;

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command;

- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)completeAllTrips:(CDVInvokedUrlCommand*)command;

- (void)cancelTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command;

- (void)cancelAllTrips:(CDVInvokedUrlCommand*)command;

@end
