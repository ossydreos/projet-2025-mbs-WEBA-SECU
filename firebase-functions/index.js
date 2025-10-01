const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialiser Firebase Admin SDK
admin.initializeApp();

// Fonction pour envoyer une notification FCM
exports.sendNotification = functions.https.onRequest(async (req, res) => {
    // Configurer CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        const { token, title, body, data } = req.body;

        if (!token || !title || !body) {
            res.status(400).send('Missing required fields: token, title, body');
            return;
        }

        console.log('🔔 Firebase Function: Envoi notification à', token);

        // Android: notification + data (affichage système + données pour l'app)
        // iOS: APNs via apns.payload.aps.alert
        const message = {
            token: token,
            notification: {
                title: title,
                body: body,
            },
            data: {
                title: title,
                body: body,
                ...(data || {}),
            },
            android: {
                priority: 'high',
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: title,
                            body: body,
                        },
                        sound: 'default',
                    },
                },
            },
        };

        // Envoyer la notification
        const response = await admin.messaging().send(message);

        console.log('🔔 Firebase Function: Notification envoyée avec succès:', response);
        res.status(200).json({
            success: true,
            messageId: response,
            message: 'Notification envoyée avec succès'
        });

    } catch (error) {
        console.error('🔔 Firebase Function: Erreur:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Fonction déclenchée automatiquement quand une nouvelle réservation est créée
exports.onNewReservation = functions.firestore
    .document('reservations/{reservationId}')
    .onCreate(async (snap, context) => {
        try {
            const reservation = snap.data();
            const reservationId = context.params.reservationId;

            console.log('🔔 Firebase Function: Nouvelle réservation détectée:', reservationId);

            // Vérifier si c'est une réservation en attente
            if (reservation.status !== 'pending') {
                console.log('🔔 Firebase Function: Réservation non en attente, ignorée');
                return;
            }

            // Récupérer tous les tokens admin
            const adminTokensSnapshot = await admin.firestore()
                .collection('admin_tokens')
                .get();

            if (adminTokensSnapshot.empty) {
                console.log('🔔 Firebase Function: Aucun token admin trouvé');
                return;
            }

            const adminTokens = adminTokensSnapshot.docs.map(doc => doc.data().token);

            // Message notification + data pour Android; APNs pour iOS
            const clientName = reservation.userName || 'Client';
            const from = reservation.departure || '';
            const to = reservation.destination || '';
            const price = reservation.totalPrice ? `${reservation.totalPrice.toFixed(2)}€` : '0.00€';

            const message = {
                notification: {
                    title: 'Nouvelle réservation',
                    body: `Nouvelle demande de ${clientName}`,
                },
                data: {
                    title: 'Nouvelle réservation',
                    body: `Nouvelle demande de ${clientName}`,
                    type: 'new_reservation',
                    entityType: 'reservation',
                    entityId: reservationId,
                    clientName: clientName,
                    reservationId: reservationId,
                    from: from,
                    to: to,
                    price: price,
                },
                android: {
                    priority: 'high',
                },
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: 'Nouvelle réservation',
                                body: `Nouvelle demande de ${clientName}`,
                            },
                            sound: 'default',
                        },
                    },
                },
                tokens: adminTokens,
            };

            const response = await admin.messaging().sendMulticast(message);

            console.log('🔔 Firebase Function: Notifications envoyées:', response.successCount, 'succès,', response.failureCount, 'échecs');
            if (response.failureCount > 0) {
                console.log('🔔 Firebase Function: Échecs:', response.responses);
            }

        } catch (error) {
            console.error('🔔 Firebase Function: Erreur lors de l\'envoi automatique:', error);
        }
    });

