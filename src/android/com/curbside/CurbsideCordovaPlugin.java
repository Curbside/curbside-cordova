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
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.Set;

import rx.functions.Action1;

public class CurbsideCordovaPlugin extends CordovaPlugin {

    private static final int PERMISSION_REQUEST_CODE = 1;
    private Activity activity;
    private CallbackContext eventListenerCallbackContext;

    @Override
    public void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);

        Context context = webView.getContext();

        activity = cordova.getActivity();
        ApplicationInfo applicationInfo = null;
        try {
            applicationInfo = activity.getPackageManager().getApplicationInfo(activity.getPackageName(), PackageManager.GET_META_DATA);
        } catch (NameNotFoundException e) {
        }

        boolean needRequestPermission = ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED;

        if (needRequestPermission) {
            String[] permissions = new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION};
            ActivityCompat.requestPermissions(cordova.getActivity(), permissions, PERMISSION_REQUEST_CODE);
        }

        // Request permissions results
        String USAGE_TOKEN = applicationInfo.metaData.getString("com.curbside.USAGE_TOKEN");
        CSUserSession.init(webView.getContext(), new TokenCurbsideCredentialProvider(USAGE_TOKEN));

        final CurbsideCordovaPlugin ccPlugin = this;

        CSUserSession
                .getInstance()
                .getEventBus()
                .getObservable(Path.USER, Type.REGISTER_TRACKING_ID)
                .subscribe(new Action1<Event>() {
                    @Override
                    public void call(Event event) {
                        Log.i(event.type.toString(), event.status.toString());

                    }
                });
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

    private void suscribe(Type type, final String eventName) {
        final CurbsideCordovaPlugin ccPlugin = this;
        CSUserSession
                .getInstance()
                .getEventBus()
                .getObservable(Path.USER, type)
                .subscribe(new Action1<Event>() {
                    @Override
                    public void call(Event event) {
                        try {
                            JSONObject result = new JSONObject();
                            result.put("event", eventName);
                            if (event.object != null) {
                                result.put("result", jsonEncode(event.object));
                            }
                            PluginResult dataResult = new PluginResult(event.status == Status.SUCCESS ? PluginResult.Status.OK : PluginResult.Status.ERROR, result);
                            dataResult.setKeepCallback(true);
                            ccPlugin.eventListenerCallbackContext.success(result);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                });
    }

    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("eventListener")) {
            this.eventListenerCallbackContext = callbackContext;
            suscribe(Type.CAN_NOTIFY_MONITORING_USER_AT_SITE, "canNotifyMonitoringSessionUserAtSite");
            suscribe(Type.APPROACHING_SITE, "userApproachingSite");
            suscribe(Type.ARRIVED_AT_SITE, "userArrivedAtSite");
            suscribe(Type.UPDATED_TRACKED_SITES, "updatedTrackedSites");
        } else {
            OperationStatus status = null;
            Object result = null;
            if (action.equals("setTrackingIdentifier")) {
                String trackingIdentifier = args.getString(0);
                if (trackingIdentifier != null) {
                    status = CSUserSession.getInstance().registerTrackingIdentifier(trackingIdentifier);
                } else {
                    CSUserSession.getInstance().unregisterTrackingIdentifier();
                }
            } else if (action.equals("startTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                status = CSUserSession.getInstance().startTripToSiteWithIdentifier(siteID, trackToken);
            } else if (action.equals("completeTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                CSUserSession.getInstance().completeTripToSiteWithIdentifier(siteID, trackToken);
                status = new OperationStatus(OperationType.SUCCESS, "completeTripToSiteWithIdentifier");
            } else if (action.equals("completeAllTrips")) {
                CSUserSession.getInstance().completeAllTrips();
                status = new OperationStatus(OperationType.SUCCESS, "completeAllTrips");
            } else if (action.equals("cancelTripToSiteWithIdentifier")) {
                String siteID = args.getString(0);
                String trackToken = args.getString(1);
                CSUserSession.getInstance().cancelTripToSiteWithIdentifier(siteID, trackToken);
                status = new OperationStatus(OperationType.SUCCESS, "cancelTripToSiteWithIdentifier");
            } else if (action.equals("cancelAllTrips")) {
                CSUserSession.getInstance().cancelAllTrips();
                status = new OperationStatus(OperationType.SUCCESS, "cancelAllTrips");
            } else if (action.equals("getTrackingIdentifier")) {
                status = new OperationStatus(OperationType.SUCCESS, CSUserSession.getInstance().getTrackingIdentifier());
            } else if (action.equals("getTrackedSites")) {
                result = this.jsonEncode(CSUserSession.getInstance().getTrackedSites());
            }

            if (result instanceof JSONObject) {
                callbackContext.success((JSONObject) result);
            } else if (result instanceof JSONArray) {
                callbackContext.success((JSONArray) result);
            } else if (result instanceof String) {
                callbackContext.success((String) result);
            } else {
                if (status == null || status.operationType == OperationType.SUCCESS) {
                    callbackContext.success(status != null ? status.statusMessage : null);
                } else {
                    callbackContext.error(status.statusMessage);
                }
            }
        }
        return true;
    }

}
