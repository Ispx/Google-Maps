const functions = require("firebase-functions");
const admin = require("firebase-admin");
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

admin.initializeApp();


const db = admin.firestore();
const batch = db.batch();

exports.listenCreationInEnRoute = functions.firestore
    .document("en-route/{documentId}")
    .onWrite((snapshot, context) => {
        console.log(snapshot);
        var newDocRef = db.doc('historic/${snapshot.id}');
        batch.set(newDocRef, snapshot.data)
        return batch.commit();
    });

exports.createHistoric = functions.firestore
    .document("historic/")
    .onWrite((snapshot, context) => {
        functions.logger.info("Notificação do documento " + snapshot.id + " enviado!", { structuredData: true });
    });






