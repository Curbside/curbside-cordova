#import "CurbsideCordovaPlugin.h"

#import <Cordova/CDVAvailability.h>

@import Curbside;

@implementation CurbsideCordovaPlugin

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)finishLaunching:(NSNotification *)notification
{
    self.locationManager = [[CLLocationManager alloc] init];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];

    NSString *usageToken = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Curbside Usage Token"];

    CSUserSession *sdksession = [CSUserSession createSessionWithUsageToken:usageToken delegate:self];
    NSDictionary *launchOptions = notification.userInfo[UIApplicationLaunchOptionsLocationKey];
    [sdksession application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];
}

- (NSString*)stringEncode:(NSString *)value {
    return [NSString stringWithFormat:@"\"%@\"", [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
}

- (NSString*)dateEncode:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
    return [self stringEncode:[formatter stringFromDate:date]];
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

- (NSString*)tripEncode:(CSTripInfo *)trip {
    return [NSString stringWithFormat:@"{trackToken: %@, startDate:%@, destID: %@}", [self stringEncode:trip.trackToken], [self dateEncode:trip.startDate], [self stringEncode:trip.destID]];
}

- (NSString*)tripsEncode:(NSArray<CSTripInfo *> *)trips {
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    for(int i=0; i< trips.count; i++){
        [stringArray addObject:[self tripEncode:[trips objectAtIndex:i]]];
    }
    return [NSString stringWithFormat:@"[%@]", [stringArray componentsJoinedByString:@","]];
}

- (NSString*)siteEncode:(CSSite *)site {
    return [NSString stringWithFormat:@"{siteIdentifier: %@, distanceFromSite:%d, userStatus: %@, trips: %@}", [self stringEncode:site.siteIdentifier], site.distanceFromSite, [self userStatusEncode:site.userStatus], [self tripsEncode:site.tripInfos]];
}

- (NSString*)sitesEncode:(NSSet<CSSite *> *)sites {
    NSArray *allSites = [sites allObjects];
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    for(int i=0; i< allSites.count; i++){
        [stringArray addObject:[self siteEncode:[allSites objectAtIndex:i]]];
    }
    return [NSString stringWithFormat:@"[%@]", [stringArray componentsJoinedByString:@","]];
}

- (void)session:(CSUserSession *)session canNotifyMonitoringSessionUserAtSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"Curbside && Curbside._canNotifyMonitoringSessionUserAtSite(%@);",[self siteEncode:site]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session userApproachingSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"Curbside && Curbside._userApproachingSite(%@);",[self siteEncode:site]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session userArrivedAtSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"Curbside && Curbside._userArrivedAtSite(%@);",[self siteEncode:site]];
    [self.commandDelegate evalJs:code];
    
}

- (void)session:(CSUserSession *)session encounteredError:(NSError *)error forOperation:(CSUserSessionAction)customerSessionAction {
    NSString *code = [NSString stringWithFormat:@"Curbside && Curbside._encounteredError(%@);", [self stringEncode:error.description]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session updatedTrackedSites:(NSSet<CSSite *> *)trackedSites {
    NSString *code = [NSString stringWithFormat:@"Curbside && Curbside._updatedTrackedSites(%@);",[self sitesEncode:trackedSites]];
    [self.commandDelegate evalJs:code];
}

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command
{
    NSString* trackingIdentifier = [command.arguments objectAtIndex:0];
    [CSUserSession currentSession].trackingIdentifier = trackingIdentifier;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)startTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command
{
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

- (void)completeTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if(trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else {
        [[CSUserSession currentSession] completeTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)completeAllTrips:(CDVInvokedUrlCommand*)command
{
    [[CSUserSession currentSession] completeAllTrips];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)cancelTripToSiteWithIdentifier:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* siteID = [command.arguments objectAtIndex:0];
    NSString* trackToken = [command.arguments objectAtIndex:1];
    
    if (siteID == nil){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"siteID was null"];
    } else if(trackToken == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"trackToken was null"];
    } else {
        [[CSUserSession currentSession] cancelTripToSiteWithIdentifier:siteID trackToken:trackToken];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)cancelAllTrips:(CDVInvokedUrlCommand*)command
{
    [[CSUserSession currentSession] cancelAllTrips];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

@end
