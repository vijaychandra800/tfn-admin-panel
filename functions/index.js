const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const {Timestamp} = require("firebase-admin/firestore"); // Import Timestamp

admin.initializeApp();
const db = admin.firestore();

// Firebase Collection
const eventsCollection = "events";
const notificationsCollection = "notifications";

exports.updateEventStatus = onSchedule("every 1 minutes", async () => {
  try {
    const now = Timestamp.now();
    console.log("Current Firestore Timestamp:", Timestamp.now());

    const batch = db.batch();
    let updateCount = 0;

    // Update status to "upcoming" if event is in the future
    try {
      const upcomingEvents = await db.collection(eventsCollection)
          .where("start_date_time", ">", now)
          .where("status", "not-in", ["upcoming"])
          .get();

      console.log(`Found ${upcomingEvents.size} upcoming events.`);

      upcomingEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "upcoming"`);
        batch.update(doc.ref, {status: "upcoming"});
        updateCount++;
      });
    } catch (error) {
      console.error("Error fetching upcoming events:", error);
    }

    // Update status to "live" if event is currently happening
    try {
      const liveEvents = await db.collection(eventsCollection)
          .where("start_date_time", "<=", now)
          .where("end_date_time", ">", now)
          .where("status", "not-in", ["live"])
          .get();

      console.log(`Found ${liveEvents.size} live events.`);

      liveEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "live"`);
        batch.update(doc.ref, {status: "live"});
        updateCount++;
      });
    } catch (error) {
      console.error("Error fetching live events:", error);
    }


    // Update status to "covered" if event has ended
    try {
      const coveredEvents = await db.collection(eventsCollection)
          .where("end_date_time", "<=", now)
          .where("status", "not-in", ["covered"])
          .get();

      console.log(`Found ${coveredEvents.size} covered events.`);

      coveredEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "covered"`);
        batch.update(doc.ref, {status: "covered"});
        updateCount++;
      });
    } catch (error) {
      console.error("Error fetching covered events:", error);
    }

    // Only commit if there are changes
    if (updateCount > 0) {
      await batch.commit();
      console.log(`Event statuses updated successfully
       for ${updateCount} events.`);
    } else {
      console.log("No events required status updates.");
    }
  } catch (error) {
    console.error("Error updating event statuses:", error);
  }
});

// Function to send notifications 30 minutes before event start
exports.sendEventNotification = onSchedule("every 5 minutes", async () => {
  try {
    const now = Timestamp.now();
    const notifyTime = Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000));

    // Fetch events starting in the next 30 minutes
    const upcomingEvents = await db.collection(eventsCollection)
        .where("start_date_time", ">=", now)
        .where("start_date_time", "<=", notifyTime)
        .orderBy("start_date_time")
        .get();

    if (upcomingEvents.empty) {
      console.log("No new events requiring notification.");
      return;
    }

    console.log(`Found ${upcomingEvents.size} upcoming events.`);

    // Fetch notifications already sent from the notifications table
    const notificationsSnapshot = await db.collection(notificationsCollection).get();
    const notifiedEventIds = notificationsSnapshot.docs.map((doc) => doc.data().event_id);

    console.log(`Already notified events:`, notifiedEventIds);

    // Filter out events that have already been notified
    const eventsToNotify = upcomingEvents.docs.filter((eventDoc) => !notifiedEventIds.includes(eventDoc.id));

    if (eventsToNotify.length === 0) {
      console.log("All upcoming events have already been notified.");
      return;
    }

    console.log(`Sending notifications for ${eventsToNotify.length} events.`);

    // Send notifications for each event
    for (const eventDoc of eventsToNotify) {
      const eventData = eventDoc.data();
      const message = {
        notification: {
          title: "Upcoming Event",
          body: `Event "${eventData.title}" starts in 30 minutes!`,
        },
        data: {
          title: "Upcoming Event",
          body: `Event "${eventData.title}" starts in 30 minutes!`,
          type: "event",
          id: "2",
          notification_type: "event",
        },
        topic: "all",
      };

      console.log(`Sending notification for event: ${eventData.title}`);

      try {
        const response = await admin.messaging().send(message);
        console.log(`Notification sent successfully:`, response);

        // Store notification in Firestore notifications collection
        const notificationData = {
          event_id: eventDoc.id, // Map event ID to notifications
          title: eventData.title, // Use event name as notification title
          description: `<p>${eventData.title} is starting soon!</p>`,
          topic: "all",
          sent_at: Timestamp.now(),
        };

        await db.collection(notificationsCollection).add(notificationData);

        console.log(`Notification saved in FireStore for event: ${eventData.title}`);
      } catch (error) {
        console.error(`Error sending notification for event ${eventData.title}:`, error);
      }
    }

    console.log("Notifications sent successfully.");
  } catch (error) {
    console.error("Error sending notifications:", error);
  }
});
