// ─── Mocks (must be declared before imports) ─────────────────────────────────

const mockGet = jest.fn();
const mockUpdate = jest.fn();

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: mockGet,
    })),
  })),
}));

jest.mock("firebase-functions/v2/https", () => ({
  onRequest: (handler: Function) => ({ run: handler }),
}));

jest.mock("firebase-functions/logger", () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

// ─── Import after mocks ───────────────────────────────────────────────────────

import { omiseWebhook } from "../omise/webhook";

// ─── Tests ────────────────────────────────────────────────────────────────────

describe("omiseWebhook", () => {
  beforeEach(() => jest.clearAllMocks());

  it("updates booking status to Done when event key is charge.complete", async () => {
    mockUpdate.mockResolvedValue(undefined);
    mockGet.mockResolvedValue({
      empty: false,
      docs: [{ id: "bk_001", ref: { update: mockUpdate } }],
    });

    const req = {
      body: {
        key: "charge.complete",
        data: { id: "chrg_test_123", status: "successful" },
      },
    };
    const res = { sendStatus: jest.fn() };

    await (omiseWebhook as any).run(req, res);

    expect(mockUpdate).toHaveBeenCalledWith({ status: "Done" });
    expect(res.sendStatus).toHaveBeenCalledWith(200);
  });

  it("does not query Firestore when event key is not charge.complete", async () => {
    const req = {
      body: {
        key: "transfer.create",
        data: { id: "trns_123", status: "pending" },
      },
    };
    const res = { sendStatus: jest.fn() };

    await (omiseWebhook as any).run(req, res);

    expect(mockGet).not.toHaveBeenCalled();
    expect(mockUpdate).not.toHaveBeenCalled();
    expect(res.sendStatus).toHaveBeenCalledWith(200);
  });

  it("does not update Firestore when no booking matches chargeId", async () => {
    mockGet.mockResolvedValue({ empty: true, docs: [] });

    const req = {
      body: {
        key: "charge.complete",
        data: { id: "chrg_unknown", status: "successful" },
      },
    };
    const res = { sendStatus: jest.fn() };

    await (omiseWebhook as any).run(req, res);

    expect(mockUpdate).not.toHaveBeenCalled();
    expect(res.sendStatus).toHaveBeenCalledWith(200);
  });

  it("returns 200 after successfully updating booking", async () => {
    mockUpdate.mockResolvedValue(undefined);
    mockGet.mockResolvedValue({
      empty: false,
      docs: [{ id: "bk_001", ref: { update: mockUpdate } }],
    });

    const req = {
      body: {
        key: "charge.complete",
        data: { id: "chrg_test_123", status: "successful" },
      },
    };
    const res = { sendStatus: jest.fn() };

    await (omiseWebhook as any).run(req, res);

    expect(res.sendStatus).toHaveBeenCalledWith(200);
    expect(res.sendStatus).toHaveBeenCalledTimes(1);
  });
});
