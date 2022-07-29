const functions = require("firebase-functions");
const admin = require("firebase-admin");
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

admin.initializeApp();


const db = admin.firestore();
const batch = db.batch();

exports.createNewDocumentInNotificationsCollection = functions.firestore
    .document("routes/{documentId}")
    .onCreate((snapshot, context) => {
        var newDocRef = db.doc('notifications/${snapshot.id}');
        batch.set(newDocRef, {
            "data": "1"
        })
        return batch.commit();
    });

exports.createOnNotificationsCollectionAndLogger = functions.firestore
    .document("notifications/{documentId}")
    .onCreate((snapshot, context) => {
        functions.logger.info("Notificação do documento " + snapshot.id + " enviado!", { structuredData: true });
    });




exports.helloWorld = functions.https.onRequest((request, response) => {
    functions.logger.info("Hello logs!", { structuredData: true });
    response.send("Hello from Firebase!");
});



