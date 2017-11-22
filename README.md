# Curbside Cordova plugin for iOS and Android (version 3.0.0)

This plugin is a thin wrapper for [Curbside SDK](https://developer.curbside.com/docs/).

---

## Quick install

_Stable version(npm)_

```
$> cordova plugins add curbside-cordova \
    --variable USAGE_TOKEN="..."
```

_Develop version_

```bash
$> cordova plugin add https://github.com/Curbside/curbside-cordova.git \
    --variable USAGE_TOKEN="..."
```

If you re-install the plugin, please always remove the plugin first, then remove the SDK

```bash
$> cordova plugin rm curbside-cordova

$> cordova plugin add curbside-cordova \
    --variable USAGE_TOKEN="..."
```

### Configuration

You can also configure the following variables to customize the iOS location plist entries

* `LOCATION_WHEN_IN_USE_DESCRIPTION` for `NSLocationWhenInUseUsageDescription` (defaults to "To get accurate GPS
  locations")
* `LOCATION_ALWAYS_USAGE_DESCRIPTION` for `NSLocationAlwaysUsageDescription` (defaults to "To get accurate GPS
  locations")

Example using the Cordova CLI

```bash
$> cordova plugin add curbside-cordova \
    --variable USAGE_TOKEN="..."
    --variable LOCATION_WHEN_IN_USE_DESCRIPTION="My custom when in use message" \
    --variable LOCATION_ALWAYS_USAGE_DESCRIPTION="My custom always usage message"
```

Example using config.xml

```xml
<plugin name="curbside-cordova" spec="3.0.0">
    <variable name="USAGE_TOKEN" value="YOUR_USAGE_TOKEN_IS_HERE" />
    <variable name="LOCATION_WHEN_IN_USE_DESCRIPTION" value="My custom when in use message" />
    <variable name="LOCATION_ALWAYS_USAGE_DESCRIPTION" value="My custom always usage message" />
</plugin>
```

## Quick example

```html
<script type="text/javascript">
document.addEventListener("deviceready", function() {
  /**
   * Will be trigger when the user is near a site where the associate can be notified of the user arrival.
   */
  Curbside.on("canNotifyMonitoringSessionUserAtSite", function(site){
    // Do something
  })

  /**
   * Will be trigger when the user is approaching a site which is currently tracked for a trip.
   */
  Curbside.on("userApproachingSite", function(site){
    // Do something
  })

  /**
   * Will be trigger when the user has arrived at a site which is currently tracked for a trip.
   */
  Curbside.on("userArrivedAtSite", function(site){
    // Do something
  })

  /**
   * Will be trigger when an error encountered.
   */
  Curbside.on("encounteredError", function(error){
    // Do something
  })

  /**
   * Will be trigger when trackedSites are updated.
   */
  Curbside.on("updatedTrackedSites", function(sites){
    // Do something
  })

  /**
   * trackingIdentifier for the user who is logged into the device. This may be nil when the app is started, but as the
   * user logs into the app, make sure this value is set. trackingIdentifier needs to be set to use session specific methods for starting
   * trips or monitoring sites. This identifier will be persisted across application restarts.
   *
   * When the user logs out, set this to nil, which will inturn end the user session or monitoring session.
   * Note: The maximum length of the trackingIdentifier is 36 characters.
  */
  Curbside.setTrackingIdentifier("USER_UNIQUE_TRACKING_ID");

  /**
   * Start a trip tracking the user to the site identified by the siteID. Call this method when
   * the application thinks its appropriate to start tracking the user eg. Order is ready to be picked up at
   * the site. This information is persisted across relaunch.
   */
  Curbside.startTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN");

  /**
   * Completes the trip for the user to the site identified by the siteID with the given trackToken.
   * If no trackToken is specified, then *all* trips to this site  will be completed.
   * Note: Do not call this when the user logs out, instead set the trackingIdentifier to nil when the user logs out.
   */
  Curbside.completeTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN");

  /**
   * This method would complete all trips for this user across all devices.
   * Note: Do not call this when the user logs out, instead set the trackingIdentifier to nil when the user logs out.
   */
  curbside.completeAllTrips()

  /**
   * Cancels the trip for the user to the given site identified by the siteID with the given trackToken.
   * If no trackToken is set, then *all* trips to this site are cancelled.
   * Note: Do not call this when the user logs out, instead set the trackingIdentifier to nil when the user logs out.
   */
  Curbside.cancelTripToSiteWithIdentifier("SITE_ID", "UNIQUE_TRACK_TOKEN")

  /**
   * This method will cancels all trips for all sites for the user.
   * Note: Do not call this when the user logs out, instead set the trackingIdentifier to nil when the user logs out.
   */
  Curbside.cancelAllTrips()
});
</script>
```
