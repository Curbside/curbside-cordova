#import "CurbsideCordovaPlugin.h"

#import <Cordova/CDVAvailability.h>

@import Curbside;

@interface CurbsideCordovaPlugin () <CSUserSessionDelegate, CLLocationManagerDelegate>
{
    NSString* _eventListenerCallbackId;
    NSMutableArray<CDVPluginResult*>* _pendingEventResults;
    NSMutableArray<NSString*>* _locationRequestCallbackId;
    CLLocationManager *_locationManager;
}

@end

@implementation CurbsideCordovaPlugin

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    _pendingEventResults = [[NSMutableArray alloc] init];
    _locationRequestCallbackId = [[NSMutableArray alloc] init];
}

- (void)finishLaunching:(NSNotification *)notification {
    [CSUserSession currentSession].delegate = self;
}

- (NSString*)userStatusEncode:(CSUserStatus)status {
    switch(status) {
        case CSUserStatusArrived:
            return @"arrived";
            break;
        case CSUserStatusInTransit:
            return @"inTransit";
            break;
        case CSUserStatusApproaching:
            return @"approaching";
            break;
        case CSUserStatusUserInitiatedArrived:
            return @"userInitiatedArrived";
            break;
        default:
            return @"unknown";
            break;
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

- (NSDictionary*)userInfoEncode:(CSUserInfo *)userInfo {
    NSMutableDictionary *encodedUserInfo = [[NSMutableDictionary alloc] init];
    [encodedUserInfo setValue:userInfo.fullName forKey:@"fullName"];
    [encodedUserInfo setValue:userInfo.emailAddress forKey:@"emailAddress"];
    [encodedUserInfo setValue:userInfo.smsNumber forKey:@"smsNumber"];
    return encodedUserInfo;
}

- (NSString*) sessionStateEncode:(CSSessionState)sessionState {
    switch(sessionState) {
        case CSSessionStateUsageTokenNotSet:
            return @"usageTokenNotSet";
            break;
        case CSSessionStateInvalidKeys:
            return @"invalidKeys";
            break;
        case CSSessionStateAuthenticated:
            return @"authenticated";
            break;
        case CSSessionStateValid:
            return @"valid";
            break;
        case CSSessionStateNetworkError:
            return @"networkError";
            break;
    }
    return @"\"unknown\"";
}

-(NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to a NSDate.
    NSDate *result = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
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

- (void)session:(CSSession *)session changedState:(CSSessionState)newState {
    [self sendSuccessEvent:@"changedState" withResult:[self sessionStateEncode:newState]];
}

- (void)eventListener:(CDVInvokedUrlCommand*)command {
    _eventListenerCallbackId = command.callbackId;
    for (CDVPluginResult* eventResult in _pendingEventResults) {
        [self.commandDelegate sendPluginResult:eventResult callbackId:_eventListenerCallbackId];
    }
    [_pendingEventResults removeAllObjects];
}

- (void)sendSuccessEvent:(NSString*) event withResult:(id) result {
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setValue:event forKey:@"event"];
    [message setValue:result forKey:@"result"];
    CDVPluginResult* eventResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    if (_eventListenerCallbackId == nil) {
        [_pendingEventResults addObject:eventResult];
    } else {
        [self.commandDelegate sendPluginResult:eventResult callbackId:_eventListenerCallbackId];
    }
}

- (void)sendErrorEvent:(NSString*) error {
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setValue:error forKey:@"result"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_eventListenerCallbackId];
}

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    NSString* trackingIdentifier = [command.arguments objectAtIndex:0];
    [CSUserSession currentSession].trackingIdentifier = trackingIdentifier;
    CSSessionState sessionState = [CSUserSession currentSession].sessionState;
    
    if (sessionState == CSSessionStateValid || sessionState == CSSessionStateAuthenticated) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self sessionStateEncode:sessionState]] callbackId:command.callbackId];
    } else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self sessionStateEncode:sessionState]] callbackId:command.callbackId];
    }
}

- (void)setUserInfo:(CDVInvokedUrlCommand*)command {
    NSDictionary* arguments = [command.arguments objectAtIndex:0];
    
    NSString* fullname = [arguments objectForKey:@"fullName"];
    NSString* emailAddress = [arguments objectForKey:@"emailAddress"];
    NSString* smsNumber = [arguments objectForKey:@"smsNumber"];
    
    CSUserInfo* userInfo = [[CSUserInfo alloc] init];
    userInfo.fullName = fullname;
    userInfo.emailAddress = emailAddress;
    userInfo.smsNumber = smsNumber;
    
    [CSUserSession currentSession].userInfo = userInfo;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    // NSString* from = [command.arguments objectAtIndex:2];
    // NSString* to = [command.arguments objectAtIndex:3];
    
    if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if (trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else if ([CSUserSession currentSession].trackingIdentifier == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackingIdentifier was null"];
    } else {
        // if (from == nil || to == nil){
            [[CSUserSession currentSession] startTripToSiteWithIdentifier:siteID trackToken:trackToken];
        // } else {
        //     NSDate *fromDate = [self dateForRFC3339DateTimeString:from];
        //     NSDate *toDate = [self dateForRFC3339DateTimeString:to];
        //     [[CSUserSession currentSession] startTripToSiteWithIdentifier:siteID trackToken:trackToken etaFromDate:fromDate toDate:toDate]
        // }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil) {
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
    
    if (siteID == nil) {
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

- (void)getTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[CSUserSession currentSession].trackingIdentifier];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getTrackedSites:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[self sitesEncode:[CSUserSession currentSession].trackedSites]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// - (void)getUserInfo:(CDVInvokedUrlCommand*)command {
//     CSUserInfo userInfo = [CSUserSession currentSession].userInfo;
//     CDVPluginResult* pluginResult;
//     if (userInfo != nil) {
//         pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self userInfoEncode:userInfo]];
//     } else {
//         pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
//     }
//     [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
// }

@end
