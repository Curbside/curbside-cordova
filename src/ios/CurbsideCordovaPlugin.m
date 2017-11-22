#import "CurbsideCordovaPlugin.h"

#import <Cordova/CDVAvailability.h>

@import Curbside;

@implementation CurbsideCordovaPlugin

NSString* eventListenerCallbackId;

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)finishLaunching:(NSNotification *)notification {
    self.locationManager = [[CLLocationManager alloc] init];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];

    NSString *usageToken = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Curbside Usage Token"];

    CSUserSession *sdksession = [CSUserSession createSessionWithUsageToken:usageToken delegate:self];
    NSDictionary *launchOptions = notification.userInfo[UIApplicationLaunchOptionsLocationKey];
    [sdksession application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];
}

- (NSString*)userStatusEncode:(CSUserStatus)status {
    switch(status) {
        case CSUserStatusArrived:
        return @"\"arrived\"";
        break;
        case CSUserStatusInTransit:
        return @"\"inTransit\"";
        break;
        case CSUserStatusApproaching:
        return @"\"approaching\"";
        break;
        case CSUserStatusUserInitiatedArrived:
        return @"\"userInitiatedArrived\"";
        break;
        default:
        return @"\"unknown\"";
    }
}

- (NSDictionary*)tripEncode:(CSTripInfo *)trip {
    NSMutableDictionary *encodedTrip = [[NSMutableDictionary alloc] init];
    [encodedTrip setValue:trip.trackToken forKey:@"trackToken"];
    [encodedTrip setValue:trip.startDate forKey:@"startDate"];
    [encodedTrip setValue:trip.destID forKey:@"destID"];
    return encodedTrip;
}

- (NSArray*)tripsEncode:(NSArray<CSTripInfo *> *)trips {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSEnumerator<CSTripInfo*> *enumerator = [trips objectEnumerator];
    CSTripInfo *trip;
    while (trip = [enumerator nextObject])
    {
        [result addObject:[self tripEncode:trip]];
    }
    return result;
}

- (NSDictionary*)siteEncode:(CSSite *)site {
    NSMutableDictionary *encodedSite = [[NSMutableDictionary alloc] init];
    [encodedSite setValue:site.siteIdentifier forKey:@"siteIdentifier"];
    [encodedSite setValue:[NSNumber numberWithInt:site.distanceFromSite] forKey:@"distanceFromSite"];
    [encodedSite setValue:[self userStatusEncode:site.userStatus] forKey:@"userStatus"];
    [encodedSite setValue:[self tripsEncode:site.tripInfos] forKey:@"trips"];
    return encodedSite;
}

- (NSArray*)sitesEncode:(NSSet<CSSite *> *)sites {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSEnumerator<CSSite*> *enumerator = [sites objectEnumerator];
    CSSite *site;
    while (site = [enumerator nextObject])
    {
        [result addObject:[self siteEncode:site]];
    }
    return result;
}

- (void)session:(CSUserSession *)session canNotifyMonitoringSessionUserAtSite:(CSSite *)site {
    [self sendSuccessEvent:@"canNotifyMonitoringSessionUserAtSite" withResult:[self siteEncode:site]];
}

- (void)session:(CSUserSession *)session userApproachingSite:(CSSite *)site {
    [self sendSuccessEvent:@"userApproachingSite" withResult:[self siteEncode:site]];
}

- (void)session:(CSUserSession *)session userArrivedAtSite:(CSSite *)site {
    [self sendSuccessEvent:@"userArrivedAtSite" withResult:[self siteEncode:site]];
}

- (void)session:(CSUserSession *)session encounteredError:(NSError *)error forOperation:(CSUserSessionAction)customerSessionAction {
    [self sendErrorEvent:error.description];
}

- (void)session:(CSUserSession *)session updatedTrackedSites:(NSSet<CSSite *> *)trackedSites {
    [self sendSuccessEvent:@"updatedTrackedSites" withResult:[self sitesEncode:trackedSites]];
}

- (void)eventListener:(CDVInvokedUrlCommand*)command {
    eventListenerCallbackId = command.callbackId;
}

- (void)sendSuccessEvent:(NSString*) event withResult:(id) result {
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setValue:event forKey:@"event"];
    [message setValue:result forKey:@"result"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:eventListenerCallbackId];
}

- (void)sendErrorEvent:(NSString*) error {
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setValue:error forKey:@"result"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:eventListenerCallbackId];
}


- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    NSString* trackingIdentifier = [command.arguments objectAtIndex:0];
    [CSUserSession currentSession].trackingIdentifier = trackingIdentifier;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if(trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else {
        [[CSUserSession currentSession] startTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else {
        [[CSUserSession currentSession] completeTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeAllTrips:(CDVInvokedUrlCommand*)command {
    [[CSUserSession currentSession] completeAllTrips];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)cancelTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else {
        [[CSUserSession currentSession] cancelTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)cancelAllTrips:(CDVInvokedUrlCommand*)command {
    [[CSUserSession currentSession] cancelAllTrips];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

@end
