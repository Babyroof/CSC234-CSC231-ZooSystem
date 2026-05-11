// ─── Mocks (must be declared before imports) ─────────────────────────────────

const mockAxiosPost = jest.fn();
const mockAxiosGet = jest.fn();

jest.mock("axios", () => ({
  __esModule: true,
  default: {
    post: mockAxiosPost,
    get: mockAxiosGet,
  },
}));

jest.mock("firebase-functions/params", () => ({
  defineSecret: jest.fn(() => ({ value: () => "skey_test_key" })),
}));

jest.mock("firebase-functions/v2/https", () => {
  class MockHttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  }
  return {
    onCall: (optsOrHandler: any, handler?: Function) => {
      const fn = typeof optsOrHandler === "function" ? optsOrHandler : handler!;
      return { run: (data: any) => fn({ data }) };
    },
    HttpsError: MockHttpsError,
  };
});

jest.mock("firebase-functions/logger", () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

// ─── Import after mocks ───────────────────────────────────────────────────────

import { createPromptPayCharge } from "../omise/createCharge";

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const VALID_CHARGE = {
  id: "chrg_test_123",
  expires_at: "2026-05-10T12:03:00.000Z",
  source: {
    scannable_code: {
      image: { download_uri: "https://cdn.omise.co/qr/test123.png" },
    },
  },
};

const MOCK_QR_BUFFER = Buffer.from("fake-qr-png-data");
const MOCK_QR_BASE64 = MOCK_QR_BUFFER.toString("base64");
const MOCK_IMAGE_RESPONSE = { data: MOCK_QR_BUFFER };

// ─── Tests ────────────────────────────────────────────────────────────────────

describe("createPromptPayCharge", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockAxiosGet.mockResolvedValue(MOCK_IMAGE_RESPONSE);
  });

  it("returns qrCodeBase64, chargeId, expiresAt for valid input", async () => {
    mockAxiosPost.mockResolvedValue({ data: VALID_CHARGE });

    const result = await (createPromptPayCharge as any).run({
      bookingId: "bk_001",
      amount: 270,
    });

    expect(result).toEqual({
      qrCodeBase64: MOCK_QR_BASE64,
      chargeId: "chrg_test_123",
      expiresAt: "2026-05-10T12:03:00.000Z",
    });
    expect(mockAxiosPost).toHaveBeenCalledWith(
      "https://api.omise.co/charges",
      expect.any(URLSearchParams),
      expect.objectContaining({
        auth: { username: "skey_test_key", password: "" },
        timeout: 15000,
      })
    );
  });

  it("throws invalid-argument when amount is 0", async () => {
    await expect(
      (createPromptPayCharge as any).run({ bookingId: "bk_001", amount: 0 })
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockAxiosPost).not.toHaveBeenCalled();
  });

  it("throws invalid-argument when amount is negative", async () => {
    await expect(
      (createPromptPayCharge as any).run({ bookingId: "bk_001", amount: -100 })
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockAxiosPost).not.toHaveBeenCalled();
  });

  it("throws invalid-argument when bookingId is empty string", async () => {
    await expect(
      (createPromptPayCharge as any).run({ bookingId: "", amount: 270 })
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockAxiosPost).not.toHaveBeenCalled();
  });

  it("throws internal when Omise API throws", async () => {
    mockAxiosPost.mockRejectedValue(new Error("Omise network error"));

    await expect(
      (createPromptPayCharge as any).run({ bookingId: "bk_001", amount: 270 })
    ).rejects.toMatchObject({ code: "internal", message: "Omise error: Omise network error" });
  });
});
