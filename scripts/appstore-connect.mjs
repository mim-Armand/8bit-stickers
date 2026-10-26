#!/usr/bin/env node
// Signs requests in memory using an existing key outside the repository.
import { readFile, stat } from "node:fs/promises";
import { createPrivateKey, sign } from "node:crypto";
import { homedir } from "node:os";
import { pathToFileURL } from "node:url";

export const APP_ID = "1366485724";
const API_ORIGIN = "https://api.appstoreconnect.apple.com";
export const keyId = process.env.ASC_KEY_ID || "TGU8SUW323";
export const issuerId =
  process.env.ASC_ISSUER_ID || "69a6de8c-7516-47e3-e053-5b8c7c11a4d1";
export const keyPath =
  process.env.ASC_PRIVATE_KEY_PATH ||
  `${homedir()}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8`;
let key;
async function token() {
  if (!key) {
    const info = await stat(keyPath);
    if ((info.mode & 0o077) !== 0)
      throw new Error(
        "App Store private key must have owner-only permissions.",
      );
    const bytes = await readFile(keyPath);
    try {
      key = createPrivateKey(bytes);
    } finally {
      bytes.fill(0);
    }
  }
  const now = Math.floor(Date.now() / 1000);
  const encode = (value) =>
    Buffer.from(JSON.stringify(value)).toString("base64url");
  const input = `${encode({ alg: "ES256", kid: keyId, typ: "JWT" })}.${encode({ iss: issuerId, iat: now, exp: now + 300, aud: "appstoreconnect-v1" })}`;
  return `${input}.${sign("sha256", Buffer.from(input), { key, dsaEncoding: "ieee-p1363" }).toString("base64url")}`;
}
export async function api(method, path, body) {
  const url = new URL(path, API_ORIGIN);
  if (url.origin !== API_ORIGIN)
    throw new Error(
      "Refusing to send App Store credentials to another origin.",
    );
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${await token()}`,
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(30_000),
    redirect: "error",
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(
      `App Store API ${method} ${url.pathname}: HTTP ${response.status}`,
    );
    error.status = response.status;
    error.details = (payload.errors || []).map(
      ({ code, title, detail, source }) => ({ code, title, detail, source }),
    );
    throw error;
  }
  return payload;
}
export async function all(path) {
  const values = [];
  do {
    const result = await api("GET", path);
    values.push(...result.data);
    path = result.links?.next;
  } while (path);
  return values;
}
if (import.meta.url === pathToFileURL(process.argv[1] || "").href) {
  const [, , command, path] = process.argv;
  if (command !== "get" || !path?.startsWith("/v")) {
    console.error(
      `Usage: node scripts/appstore-connect.mjs get /v1/apps/${APP_ID}`,
    );
    process.exitCode = 1;
  } else {
    try {
      console.log(JSON.stringify(await api("GET", path), null, 2));
    } catch (error) {
      console.error(
        JSON.stringify({ message: error.message, errors: error.details }),
      );
      process.exitCode = 1;
    }
  }
}
