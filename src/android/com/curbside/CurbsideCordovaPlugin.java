/**
 */
package com.curbside;


import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.util.ArraySet;
import android.util.Log;

import com.curbside.sdk.CSSite;
import com.curbside.sdk.CSTripInfo;
import com.curbside.sdk.CSUserSession;
import com.curbside.sdk.CSUserStatus;
import com.curbside.sdk.OperationStatus;
import com.curbside.sdk.OperationType;
import com.curbside.sdk.credentialprovider.TokenCurbsideCredentialProvider;
import com.curbside.sdk.event.Event;
import com.curbside.sdk.event.Path;
import com.curbside.sdk.event.Status;
import com.curbside.sdk.event.Type;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONStringer;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.Set;

import rx.Subscriber;
import rx.exceptions.OnErrorNotImplementedException;
import rx.functions.Action1;

public class CurbsideCordovaPlugin extends CordovaPlugin {

    private static final int PERMISSION_REQUEST_CODE = 1;
    private CallbackContext eventListenerCallbackContext;
    private ArrayList<PluginResult> pluginResults = new ArrayList<PluginResult>();

    @Override
    public void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);

        final CurbsideCordovaPlugin ccPlugin = this;


        CSUserSession instance = CSUserSession.getInstance();
        if (instance == null) {
            throw new Error("CSUserSession must be initialized init");
        }

        subscribe(Type.CAN_NOTIFY_MONITORING_USER_AT_SITE, "canNotifyMonitoringSessionUserAtSite");
        subscribe(Type.APPROACHING_SITE, "userApproachingSite");
        subscribe(Type.ARRIVED_AT_SITE, "userArrivedAtSite");
        subscribe(Type.UPDATED_TRACKED_SITES, "updatedTrackedSites");
    }

    private Object jsonEncode(Object object) throws JSONException {
        if (object instanceof Collection) {
            JSONArray result = new JSONArray();
            for (Object item : (Collection) object) {
                result.put(jsonEncode(item));
            }
            return result;
        } else if (object instanceof CSSite) {
            CSSite site = (CSSite) object;
            JSONObject result = new JSONObject();
            result.put("siteIdentifier", site.getSiteIdentifier());
            result.put("distanceFromSite", site.getDistanceFromSite());
            result.put("userStatus", jsonEncode(site.getUserStatus()));
            result.put("trips", jsonEncode(site.getTripInfos()));
            return result;
        } else if (object instanceof CSUserStatus) {
            CSUserStatus userStatus = (CSUserStatus) object;
            switch (userStatus) {
                case ARRIVED:
                    return "arrived";
                case IN_TRANSIT:
                    return "inTransit";
                case APPROACHING:
                    return "approaching";
                case INITIATED_ARRIVED:
                    return "userInitiatedArrived";
                case UNKNOWN:
                    return "unknown";
            }
            return null;
        } else if (object instanceof CSTripInfo) {
            CSTripInfo tripInfo = (CSTripInfo) object;
            JSONObject result = new JSONObject();
            result.put("trackToken", tripInfo.getTrackToken());
            result.put("startDate", tripInfo.getStartDate());
            result.put("destID", tripInfo.getDestId());
            return result;
        }
        return object;
    }

    private void subscribe(Type type, final String eventName) {
        final CurbsideCordovaPlugin ccPlugin = this;
        Subscriber<Event> subscriber = new Subscriber<Event>() {
            @Override
            public final void onCompleted() {
            }

            @Override
            public final void onError(Throwable e) {
                throw new OnErrorNotImplementedException(e);
            }

            @Override
            public final void onNext(Event event) {
                try {
                    JSONObject result = new JSONObject();
                    result.put("event", eventName);
                    if (event.object != null) {
                        result.put("result", jsonEncode(event.object));
                    }
                    PluginResult dataResult = new PluginResult(event.status == Status.SUCCESS ? PluginResult.Status.OK : PluginResult.Status.ERROR, result);
                    dataResult.setKeepCallback(true);
                    if (ccPlugin.eventListenerCallbackContext != null) {
                        ccPlugin.eventListenerCallbackContext.sendPluginResult(dataResult);
                    } else {
                        pluginResults.add(dataResult);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        };
        listenEvent(type, subscriber);
    }

    private void listenNextEvent(final Type type, final CallbackContext callbackContext) {
        Subscriber<Event> subscriber = new Subscriber<Event>() {
            @Override
            public final void onCompleted() {
            }

            @Override
            public final void onError(Throwable e) {
                throw new OnErrorNotImplementedException(e);
            }

            @Override
            public final void onNext(Event event) {
                Object result = event.object;
                if (event.status == Status.SUCCESS) {
                    if (result instanceof JSONObject) {
                        callbackContext.success((JSONObject) result);
                    } else if (result instanceof JSONArray) {
                        callbackContext.success((JSONArray) result);
                    } else if (result instanceof String) {
                        callbackContext.success((String) result);
                    } else {
                        callbackContext.success();
                    }
                } else {
                    callbackContext.error(event.object.toString());
                }
                unsubscribe();
            }
        };
        listenEvent(type, subscriber);
    }

    private void listenEvent(final Type type, final Subscriber<Event> subscriber) {
        CSUserSession
                .getInstance()
                .getEventBus()
                .getObservable(Path.USER, type)
                .subscribe(subscriber);
    }


    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("eventListener")) {
            this.eventListenerCallbackContext = callbackContext;
            for (PluginResult pluginResult : pluginResults) {
                callbackContext.sendPluginResult(pluginResult);
            }
            pluginResults.clear();
        } else {
            if (action.equals("setTrackingIdentifier")) {
                String trackingIdentifier = args.getString(0);
                if (trackingIdentifier != null) {
                    listenNextEvent(Type.REGISTER_TRACKING_ID, callbackContext);
                    CSUserSession.getInstance().registerTrackingIdentifier(trackingIdentifier);
                } else {
                    listenNextEvent(Type.UNREGISTER_TRACKING_ID, callbackContext);
                    CSUserSession.getInstance().unregisterTrackingIdentifier();
                }
            } else if (action.equals("startTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                listenNextEvent(Type.START_TRIP, callbackContext);
                CSUserSession.getInstance().startTripToSiteWithIdentifier(siteID, trackToken);
            } else if (action.equals("completeTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                listenNextEvent(Type.COMPLETE_TRIP, callbackContext);
                CSUserSession.getInstance().completeTripToSiteWithIdentifier(siteID, trackToken);
            } else if (action.equals("completeAllTrips")) {
                CSUserSession.getInstance().completeAllTrips();
                listenNextEvent(Type.COMPLETE_ALL_TRIPS, callbackContext);
            } else if (action.equals("cancelTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                listenNextEvent(Type.CANCEL_TRIP, callbackContext);
                CSUserSession.getInstance().cancelTripToSiteWithIdentifier(siteID, trackToken);
            } else if (action.equals("cancelAllTrips")) {
                CSUserSession.getInstance().cancelAllTrips();
                listenNextEvent(Type.CANCEL_ALL_TRIPS, callbackContext);
            } else if (action.equals("getTrackingIdentifier")) {
                callbackContext.success(CSUserSession.getInstance().getTrackingIdentifier());
            } else if (action.equals("getTrackedSites")) {
                callbackContext.success((JSONObject) jsonEncode(CSUserSession.getInstance().getTrackedSites()));
            }
        }
        return true;
    }

}
