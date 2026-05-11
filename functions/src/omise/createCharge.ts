import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import axios from "axios";

const omiseSecretKey = defineSecret("OMISE_SECRET_KEY");

interface CreateChargeData {
  bookingId: string;
  amount: number;
}

interface CreateChargeResult {
  qrCodeBase64: string;
  chargeId: string;
  expiresAt: string | null;
}

export const createPromptPayCharge = onCall(
  { secrets: ["OMISE_SECRET_KEY"], cors: true },
  async (request): Promise<CreateChargeResult> => {
    const data = request.data as CreateChargeData;

    if (!data.bookingId || data.bookingId.trim() === "") {
      throw new HttpsError("invalid-argument", "bookingId is required.");
    }
    if (!data.amount || data.amount <= 0) {
      throw new HttpsError("invalid-argument", "amount must be greater than 0.");
    }

    logger.info("createPromptPayCharge called", {
      bookingId: data.bookingId,
      amount: data.amount,
      secretKeyExists: !!omiseSecretKey.value(),
    });

    const secretKey = omiseSecretKey.value();

    let charge: any;
    try {
      const chargeResponse = await axios.post(
        "https://api.omise.co/charges",
        new URLSearchParams({
          amount: String(data.amount * 100),
          currency: "thb",
          "source[type]": "promptpay",
        }),
        {
          auth: {
            username: secretKey,
            password: "",
          },
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          timeout: 15000,
        }
      );
      charge = chargeResponse.data;
    } catch (error: any) {
      logger.error("Omise charge creation failed", {
        message: error.message,
        code: error.code,
        statusCode: error.response?.status,
        details: error.response?.data || error,
      });
      throw new HttpsError("internal", `Omise error: ${error.message}`);
    }

    logger.info("Omise charge created", { chargeId: charge.id });

    const qrCodeUrl: string | undefined = charge?.source?.scannable_code?.image?.download_uri;
    if (!qrCodeUrl) {
      logger.error("Omise response missing QR URL", { charge });
      throw new HttpsError("internal", "Could not retrieve QR code from Omise.");
    }
    logger.info("QR URL obtained", { qrCodeUrl });

    const imageResponse = await axios.get(qrCodeUrl, {
      responseType: "arraybuffer",
      timeout: 10000,
      auth: {
        username: secretKey,
        password: "",
      },
    });
    const qrCodeBase64 = Buffer.from(imageResponse.data as ArrayBuffer).toString("base64");
    logger.info("QR base64 encoded successfully", { length: qrCodeBase64.length });

    return {
      qrCodeBase64,
      chargeId: charge.id as string,
      expiresAt: (charge.expires_at as string) ?? null,
    };
  }
);
