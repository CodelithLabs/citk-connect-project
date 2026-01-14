import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Monitors bus locations and flags drivers exceeding 60 km/h.
 * Triggered on updates to 'bus_locations/{busId}'.
 */
export const monitorBusSpeed = functions.firestore
  .document("bus_locations/{busId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const busId = context.params.busId;

    if (!newData) return null;

    // Speed is stored in meters/second (Geolocator standard)
    const speedMps = newData.speed || 0;
    const speedKmph = speedMps * 3.6;
    const SPEED_LIMIT = 60; // km/h

    if (speedKmph > SPEED_LIMIT) {
      // Prevent spamming: Check if an alert was created in the last 2 minutes
      const recentAlerts = await admin.firestore()
        .collection("driver_alerts")
        .where("busId", "==", busId)
        .where("type", "==", "OVERSPEED")
        .where("timestamp", ">", admin.firestore.Timestamp.fromMillis(Date.now() - 2 * 60 * 1000))
        .limit(1)
        .get();

      if (!recentAlerts.empty) return null;

      // Create a new alert flag
      await admin.firestore().collection("driver_alerts").add({
        busId: busId,
        type: "OVERSPEED",
        speed_kmph: parseFloat(speedKmph.toFixed(1)),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        location: new admin.firestore.GeoPoint(newData.lat, newData.lng),
        resolved: false,
      });
    }
    return null;
  });