import * as functions from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

type Reservation = {
  userId?: string;
  status?: "pending" | "confirmed" | "canceled";
  dateISO?: string; // ISO8601
  departure?: string;
  destination?: string;
  userName?: string;
};

type ChatMessage = {
  senderRole?: "user" | "admin";
  senderId?: string;
  text?: string;
};

type RideChatThread = {
  userId?: string;
  reservationId?: string;
  departure?: string;
  destination?: string;
  userName?: string;
};

type SupportThread = {
  userId?: string;
};

// Récupération sécurisée des secrets OneSignal
const APP_ID = functions.config().onesignal.app_id as string;
const REST_KEY = functions.config().onesignal.rest_key as string;

function buildMessagePreview(text?: string, maxLength = 100) {
  if (!text) {
    return "";
  }
  const trimmed = text.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return `${trimmed.slice(0, maxLength - 1)}…`;
}

function composeLines(lines: Array<string | undefined>) {
  return lines.filter(Boolean).join("\n");
}

async function sendToOneSignalByTag(params: {
  title: string;
  body: string;
  data?: Record<string, string>;
  sendAfterGMT?: string;      // "Fri, 24 Oct 2025 16:30:00 GMT" (optionnel)
}) {
  const payload: any = {
    app_id: APP_ID,
    // ✅ Ciblage par tag "role: admin"
    filters: [
      { field: "tag", key: "role", relation: "=", value: "admin" }
    ],
    headings: { fr: params.title, en: params.title },
    contents: { fr: params.body,  en: params.body },
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
async function sendToOneSignalByUserId(params: {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  sendAfterGMT?: string;
}) {
  const payload: any = {
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
    const res = snap.data() as Reservation;
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
      } catch { /* noop */ }
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
    } catch (error) {
      console.error("❌ Erreur OneSignal:", error);
    }
  });

// 🔔 Trigger: réservation confirmée → notification au client
export const onReservationConfirmed = functions.firestore
  .document("reservations/{resId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    
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
    } catch (error) {
      console.error("❌ Erreur notification client:", error);
    }
  });

// 🔔 Trigger: réservation annulée → notification au client
export const onReservationCancelled = functions.firestore
  .document("reservations/{resId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    
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
    } catch (error) {
      console.error("❌ Erreur notification annulation:", error);
    }
  });

// 🔔 Trigger: réservation annulée → notification aux admins
export const onReservationCancelledAdmin = functions.firestore
  .document("reservations/{resId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    
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
    } catch (error) {
      console.error("❌ Erreur notification annulation admin:", error);
    }
  });

// 🔔 Trigger: réservation confirmée → programmer rappels 24h et 1h avant
export const onReservationConfirmedReminders = functions.firestore
  .document("reservations/{resId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    
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

    } catch (error) {
      console.error("❌ Erreur programmation rappels:", error);
    }
  });

export const onRideChatMessageCreate = functions.firestore
  .document("ride_chat_threads/{threadId}/messages/{messageId}")
  .onCreate(async (snap, ctx) => {
    const message = snap.data() as ChatMessage | undefined;
    if (!message) {
      return;
    }

    const senderRole = message.senderRole;
    if (!senderRole) {
      return;
    }

    const text = message.text?.trim();
    if (!text) {
      return;
    }

    if (message.senderId === "admin_auto") {
      return;
    }

    const firestore = getFirestore();
    const threadSnap = await firestore
      .collection("ride_chat_threads")
      .doc(ctx.params.threadId)
      .get();

    if (!threadSnap.exists) {
      return;
    }

    const thread = threadSnap.data() as RideChatThread;

    let departure = thread.departure;
    let destination = thread.destination;
    let clientName = thread.userName;

    if (thread.reservationId) {
      try {
        const reservationSnap = await firestore
          .collection("reservations")
          .doc(thread.reservationId)
          .get();

        if (reservationSnap.exists) {
          const reservation = reservationSnap.data() as Reservation;
          departure = reservation.departure ?? departure;
          destination = reservation.destination ?? destination;
          clientName = (reservation as any).userName ?? clientName;
        }
      } catch (error) {
        console.error("❌ Impossible de récupérer la réservation pour la notif chat:", error);
      }
    }

    const preview = buildMessagePreview(text, 140);
    const client = clientName ?? "Client";
    const itinerary = departure && destination
      ? `${departure} → ${destination}`
      : undefined;
    const adminTitle = itinerary ? `[Course] ${itinerary}` : "[Course] Nouveau message";
    const adminBody = composeLines([
      client ? `Client: ${client}` : undefined,
      itinerary ? `Trajet: ${itinerary}` : undefined,
      preview ? `Msg: ${preview}` : undefined,
    ]);
    const userTitle = itinerary ? `[Course] ${itinerary}` : "[Course] Réponse du chauffeur";
    const userBody = composeLines([
      itinerary ? `Trajet: ${itinerary}` : undefined,
      preview ? `Message chauffeur: ${preview}` : undefined,
    ]);

    if (senderRole === "user") {
      await sendToOneSignalByTag({
        title: adminTitle,
        body: adminBody,
        data: {
          type: "ride_chat",
          threadId: ctx.params.threadId,
          reservationId: thread.reservationId ?? "",
          route: `/ride-chat/${ctx.params.threadId}`,
        },
      });
      return;
    }

    if (senderRole === "admin" && thread.userId) {
      await sendToOneSignalByUserId({
        userId: thread.userId,
        title: userTitle,
        body: userBody,
        data: {
          type: "ride_chat",
          threadId: ctx.params.threadId,
          reservationId: thread.reservationId ?? "",
          route: `/ride-chat/${ctx.params.threadId}`,
        },
      });
    }
  });

export const onSupportChatMessageCreate = functions.firestore
  .document("support_threads/{threadId}/messages/{messageId}")
  .onCreate(async (snap, ctx) => {
    const message = snap.data() as ChatMessage | undefined;
    if (!message) {
      return;
    }

    const senderRole = message.senderRole;
    if (!senderRole) {
      return;
    }

    const text = message.text?.trim();
    if (!text) {
      return;
    }

    if (message.senderId === "admin_auto") {
      return;
    }

    const firestore = getFirestore();
    const threadSnap = await firestore
      .collection("support_threads")
      .doc(ctx.params.threadId)
      .get();

    if (!threadSnap.exists) {
      return;
    }

    const thread = threadSnap.data() as SupportThread;
    const preview = buildMessagePreview(text);

    if (senderRole === "user") {
      await sendToOneSignalByTag({
        title: "[Support] Nouveau message",
        body: preview,
        data: {
          type: "support_chat",
          threadId: ctx.params.threadId,
          route: `/support/${ctx.params.threadId}`,
        },
      });
      return;
    }

    if (senderRole === "admin" && thread.userId) {
      await sendToOneSignalByUserId({
        userId: thread.userId,
        title: "[Support] Réponse admin",
        body: preview,
        data: {
          type: "support_chat",
          threadId: ctx.params.threadId,
          route: `/support/${ctx.params.threadId}`,
        },
      });
    }
  });

// 🔐 Function pour exposer les clés API de manière sécurisée
export const getApiKeys = functions.https.onCall(async (data, context) => {
  // Vérifier l'authentification
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  // Récupération sécurisée des clés depuis la config Firebase
  const mapsAndroidKey = functions.config().google?.maps_android_key as string;
  const mapsIosKey = functions.config().google?.maps_ios_key as string;
  const placesWebKey = functions.config().google?.places_web_key as string;
  const stripePublishableKey = functions.config().stripe?.publishable_key as string;
  const stripeSecretKey = functions.config().stripe?.secret_key as string;

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
