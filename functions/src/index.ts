import * as admin from "firebase-admin";

admin.initializeApp();

export { createPromptPayCharge } from "./omise/createCharge";
export { omiseWebhook }          from "./omise/webhook";
