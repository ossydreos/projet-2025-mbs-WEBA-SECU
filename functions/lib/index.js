import * as functions from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
initializeApp();
// Récupération sécurisée des secrets OneSignal
const APP_ID = functions.config().onesignal.app_id;
const REST_KEY = functions.config().onesignal.rest_key;
async function sendToOneSignalByTag(params) {
    const payload = {
        app_id: APP_ID,
        // ✅ Ciblage par tag "role: admin"
        filters: [
            { field: "tag", key: "role", relation: "=", value: "admin" }
        ],
        headings: { fr: params.title, en: params.title },
        contents: { fr: params.body, en: params.body },
        data: params.data ?? {},
    };
    if (params.sendAfterGMT) {
        payload.send_after = params.sendAfterGMT;
    }
    const res = await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
            Authorization: `Basic ${REST_KEY}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`OneSignal error ${res.status}: ${text}`);
    }
    return res.json();
}
// Fonction pour envoyer à un utilisateur spécifique par userId
async function sendToOneSignalByUserId(params) {
    const payload = {
        app_id: APP_ID,
        // ✅ Ciblage par external_user_id (userId du client)
        include_external_user_ids: [params.userId],
        headings: { fr: params.title, en: params.title },
        contents: { fr: params.body, en: params.body },
        data: params.data ?? {},
    };
    if (params.sendAfterGMT) {
        payload.send_after = params.sendAfterGMT;
    }
    const res = await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
            Authorization: `Basic ${REST_KEY}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`OneSignal error ${res.status}: ${text}`);
    }
    return res.json();
}
// 🔔 Trigger: nouvelle réservation confirmée → push à tous les admins
export const onReservationCreate = functions.firestore
    .document("reservations/{resId}")
    .onCreate(async (snap, ctx) => {
    const res = snap.data();
    console.log("🔔 Reservation créée:", res);
    console.log("🔔 Status:", res?.status);
    if (!res || res.status !== "pending") {
        console.log("❌ Status pas 'pending', skipping. Status actuel:", res?.status);
        return;
    }
    // 1) Cibler directement les utilisateurs avec le tag "role: admin" dans OneSignal
    console.log("🔍 Ciblage des utilisateurs avec tag 'role: admin'");
    // 2) Corps de notif
    let body = "Nouvelle réservation en attente";
    if (res.dateISO) {
        try {
            const when = new Date(res.dateISO);
            body = new Intl.DateTimeFormat("fr-FR", {
                dateStyle: "medium",
                timeStyle: "short",
            }).format(when);
        }
        catch { /* noop */ }
    }
    // 3) Envoi OneSignal avec ciblage par tag
    console.log("🚀 Envoi OneSignal aux utilisateurs avec tag 'role: admin'");
    try {
        const result = await sendToOneSignalByTag({
            title: "Nouvelle réservation ⏳",
            body,
            data: { route: `/reservations/${ctx.params.resId}` },
        });
        console.log("✅ OneSignal result:", result);
    }
    catch (error) {
        console.error("❌ Erreur OneSignal:", error);
    }
});
// 🔔 Trigger: réservation confirmée → notification au client
export const onReservationConfirmed = functions.firestore
    .document("reservations/{resId}")
    .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();
    // Vérifier que le statut est passé de "pending" à "confirmed"
    if (before.status !== "pending" || after.status !== "confirmed") {
        console.log("❌ Pas de changement pending→confirmed, skipping");
        return;
    }
    console.log("🔔 Réservation confirmée pour l'utilisateur:", after.userId);
    // Envoyer notification au client spécifique
    try {
        const result = await sendToOneSignalByUserId({
            userId: after.userId,
            title: "🚗 Chauffeur assigné !",
            body: `Votre course de ${after.departure} vers ${after.destination} a été acceptée. Vous pouvez maintenant confirmer et payer.`,
            data: {
                route: `/reservations/${ctx.params.resId}`,
                type: "reservation_confirmed",
                reservationId: ctx.params.resId
            },
        });
        console.log("✅ Notification client envoyée:", result);
    }
    catch (error) {
        console.error("❌ Erreur notification client:", error);
    }
});
// 🔔 Trigger: réservation annulée → notification au client
export const onReservationCancelled = functions.firestore
    .document("reservations/{resId}")
    .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();
    // Vérifier que le statut est passé à "cancelled"
    if (after.status !== "cancelled") {
        console.log("❌ Pas de changement vers cancelled, skipping");
        return;
    }
    console.log("🔔 Réservation annulée pour l'utilisateur:", after.userId);
    // Envoyer notification au client spécifique
    try {
        const result = await sendToOneSignalByUserId({
            userId: after.userId,
            title: "❌ Course annulée",
            body: `Votre course de ${after.departure} vers ${after.destination} a été annulée. Vous serez remboursé si un paiement a été effectué.`,
            data: {
                route: `/reservations/${ctx.params.resId}`,
                type: "reservation_cancelled",
                reservationId: ctx.params.resId
            },
        });
        console.log("✅ Notification annulation envoyée:", result);
    }
    catch (error) {
        console.error("❌ Erreur notification annulation:", error);
    }
});
// 🔔 Trigger: réservation annulée → notification aux admins
export const onReservationCancelledAdmin = functions.firestore
    .document("reservations/{resId}")
    .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();
    // Vérifier que le statut est passé à "cancelled"
    if (after.status !== "cancelled") {
        console.log("❌ Pas de changement vers cancelled, skipping admin notification");
        return;
    }
    console.log("🔔 Réservation annulée - notification aux admins");
    // Envoyer notification aux admins
    try {
        const result = await sendToOneSignalByTag({
            title: "❌ Course annulée",
            body: `Course annulée: ${after.departure} → ${after.destination}\nClient: ${after.userName || 'Inconnu'}\nRéservation: ${ctx.params.resId}`,
            data: {
                route: `/reservations/${ctx.params.resId}`,
                type: "reservation_cancelled_admin",
                reservationId: ctx.params.resId
            },
        });
        console.log("✅ Notification annulation admin envoyée:", result);
    }
    catch (error) {
        console.error("❌ Erreur notification annulation admin:", error);
    }
});
// 🔔 Trigger: réservation confirmée → programmer rappels 24h et 1h avant
export const onReservationConfirmedReminders = functions.firestore
    .document("reservations/{resId}")
    .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();
    // Vérifier que le statut est passé à "confirmed"
    if (before.status !== "pending" || after.status !== "confirmed") {
        console.log("❌ Pas de changement pending→confirmed, skipping reminders");
        return;
    }
    // Vérifier qu'on a une date valide
    if (!after.dateISO) {
        console.log("❌ Pas de dateISO, skipping reminders");
        return;
    }
    try {
        const courseDate = new Date(after.dateISO);
        const now = new Date();
        // Vérifier que la course est dans le futur
        if (courseDate <= now) {
            console.log("❌ Course dans le passé, skipping reminders");
            return;
        }
        // Calculer les dates de rappel
        const reminder24h = new Date(courseDate.getTime() - 24 * 60 * 60 * 1000);
        const reminder1h = new Date(courseDate.getTime() - 60 * 60 * 1000);
        // Vérifier que les rappels sont dans le futur
        if (reminder24h > now) {
            console.log("🔔 Programmation rappel 24h avant:", reminder24h.toISOString());
            const result24h = await sendToOneSignalByUserId({
                userId: after.userId,
                title: "⏰ Rappel course dans 24h",
                body: `Votre course de ${after.departure} vers ${after.destination} commence demain !\nHeure: ${courseDate.toLocaleString('fr-FR')}`,
                data: {
                    route: `/reservations/${ctx.params.resId}`,
                    type: "reminder_24h",
                    reservationId: ctx.params.resId
                },
                sendAfterGMT: reminder24h.toISOString()
            });
            console.log("✅ Rappel 24h programmé:", result24h);
        }
        if (reminder1h > now) {
            console.log("🔔 Programmation rappel 1h avant:", reminder1h.toISOString());
            const result1h = await sendToOneSignalByUserId({
                userId: after.userId,
                title: "🚗 Votre course dans 1h !",
                body: `Votre course de ${after.departure} vers ${after.destination} commence dans 1 heure !\nHeure: ${courseDate.toLocaleString('fr-FR')}`,
                data: {
                    route: `/reservations/${ctx.params.resId}`,
                    type: "reminder_1h",
                    reservationId: ctx.params.resId
                },
                sendAfterGMT: reminder1h.toISOString()
            });
            console.log("✅ Rappel 1h programmé:", result1h);
        }
    }
    catch (error) {
        console.error("❌ Erreur programmation rappels:", error);
    }
});
// 🔐 Function pour exposer les clés API de manière sécurisée
export const getApiKeys = functions.https.onCall(async (data, context) => {
    // Vérifier l'authentification
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }
    // Récupération sécurisée des clés depuis la config Firebase
    const mapsAndroidKey = functions.config().google?.maps_android_key;
    const mapsIosKey = functions.config().google?.maps_ios_key;
    const placesWebKey = functions.config().google?.places_web_key;
    const stripePublishableKey = functions.config().stripe?.publishable_key;
    const stripeSecretKey = functions.config().stripe?.secret_key;
    // Vérifier que toutes les clés sont présentes
    if (!mapsAndroidKey || !mapsIosKey || !placesWebKey || !stripePublishableKey || !stripeSecretKey) {
        throw new functions.https.HttpsError('internal', 'Configuration des clés API incomplète');
    }
    return {
        googleMapsAndroidKey: mapsAndroidKey,
        googleMapsIosKey: mapsIosKey,
        googlePlacesWebKey: placesWebKey,
        stripePublishableKey: stripePublishableKey,
        stripeSecretKey: stripeSecretKey,
    };
});
