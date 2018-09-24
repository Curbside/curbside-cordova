# Curbside Cordova plugin for iOS and Android (version 3.2.1)

This plugin is a wrapper for [Curbside SDK](https://developer.curbside.com/docs/).

---

## Quick install

_Stable version(npm)_

```bash
cordova plugin add curbside-cordova
```

_Develop version_

```bash
cordova plugin add https://github.com/Curbside/curbside-cordova.git
```

### iOS

In `platforms/ios/YOUR_PROJECT/Classes/AppDelegate.m`

-   Add on top

```objc
@import Curbside;
```

#### User Session

-   At the end of `-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` add this:

```objc
  CSUserSession *sdksession = [CSUserSession createSessionWithUsageToken:@"USAGE_TOKEN" delegate:nil];
  [sdksession application:application didFinishLaunchingWithOptions:launchOptions];
```

#### Monitoring Session

If your app does not already request location, In `platforms/ios/YOUR_PROJECT/Classes/AppDelegate.m` in `-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` add this:

```objc
    CSMonitoringSession *sdksession = [CSMonitoringSession createSessionWithAPIKey:@"APIKey" secret:@"secret" delegate:nil];
    [sdksession application:application didFinishLaunchingWithOptions:launchOptions];
```

Enable Background Modes

1. From the Project Navigator, select your project.
2. Select your target.
3. Select Capabilities.
4. Scroll down to Background Modes.
5. Check Location updates and Background fetch.

![Image of background modes](./backgroundModes.png)

Otherwise you will get

```
*** Assertion failure in -[CLLocationManager setAllowsBackgroundLocationUpdates:]
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: !stayUp || CLClientIsBackgroundable(internal->fClient)'
```

#### Fixing the Podfile iOS version

> We're currently awaiting for one of our fixes to be merged in the Cordova core. Until this is available, this step is needed.

If you are experiencing this error:

```
Installing "curbside-cordova" for ios
Failed to install 'curbside-cordova': Error: pod: Command failed with exit code 1
    at ChildProcess.whenDone (/path/to/your/project/platforms/ios/cordova/node_modules/cordova-common/src/superspawn.js:169:23)
    at emitTwo (events.js:125:13)
    at ChildProcess.emit (events.js:213:7)
    at maybeClose (internal/child_process.js:887:16)
    at Process.ChildProcess._handle.onexit (internal/child_process.js:208:5)
Error: pod: Command failed with exit code 1
```

In your project, edit the file `platforms/ios/Podfile`. Replace `platform :ios, '8.0'` by `platform :ios,'9.0'` Then in
a terminal go to `platforms/ios` and execute

```bash
pod install
```

### Android

Add the Curbside SDK maven url

In your project, edit the file `platforms/android/build.gradle`.

Replace

```java
allprojects {
    repositories {
        jcenter()
        maven {
            url "https://maven.google.com"
        }
    }
}
```

by:

```java
allprojects {
    repositories {
        jcenter()
        maven {
            url "https://maven.google.com"
        }
        maven {url "https://raw.github.com/Curbside/curbside-android-sdk-release/master"}
    }
}
```

Otherwise, you will experience the following error:

```
* What went wrong: A problem occurred configuring root project 'android'.
  > Could not resolve all dependencies for configuration ':_debugApkCopy'. Could not find any matches for
  > com.curbside:sdk:3.0+ as no versions of com.curbside:sdk are available.
       Required by:
           project :
```

#### Add Firebase in your app

1. Go to <a href="https://console.firebase.google.com/u/0/">Firebase Console</a> and click **Add project**.

![Image of Firebase Console](./Firebase_Console.png)

2. Following pop up window will open. Click on the drop down marker in front of Project Name. Select the project from the list of existing Google Projects and then click “Add Firebase”.

![Image of Add Project](./Add_Project.png)

3. Click **Add Firebase to your Android app** and follow the setup steps.
4. When prompted, enter your app's package name. Package name can only be set when you add an app to your Firebase project.
5. At the end, you'll download a google-services.json file. You can download this file again at any time.
6. Copy google-services.json file into your project's module folder, typically app.

#### Add the Firebase SDK in your app

1. First, add rules to your root-level `/platforms/android/build.gradle` file, to include the google-services plugin and the Google's Maven repository:

```java
buildscript {
    // ...
    dependencies {
        // ...
        classpath 'com.google.gms:google-services:3.0.0' // google-services plugin
    }
}

allprojects {
    // ...
    repositories {
        // ...
        maven {
            url "https://maven.google.com" // Google's Maven repository
        }
    }
}
```

2. Then, in your module Gradle file `/platforms/android/app/build.gradle`, add at the bottom of the file to enable the Gradle plugin:

```java
apply plugin: 'com.google.gms.google-services'
```

3. **Make sure** that all the google dependencies are of the same version. Otherwise, app may throw errors/exceptions when running/syncing the project.

#### Setup your MainActivity

In `platforms/android/src/main/java/com/YOUR_PROJECT/MainActivity.java` add your usage token and permission notification:

```java
    private static String USAGE_TOKEN = "USAGE_TOKEN";
    private static final int PERMISSION_REQUEST_CODE = 1;

    @Override
    public void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        CSUserSession.init(this, new TokenCurbsideCredentialProvider(USAGE_TOKEN));

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            String[] permissions = new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION};
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE);
        }
        ...
```

or if you whant to have the monitoring session

```java
    private static String API_KEY = "API_KEY";
    private static String SECRET = "SECRET";
    private static final int PERMISSION_REQUEST_CODE = 1;

    @Override
    public void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        CSMonitoringSession.init(this, new BasicAuthCurbsideCredentialProvider(API_KEY, SECRET));

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            String[] permissions = new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION};
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE);
        }
        ...
```

## Configuration

You can also configure the following variables to customize the iOS location plist entries

-   `LOCATION_WHEN_IN_USE_DESCRIPTION` for `NSLocationWhenInUseUsageDescription` (defaults to "To get accurate GPS
    locations")
-   `LOCATION_ALWAYS_USAGE_DESCRIPTION` for `NSLocationAlwaysUsageDescription` (defaults to "To get accurate GPS
    locations")

Example using the Cordova CLI

```bash
cordova plugin add curbside-cordova \
    --variable LOCATION_WHEN_IN_USE_DESCRIPTION="My custom when in use message" \
    --variable LOCATION_ALWAYS_USAGE_DESCRIPTION="My custom always usage message"
```

Example using config.xml

```xml
<plugin name="curbside-cordova" spec="3.0.0">
    <variable name="LOCATION_WHEN_IN_USE_DESCRIPTION" value="My custom when in use message" />
    <variable name="LOCATION_ALWAYS_USAGE_DESCRIPTION" value="My custom always usage message" />
</plugin>
```

## Quick Start

### For User Session

```html
<script type="text/javascript">
document.addEventListener("deviceready", function() {
  /**
   * Will be triggered when the user is near a site where the associate can be notified of the user arrival.
   **/
  Curbside.on("canNotifyMonitoringSessionUserAtSite", function(site){
    // Do something
  });

  /**
   * Will be triggered when the user is approaching a site which is currently tracked for a trip.
   **/
  Curbside.on("userApproachingSite", function(site){
    // Do something
  });

  /**
   * Will be triggered when the user has arrived at a site which is currently tracked for a trip.
   **/
  Curbside.on("userArrivedAtSite", function(site){
    // Do something
  });

  /**
   * Will be triggered when an error is encountered.
   **/
  Curbside.on("encounteredError", function(error){
    // Do something
  });

  /**
   * Will be triggered when trackedSites are updated.
   **/
  Curbside.on("updatedTrackedSites", function(sites){
    // Do something
  });

  /**
   * Set the "USER_UNIQUE_TRACKING_ID" of the user currently logged in your app. This may be nil when the app is
   * started, but as the user logs into the app, make sure this value is set. trackingIdentifier needs to be set to use
   * session specific methods for starting trips or monitoring sites. This identifier will be persisted across
   * application restarts.
   *
   * When the user logs out, set this to nil, which will in turn end the user session or monitoring session.
   * Note: The maximum length of the trackingIdentifier is 36 characters.
   **/
  Curbside.setTrackingIdentifier("USER_UNIQUE_TRACKING_ID", function(error){

  });

  /**
   * Start a trip tracking the user pickup of "UNIQUE_TRACK_TOKEN" to the site identified by the "SITE_ID". Call this
   * method when the application thinks its appropriate to start tracking the user eg. Order is ready to be picked up at
   * the site. This information is persisted across relaunch.
   *
   * If an error occurs because of an invalid session state, permissions or authentication with the ARRIVE server,
   * the callback will be informed with the reason as to why startTripToSiteWithIdentifier failed.
   **/
  Curbside.startTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN", function(error){

  });

  /**
   * Start a trip tracking the user pickup of "UNIQUE_TRACK_TOKEN" to the site identified by the "SITE_ID". Call this
   * method when the application thinks its appropriate to start tracking the user eg. Order is ready to be picked up at
   * the site. This information is persisted across relaunch. toDate can be null.
   *
   * If an error occurs because of an invalid session state, permissions or authentication with the ARRIVE server,
   * the callback will be informed with the reason as to why startTripToSiteWithIdentifier failed.
   **/
  Curbside.startTripToSiteWithIdentifierAndEta("SITE_ID", "UNIQUE_TRACK_TOKEN", fromDate, toDate, function(error){

  });


  /**
   * Completes the trip for the user to the site identified by the "SITE_ID" with the given "UNIQUE_TRACK_TOKEN".
   * If no trackToken is specified, then *all* trips to this site  will be completed.
   *
   * Note: Do not call this when the user logs out, instead set the "USER_UNIQUE_TRACKING_ID" to nil when the user logs out.
   **/
  Curbside.completeTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN", function(error){

  });

  /**
   * This method would complete all trips for this user across all devices.
   *
   * Note: Do not call this when the user logs out, instead set the "USER_UNIQUE_TRACKING_ID" to nil when the user logs
   * out.
   **/
  curbside.completeAllTrips(function(error){

  });

  /**
   * Cancels the trip for the user to the given site identified by the "SITE_ID" with the given "UNIQUE_TRACK_TOKEN".
   *
   * If no "UNIQUE_TRACK_TOKEN" is set, then *ALL* trips to this site are cancelled.
   *
   * Note: Do not call this when the user logs out, instead set the "USER_UNIQUE_TRACKING_ID" to nil when the user logs out.
   **/
  Curbside.cancelTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN", function(error){

  });

  /**
   * Returns the "USER_UNIQUE_TRACKING_ID" of the currently tracked user.
   **/
  Curbside.getTrackingIdentifier(function(error, trackingIdentifier){

  });

  /**
   * Returns the list of sites currently tracked by the user.
   **/
  Curbside.getTrackedSites(function(error, sites){

  });

  /**
   * Set userInfo e.g. full name, email and sms number
   **/
  Curbside.setUserInfo({fullName, emailAddress, smsNumber}, function(error){

  });

  /**
   * Returns the userInfo e.g. full name, email and sms number
   */
  Curbside.getUserInfo(function(error, userInfo){

  });
});
</script>
```

### For Monitoring Session

```html
<script type="text/javascript">
document.addEventListener("deviceready", function() {
   /**
   * Will be triggered when user status updates are sent to the consuming application.
   **/
  Curbside.on("updatedTrackedSites", function(UserStatusUpdates){
    // Do something
  });

  /**
   * Set the "USER_UNIQUE_TRACKING_ID" of the user currently logged in your app. This may be nil when the app is
   * started, but as the user logs into the app, make sure this value is set. trackingIdentifier needs to be set to use
   * session specific methods for starting trips or monitoring sites. This identifier will be persisted across
   * application restarts.
   *
   * When the user logs out, set this to nil, which will in turn end the user session or monitoring session.
   * Note: The maximum length of the trackingIdentifier is 36 characters.
   **/
  Curbside.setTrackingIdentifier("USER_UNIQUE_TRACKING_ID", function(error){

  });

  /**
   * Returns the "USER_UNIQUE_TRACKING_ID" of the currently tracked user.
   **/
  Curbside.getTrackingIdentifier(function(error, trackingIdentifier){

  });

  /**
   * Completes the trip(s) identified by the trackToken(s) and trackIdentifier to this site.
   * Call this method when the trip(s) for the given trackToken(s) is/are completed by the user.
   * If the trackTokens is nil, then all trips to this site for the user will be marked complete.
   **/
  Curbside.completeTripForTrackingIdentifier("USER_UNIQUE_TRACKING_ID", ["UNIQUE_TRACK_TOKEN_1", "UNIQUE_TRACK_TOKEN_2"], function(error){

  });

  /**
   * Cancels the trip(s) identified by the trackToken(s) and trackIdentifier to this site.
   * Call this method when the trip(s) for the given trackToken(s) is/are cancelled by the user.
   * If the trackTokens is nil, then all trips to this site for the user will be canceled.
   **/
  Curbside.cancelTripForTrackingIdentifier("USER_UNIQUE_TRACKING_ID", ["UNIQUE_TRACK_TOKEN_1", "UNIQUE_TRACK_TOKEN_2"], function(error){

  });

  /**
   * This subscribes to user arrival and status updates to the site defined by arrivalSite.
   * If an error occurs because of an invalid session state, permissions or authentication with the ARRIVE server,
   * Will trigger userStatusUpdates
   **/
  Curbside.startMonitoringArrivalsToSiteWithIdentifier("SITE_ID", function(error){

  });

  /**
   * This unsubscribes to user status updates.
   **/
  Curbside.stopMonitoringArrivals(function(error){

  });
});
</script>
```

### Promise

All functions return a Promise as an alternative to a callback.

-   setTrackingIdentifier
-   startTripToSiteWithIdentifier
-   startTripToSiteWithIdentifierAndEta
-   completeTripToSiteWithIdentifier
-   completeAllTrips
-   cancelTripToSiteWithIdentifier
-   getTrackingIdentifier
-   getTrackedSites

The Promise can be used like this:

```js
Curbside.getTrackedSites
    .then(function(sites) {
        // Do something
    })
    .catch(function(error) {
        // Do something
    });
```
