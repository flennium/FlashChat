const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();
const mentionRegex = /(^|[^A-Za-z0-9._%+\-/:=#?&])@([A-Za-z0-9_.]+)/g;

function extractMentionUsernames(text = "") {
  const mentions = new Set();

  for (const match of text.matchAll(mentionRegex)) {
    // Always lowercase so @JohnDoe resolves to usernames/"johndoe"
    let username = (match[2] || "").toLowerCase();
    while (username.endsWith(".")) {
      username = username.slice(0, -1);
    }
    if (username) {
      mentions.add(username);
    }
  }

  return [...mentions];
}

exports.onNewMessage = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const roomId = context.params.roomId;
    const message = snap.data() || {};
    const senderId = message.senderId || "";

    const membersSnapshot = await db
      .collection("rooms")
      .doc(roomId)
      .collection("members")
      .get();

    const memberIds = membersSnapshot.docs.map((doc) => doc.id);
    if (memberIds.length === 0) {
      return null;
    }

    const memberRefs = membersSnapshot.docs
      .filter((doc) => doc.id !== senderId)
      .map((doc) => doc.ref);

    if (memberRefs.length > 0) {
      const batch = db.batch();
      for (const ref of memberRefs) {
        batch.set(
          ref,
          {
            unreadCount: admin.firestore.FieldValue.increment(1),
          },
          {merge: true},
        );
      }
      await batch.commit();
    }

    const mentionedUsernames = extractMentionUsernames(message.text || "");
    if (mentionedUsernames.length === 0) {
      return null;
    }

    const usernameDocs = await Promise.all(
      mentionedUsernames.map((username) =>
        db.collection("usernames").doc(username).get(),
      ),
    );

    const mentionedUids = usernameDocs
      .map((doc) => doc.data()?.uid)
      .filter((uid) => uid && uid !== senderId && memberIds.includes(uid));

    if (mentionedUids.length === 0) {
      return null;
    }

    const uniqueMentionedUids = [...new Set(mentionedUids)];
    const userDocs = await Promise.all(
      uniqueMentionedUids.map((uid) => db.collection("users").doc(uid).get()),
    );

    const tokens = userDocs
      .map((doc) => doc.data())
      .filter((user) => user && user.notificationsEnabled !== false)
      .map((user) => user.fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) {
      return null;
    }

    const senderLabel =
      message.senderUsername && String(message.senderUsername).trim()
        ? `@${message.senderUsername}`
        : message.senderName || "New mention";

    return admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `${senderLabel} mentioned you`,
        body: message.text || "You were mentioned in a room",
      },
      data: {
        roomId,
        type: "mention",
      },
    });
  });

exports.moderateMessage = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snap) => {
    const bannedWords = ["spamword", "bannedword"];
    const message = snap.data();
    const text = (message.text || "").toLowerCase();
    const shouldDelete = bannedWords.some((word) => text.includes(word));

    if (!shouldDelete) return null;

    return snap.ref.update({
      text: "",
      isDeleted: true,
    });
  });

exports.updateMemberCount = functions.firestore
  .document("rooms/{roomId}/members/{uid}")
  .onWrite(async (_, context) => {
    const roomRef = db.collection("rooms").doc(context.params.roomId);
    const membersSnapshot = await roomRef.collection("members").get();
    return roomRef.update({
      memberCount: membersSnapshot.size,
    });
  });
