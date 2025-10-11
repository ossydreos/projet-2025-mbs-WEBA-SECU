import * as functions from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

type Reservation = {
  userId?: string;
  status?: "pending" | "confirmed" | "canceled";
  dateISO?: string; // ISO8601
};

// Récupération sécurisée des secrets OneSignal
const APP_ID = functions.config().onesignal.app_id as string;
const REST_KEY = functions.config().onesignal.rest_key as string;

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
}) {
  const payload: any = {
    app_id: APP_ID,
    // ✅ Ciblage par external_user_id (userId du client)
    include_external_user_ids: [params.userId],
    headings: { fr: params.title, en: params.title },
    contents: { fr: params.body, en: params.body },
    data: params.data ?? {},
  };

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
