import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Request, Response } from "express";

interface OmiseWebhookBody {
  key: string;
  data: {
    id: string;
    status: string;
  };
}

export const omiseWebhook = onRequest(
  { cors: true },
  async (req: Request, res: Response): Promise<void> => {
    try {
      const body = req.body as OmiseWebhookBody;

      if (body.key !== "charge.complete") {
        logger.info(`Ignoring webhook event: ${body.key}`);
        res.sendStatus(200);
        return;
      }

      const chargeId = body?.data?.id;
      if (!chargeId) {
        logger.error("Webhook body missing data.id");
        res.sendStatus(200);
        return;
      }

      const db = admin.firestore();
      const snapshot = await db
        .collection("booking")
        .where("chargeId", "==", chargeId)
        .limit(1)
        .get();

      if (snapshot.empty) {
        logger.warn(`No booking found for chargeId: ${chargeId}`);
        res.sendStatus(200);
        return;
      }

      const bookingDoc = snapshot.docs[0];
      await bookingDoc.ref.update({ status: "Done" });

      logger.info(`Booking ${bookingDoc.id} marked Done via chargeId ${chargeId}`);
      res.sendStatus(200);
    } catch (err) {
      logger.error("omiseWebhook error", { message: (err as any)?.message });
      res.sendStatus(200);
    }
  }
);
