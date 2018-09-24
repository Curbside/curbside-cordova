#import "CurbsideCordovaPlugin.h"

#import <Cordova/CDVAvailability.h>

@import Curbside;

@interface CurbsideCordovaPlugin () <CSUserSessionDelegate, CSMonitoringSessionDelegate, CLLocationManagerDelegate>
{
    NSString* _eventListenerCallbackId;
    NSMutableArray<CDVPluginResult*>* _pendingEventResults;
    NSMutableArray<NSString*>* _locationRequestCallbackId;
    CLLocationManager *_locationManager;
}

@end

@implementation CurbsideCordovaPlugin

- (NSString*)getStringArg: (NSArray*)arguments at:(int)index{
    id obj = [arguments objectAtIndex:index];
    if(!obj || obj == [NSNull null]){
        return nil;
    }
    return obj;
}

- (NSArray<NSString *> *)getArrayArg: (NSArray*)arguments at:(int)index{
    id obj = [arguments objectAtIndex:index];
    if(!obj || obj == [NSNull null]){
        return nil;
    }
    return obj;
}

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    _pendingEventResults = [[NSMutableArray alloc] init];
    _locationRequestCallbackId = [[NSMutableArray alloc] init];
}

- (void)finishLaunching:(NSNotification *)notification {
    CSUserSession* userSession = [CSUserSession currentSession];
    if(userSession != nil){
        userSession.delegate = self;
    }
    CSMonitoringSession* monitorSession = [CSMonitoringSession currentSession];
    if(monitorSession != nil){
        monitorSession.delegate = self;
        monitorSession.statusesUpdatedHandler = ^(NSArray<CSUserStatusUpdate *> *userStatusUpdates) {
            [self sendSuccessEvent:@"userStatusUpdates" withResult:[self userStatusUpdatesEncode:userStatusUpdates]];
        };
    }
}

// utils

- (NSNumber*)dateEncode:(NSDate*)date {
    if(date == nil){
        return nil;
    }
    return [NSNumber numberWithDouble:[date timeIntervalSince1970]];
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
    [encodedTrip setValue:[self dateEncode:trip.startDate]forKey:@"startDate"];
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
    [encodedUserInfo setValue:userInfo.vehicleMake forKey:@"vehicleMake"];
    [encodedUserInfo setValue:userInfo.vehicleModel forKey:@"vehicleModel"];
    [encodedUserInfo setValue:userInfo.vehicleLicensePlate forKey:@"vehicleLicensePlate"];
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
        default:
            return @"unknown";
            break;
    }
}


- (NSString*) motionAcivityEncode:(CSMotionActivity)motionAcivity {
    switch(motionAcivity) {
        case CSMotionActivityInVehicle:      
            return @"inVehicle";
            break;
        case CSMotionActivityOnBicycle:
            return @"onBicycle";
            break;
        case CSMotionActivityOnFoot:
            return @"onFoot";
            break;
        case CSMotionActivityStill:
            return @"still";
            break;
        default:
            return @"unknown";
            break;
    }
}

- (NSDictionary*)locationEncode:(CLLocation *)location {
    NSMutableDictionary *encodedLocation = [[NSMutableDictionary alloc] init];
    [encodedLocation setValue:[NSNumber numberWithDouble:location.altitude] forKey:@"altitude"];
    [encodedLocation setValue:[NSNumber numberWithDouble:location.verticalAccuracy] forKey:@"verticalAccuracy"];
    if(location.floor != nil){
        [encodedLocation setValue:[NSNumber numberWithInteger:location.floor.level] forKey:@"floor"];
    }
    [encodedCoordinate setValue:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
    [encodedCoordinate setValue:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];
    [encodedLocation setValue:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"horizontalAccuracy"];
    [encodedLocation setValue:[NSNumber numberWithDouble:location.speed] forKey:@"speed"];
    [encodedLocation setValue:[NSNumber numberWithDouble:location.course] forKey:@"course"];
    [encodedLocation setValue:[self dateEncode:location.timestamp] forKey:@"timestamp"];
    return encodedLocation;
}

- (NSDictionary*)userStatusUpdateEncode:(CSUserStatusUpdate *)userStatusUpdate {
    NSMutableDictionary *encodedUserStatusUpdate = [[NSMutableDictionary alloc] init];
    [encodedUserStatusUpdate setValue:userStatusUpdate.trackingIdentifier forKey:@"trackingIdentifier"];
    [encodedUserStatusUpdate setValue:[self locationEncode:userStatusUpdate.location] forKey:@"location"];
    [encodedUserStatusUpdate setValue:[self dateEncode:userStatusUpdate.lastUpdateTimestamp] forKey:@"lastUpdateTimestamp"];
    [encodedUserStatusUpdate setValue:[self userStatusEncode:userStatusUpdate.userStatus] forKey:@"userStatus"];
    [encodedUserStatusUpdate setValue:[self userInfoEncode:userStatusUpdate.userInfo] forKey:@"userInfo"];
    [encodedUserStatusUpdate setValue:@(userStatusUpdate.acknowledgedUser) forKey:@"acknowledgedUser"];
    [encodedUserStatusUpdate setValue:[NSNumber numberWithInt: userStatusUpdate.estimatedTimeOfArrival] forKey:@"estimatedTimeOfArrival"];
    [encodedUserStatusUpdate setValue:[NSNumber numberWithInt: userStatusUpdate.distanceFromSite] forKey:@"distanceFromSite"];
    [encodedUserStatusUpdate setValue:[self motionAcivityEncode:userStatusUpdate.motionActivity] forKey:@"motionActivity"];
    [encodedUserStatusUpdate setValue:[self tripsEncode:userStatusUpdate.tripInfos] forKey:@"tripsInfo"];
    if(userStatusUpdate.monitoringSessionUserAcknowledgedTimestamp != nil){
        [encodedUserStatusUpdate setValue:[self dateEncode:userStatusUpdate.monitoringSessionUserAcknowledgedTimestamp]  forKey:@"monitoringSessionUserAcknowledgedTimestamp"];
    }
    if(userStatusUpdate.monitoringSessionUserTrackingIdentifier != nil){
        [encodedUserStatusUpdate setValue:userStatusUpdate.monitoringSessionUserTrackingIdentifier forKey:@"monitoringSessionUserTrackingIdentifier"];
    }
    return encodedUserStatusUpdate;
}

- (NSArray*)userStatusUpdatesEncode:(NSArray<CSUserStatusUpdate *> *)userStatusUpdates {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSEnumerator<CSUserStatusUpdate*> *enumerator = [userStatusUpdates objectEnumerator];
    CSUserStatusUpdate *userStatusUpdate;
    while (userStatusUpdate = [enumerator nextObject])
    {
        [result addObject:[self userStatusUpdateEncode:userStatusUpdate]];
    }
    return result;
}

-(NSDate*)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    if(rfc3339DateTimeString == nil){
        return nil;
    }
    
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to a NSDate.
    NSDate *result = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
    return result;
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

// Session
- (void)session:(CSSession *)session changedState:(CSSessionState)newState {
    [self sendSuccessEvent:@"changedState" withResult:[self sessionStateEncode:newState]];
}

- (CSSession*)getSession {
    CSUserSession* userSession = [CSUserSession currentSession];
    if(userSession != nil){
        return userSession;
    }
    CSMonitoringSession* monitoringSession = [CSMonitoringSession currentSession];
    return monitoringSession;
}

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    NSString* trackingIdentifier = [self getStringArg:command.arguments at:0];
    
    CSSession* session = [self getSession];
    if(session == nil){
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSSession must be initialized"] callbackId:command.callbackId];
    } else {
        session.trackingIdentifier = trackingIdentifier;
        CSSessionState sessionState = session.sessionState;
        
        if (sessionState == CSSessionStateValid || sessionState == CSSessionStateAuthenticated) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self sessionStateEncode:sessionState]] callbackId:command.callbackId];
        } else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self sessionStateEncode:sessionState]] callbackId:command.callbackId];
        }
    }
}

- (void)getTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    CSSession* session = [self getSession];
    if(session == nil){
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSSession must be initialized"] callbackId:command.callbackId];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:session.trackingIdentifier];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


- (void)setUserInfo:(CDVInvokedUrlCommand*)command {
    NSDictionary* arguments = [command.arguments objectAtIndex:0];
    
    NSString* fullname = [arguments objectForKey:@"fullName"];
    NSString* emailAddress = [arguments objectForKey:@"emailAddress"];
    NSString* smsNumber = [arguments objectForKey:@"smsNumber"];
    NSString* vehicleMake = [arguments objectForKey:@"vehicleMake"];
    NSString* vehicleModel = [arguments objectForKey:@"vehicleModel"];
    NSString* vehicleLicensePlate = [arguments objectForKey:@"vehicleLicensePlate"];
    
    CSUserInfo* userInfo = [[CSUserInfo alloc] init];
    userInfo.fullName = fullname;
    userInfo.emailAddress = emailAddress;
    userInfo.smsNumber = smsNumber;
    userInfo.vehicleMake = vehicleMake;
    userInfo.vehicleModel = vehicleModel;
    userInfo.vehicleLicensePlate = vehicleLicensePlate;
    
    CDVPluginResult* pluginResult;
    CSSession* session = [self getSession];
    
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSSession must be initialized"];
    } else {
        session.userInfo = userInfo;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getUserInfo:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    CSSession* session = [self getSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSSession must be initialized"];
    } else {
        CSUserInfo* userInfo = session.userInfo;
        if (userInfo != nil) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self userInfoEncode:userInfo]];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


// User Session

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


- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* siteID = [self getStringArg:command.arguments at:0];
    NSString* trackToken = [self getStringArg:command.arguments at:1];
    
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if (trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else if (session.trackingIdentifier == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackingIdentifier was null"];
    } else {
        [session startTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)startTripToSiteWithIdentifierAndEta:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* siteID = [self getStringArg:command.arguments at:0];
    NSString* trackToken = [self getStringArg:command.arguments at:1];
    NSString* from = [self getStringArg:command.arguments at:2];
    NSString* to = [self getStringArg:command.arguments at:3];
    
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if (trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else if (from == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"from was null"];
    } else if (session.trackingIdentifier == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackingIdentifier was null"];
    } else {
        NSDate *fromDate = [self dateForRFC3339DateTimeString:from];
        NSDate *toDate = [self dateForRFC3339DateTimeString:to];
        [session startTripToSiteWithIdentifier:siteID trackToken:trackToken etaFromDate:fromDate toDate:toDate];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* siteID = [self getStringArg:command.arguments at:0];
    NSString* trackToken = [self getStringArg:command.arguments at:1];
    
    
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else {
        [session completeTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeAllTrips:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else {
        [session completeAllTrips];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)cancelTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* siteID = [self getStringArg:command.arguments at:0];
    NSString* trackToken = [self getStringArg:command.arguments at:1];
    
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else {
        [session cancelTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)cancelAllTrips:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else {
        [session cancelAllTrips];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getTrackedSites:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    CSUserSession* session = [CSUserSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSUserSession must be initialized"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[self sitesEncode:session.trackedSites]];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Monitoring Sesion

- (void)session:(nonnull CSMonitoringSession *)session encounteredError:(nonnull NSError *)error {
    [self sendErrorEvent:error.description];
}

- (void) startMonitoringArrivalsToSiteWithIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* siteID = [self getStringArg:command.arguments at:0];
    
    CSMonitoringSession* session = [CSMonitoringSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSMonitoringSession must be initialized"];
    } else if (siteID == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else {
        [session startMonitoringArrivalsToSiteWithIdentifier:siteID];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopMonitoringArrivals:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    
    CSMonitoringSession* session = [CSMonitoringSession currentSession];
    if(session == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSMonitoringSession must be initialized"];
    } else {
        [session stopMonitoringArrivals];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeTripForTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* trackingIdentifier = [self getStringArg:command.arguments at:0];
    NSArray<NSString *>* trackTokens = [self getArrayArg:command.arguments at:1];
    
    CSMonitoringSession* session = [CSMonitoringSession currentSession];
    if(session == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSMonitoringSession must be initialized"];
    } else if(trackingIdentifier == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackingIdentifier was null"];
    } else {
        [session completeTripForTrackingIdentifier:trackingIdentifier trackTokens:trackTokens];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)cancelTripForTrackingIdentifier:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    NSString* trackingIdentifier = [self getStringArg:command.arguments at:0];
    NSArray<NSString *>* trackTokens = [self getArrayArg:command.arguments at:1];
    
    CSMonitoringSession* session = [CSMonitoringSession currentSession];
    if(session == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CSMonitoringSession must be initialized"];
    } else if(trackingIdentifier == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackingIdentifier was null"];
    } else {
        [session cancelTripForTrackingIdentifier:trackingIdentifier trackTokens:trackTokens];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end
