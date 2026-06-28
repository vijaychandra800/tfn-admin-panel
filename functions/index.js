const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore"); // Import Timestamp

admin.initializeApp();
const db = admin.firestore();

// Firebase Collection
const eventsCollection = "events";
const notificationsCollection = "notifications";
const commentsCollection = "comments";
const settingsCollection = "settings";
const usersCollection = "users";

// Defaults for the Fanzone chat lifespan, overridable from settings/app.
const DEFAULT_CHAT_PURGE_DAYS = 7;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

exports.updateEventStatus = onSchedule("every 1 minutes", async () => {
  try {
    const now = Timestamp.now();
    console.log("Current Firestore Timestamp:", Timestamp.now());

    const batch = db.batch();
    let updateCount = 0;

    // Update status to "upcoming" if event is in the future
    try {
      const upcomingEvents = await db
        .collection(eventsCollection)
        .where("start_date_time", ">", now)
        .where("status", "not-in", ["upcoming"])
        .get();

      console.log(`Found ${upcomingEvents.size} upcoming events.`);

      upcomingEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "upcoming"`);
        batch.update(doc.ref, { status: "upcoming" });
        updateCount++;
      });
    } catch (error) {
      console.error("Error fetching upcoming events:", error);
    }

    // Update status to "live" if event is currently happening
    try {
      const liveEvents = await db
        .collection(eventsCollection)
        .where("start_date_time", "<=", now)
        .where("end_date_time", ">", now)
        .where("status", "not-in", ["live"])
        .get();

      console.log(`Found ${liveEvents.size} live events.`);

      liveEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "live"`);
        batch.update(doc.ref, { status: "live" });
        updateCount++;
      });
    } catch (error) {
      console.error("Error fetching live events:", error);
    }

    // Update status to "covered" if event has ended
    try {
      const coveredEvents = await db
        .collection(eventsCollection)
        .where("end_date_time", "<=", now)
        .where("status", "not-in", ["covered"])
        .get();

      console.log(`Found ${coveredEvents.size} covered events.`);

      coveredEvents.forEach((doc) => {
        console.log(`Updating event ${doc.id} to "covered"`);
        batch.update(doc.ref, { status: "covered" });
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
    const notifyTime = Timestamp.fromDate(
      new Date(Date.now() + 30 * 60 * 1000),
    );

    // Fetch events starting in the next 30 minutes
    const upcomingEvents = await db
      .collection(eventsCollection)
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
    const notificationsSnapshot = await db
      .collection(notificationsCollection)
      .get();
    const notifiedEventIds = notificationsSnapshot.docs.map(
      (doc) => doc.data().event_id,
    );

    console.log(`Already notified events:`, notifiedEventIds);

    // Filter out events that have already been notified
    const eventsToNotify = upcomingEvents.docs.filter(
      (eventDoc) => !notifiedEventIds.includes(eventDoc.id),
    );

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

        console.log(
          `Notification saved in FireStore for event: ${eventData.title}`,
        );
      } catch (error) {
        console.error(
          `Error sending notification for event ${eventData.title}:`,
          error,
        );
      }
    }

    console.log("Notifications sent successfully.");
  } catch (error) {
    console.error("Error sending notifications:", error);
  }
});

// Purge event (Fanzone) chats once the event has been over for longer than
// the admin-configured `chat_purge_days` (default 7). Runs once a day, finds
// events ended before the cutoff, and batch-deletes every comment whose
// target is that event. Deletes are chunked to respect Firestore's 500-write
// batch limit.
exports.purgeExpiredEventChats = onSchedule("every 24 hours", async () => {
  try {
    // Resolve the configurable purge window from settings/app.
    let purgeDays = DEFAULT_CHAT_PURGE_DAYS;
    try {
      const settingsSnap = await db
        .collection(settingsCollection)
        .doc("app")
        .get();
      const configured = settingsSnap.get("chat_purge_days");
      if (typeof configured === "number" && configured > 0) {
        purgeDays = configured;
      }
    } catch (error) {
      console.error("Error reading chat_purge_days, using default:", error);
    }

    const cutoff = Timestamp.fromMillis(Date.now() - purgeDays * MS_PER_DAY);
    console.log(
      `Purging event chats ended before ${cutoff.toDate()} ` +
        `(purge window: ${purgeDays} days).`,
    );

    const endedEvents = await db
      .collection(eventsCollection)
      .where("end_date_time", "<=", cutoff)
      .get();

    if (endedEvents.empty) {
      console.log("No expired event chats to purge.");
      return;
    }

    let totalDeleted = 0;
    for (const eventDoc of endedEvents.docs) {
      totalDeleted += await deleteEventComments(eventDoc.id);
    }

    console.log(
      `Purged ${totalDeleted} comments across ` +
        `${endedEvents.size} expired events.`,
    );
  } catch (error) {
    console.error("Error purging expired event chats:", error);
  }
});

/**
 * Deletes every comment belonging to a given event, in batches of 450.
 * @param {string} eventId The event whose comments should be removed.
 * @return {Promise<number>} The number of comments deleted.
 */
async function deleteEventComments(eventId) {
  let deleted = 0;
  // Loop until no more matching comments remain.
  for (;;) {
    const snap = await db
      .collection(commentsCollection)
      .where("target_type", "==", "event")
      .where("target_id", "==", eventId)
      .limit(450)
      .get();

    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snap.size;

    if (snap.size < 450) break;
  }
  return deleted;
}

// ---------------------------------------------------------------------------
// Comment engagement notifications
//
// Notify the owner of a comment whenever another user replies to it or reacts
// to it. Tokens are read from `users/{uid}.fcmToken`. The author is never
// notified about their own reply/reaction, and stale tokens are pruned.
// ---------------------------------------------------------------------------

/**
 * Builds the routing data payload (all-string values) used by the app to open
 * the right screen when a comment notification is tapped.
 * @param {Object} commentData The comment document data.
 * @return {Object} String key/value pairs describing the comment target.
 */
function buildCommentTargetData(commentData) {
  const targetType = commentData.target_type || "article";
  const targetId = commentData.target_id || commentData.article_id || "";
  if (targetType === "event") {
    return { type: "event", event_id: String(targetId) };
  }
  return { type: "article", article_id: String(targetId) };
}

/**
 * Looks up a user's FCM token and sends a single notification. Silently skips
 * when the user has no token, and removes the token if FCM reports it as
 * unregistered.
 * @param {string} ownerId The recipient user id.
 * @param {string} title Notification title.
 * @param {string} body Notification body.
 * @param {Object} data Extra string key/value routing data.
 * @return {Promise<void>}
 */
async function sendCommentNotification(ownerId, title, body, data) {
  if (!ownerId) return;
  let token;
  try {
    const userSnap = await db.collection(usersCollection).doc(ownerId).get();
    token = userSnap.get("fcmToken");
  } catch (error) {
    console.error(`Error reading fcmToken for user ${ownerId}:`, error);
    return;
  }
  if (!token) {
    console.log(`User ${ownerId} has no fcmToken; skipping notification.`);
    return;
  }

  const message = {
    token,
    notification: { title, body },
    data: {
      title,
      body,
      notification_type: "comment",
      ...data,
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`Comment notification sent to ${ownerId}:`, response);
  } catch (error) {
    console.error(`Error sending comment notification to ${ownerId}:`, error);
    // Prune tokens FCM no longer recognises so we stop retrying them.
    if (
      error.code === "messaging/registration-token-not-registered" ||
      error.code === "messaging/invalid-registration-token"
    ) {
      try {
        await db
          .collection(usersCollection)
          .doc(ownerId)
          .update({ fcmToken: admin.firestore.FieldValue.delete() });
        console.log(`Removed stale fcmToken for user ${ownerId}.`);
      } catch (cleanupError) {
        console.error(
          `Error removing stale fcmToken for user ${ownerId}:`,
          cleanupError,
        );
      }
    }
  }
}

// Notify the parent comment's owner when someone replies to their comment.
exports.onCommentReply = onDocumentCreated(
  `${commentsCollection}/{commentId}`,
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const comment = snap.data();

    const replyTo = comment.reply_to;
    if (!replyTo || !replyTo.comment_id) return; // Not a reply.

    // Engagement notifications are scoped to the event Fanzone only —
    // replies on article comment threads never push.
    if (comment.target_type !== "event") return;

    const replier = comment.user || {};
    const replierId = replier.id;

    // Fetch the parent comment to resolve its owner.
    let parent;
    try {
      const parentSnap = await db
        .collection(commentsCollection)
        .doc(replyTo.comment_id)
        .get();
      if (!parentSnap.exists) return;
      parent = parentSnap.data();
    } catch (error) {
      console.error(
        `Error reading parent comment ${replyTo.comment_id}:`,
        error,
      );
      return;
    }

    const ownerId = (parent.user || {}).id;
    if (!ownerId || ownerId === replierId) return; // Skip self-replies.

    const replierName = replier.name || "Someone";
    const title = "New reply";
    const body = `${replierName} replied to your message`;

    await sendCommentNotification(
      ownerId,
      title,
      body,
      buildCommentTargetData(comment),
    );
  },
);

// Notify a comment's owner when another user adds a reaction to it.
exports.onCommentReaction = onDocumentUpdated(
  `${commentsCollection}/{commentId}`,
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    // Engagement notifications are scoped to the event Fanzone only —
    // reactions on article comment threads never push.
    if (after.target_type !== "event") return;

    const ownerId = (after.user || {}).id;
    if (!ownerId) return;

    const beforeReactions = before.reactions || {};
    const afterReactions = after.reactions || {};

    // Collect (userId, emoji) pairs that were newly added in this update.
    const newlyReacted = [];
    for (const emoji of Object.keys(afterReactions)) {
      const beforeUsers = new Set(beforeReactions[emoji] || []);
      for (const uid of afterReactions[emoji] || []) {
        if (!beforeUsers.has(uid) && uid !== ownerId) {
          newlyReacted.push({ userId: uid, emoji });
        }
      }
    }
    if (newlyReacted.length === 0) return;

    const targetData = buildCommentTargetData(after);

    for (const { userId, emoji } of newlyReacted) {
      let reactorName = "Someone";
      try {
        const reactorSnap = await db
          .collection(usersCollection)
          .doc(userId)
          .get();
        reactorName = reactorSnap.get("name") || reactorName;
      } catch (error) {
        console.error(`Error reading reactor ${userId}:`, error);
      }

      const title = "New reaction";
      const body = `${reactorName} reacted ${emoji} to your message`;

      await sendCommentNotification(ownerId, title, body, targetData);
    }
  },
);
