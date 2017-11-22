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

- (NSString*)jsonEncode:(id)data {
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)session:(CSUserSession *)session canNotifyMonitoringSessionUserAtSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"window.Curbside.canNotifyMonitoringSessionUserAtSite(%@);",[self jsonEncode:site]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session userApproachingSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"window.Curbside.userApproachingSite(%@);",[self jsonEncode:site]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session userArrivedAtSite:(CSSite *)site {
    NSString *code = [NSString stringWithFormat:@"window.Curbside.userArrivedAtSite(%@);",[self jsonEncode:site]];
    [self.commandDelegate evalJs:code];
    
}

- (void)session:(CSUserSession *)session encounteredError:(NSError *)error forOperation:(CSUserSessionAction)customerSessionAction {
    NSString *code = [NSString stringWithFormat:@"window.Curbside.encounteredError(%@);",[self jsonEncode:error.description]];
    [self.commandDelegate evalJs:code];
}

- (void)session:(CSUserSession *)session updatedTrackedSites:(NSSet<CSSite *> *)trackedSites {
    NSString *code = [NSString stringWithFormat:@"window.Curbside && window.Curbside.updatedTrackedSites(%@);",[self jsonEncode:trackedSites]];
    [self.commandDelegate evalJs:code];
}

- (void)setTrackingIdentifier:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* trackingIdentifier = [command.arguments objectAtIndex:0];
    
    if (trackingIdentifier != nil) {
        [CSUserSession currentSession].trackingIdentifier = trackingIdentifier;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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
