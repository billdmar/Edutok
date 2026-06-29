# Security

This document describes Edutok's security model, the trade-offs a client-only app
makes, and how to report issues. Edutok is a portfolio project, not a commercial
service — this is written to be honest about what is and isn't protected.

## Reporting a vulnerability

Please open a GitHub issue (or contact the repository owner directly for sensitive
reports). There is no bug bounty.

## Secrets

- API keys (Google Gemini, Unsplash) and the Firebase config live in
  `Edutok/Secrets.swift` and `Edutok/GoogleService-Info.plist`, both of which are
  **gitignored** and supplied per-developer. They have never been committed — CI
  writes non-functional stubs so the project compiles without real credentials.
- **Known limitation:** because Edutok has no backend, the Gemini and Unsplash keys
  are compiled into the app binary and can be extracted by a determined attacker
  (`strings`, reverse engineering). This is inherent to a keyless-backend client.
  The realistic mitigation — and the natural next step if this were productionized —
  is a thin server-side proxy that holds the keys and the app calls instead. The
  4-manager architecture isolates all networking in `TopicManager`/`ImageManager`,
  so swapping in a proxy endpoint is a localized change.

## Firestore security rules

The client SDK writes directly to Firestore. Without rules, any authenticated user
could overwrite another user's profile or post a leaderboard score under someone
else's id. [`firestore.rules`](firestore.rules) closes that:

- **Profiles** (`users/{uid}`): readable by any signed-in user; writable **only by the
  owner** (`request.auth.uid == uid`), with a shape check on the payload.
- **Leaderboards** (`daily_cards_leaderboard`, `daily_topics_leaderboard`): document
  ids are `"<yyyy-MM-dd>_<uid>"`. Reads are open to signed-in users; a write is
  allowed **only when the id's uid segment and the payload `userId` both match the
  caller**, and the `value` is a non-negative integer. This prevents score spoofing
  for other users.
- Everything else is denied by a catch-all rule.

> **Residual gap (documented, not fixed here):** a user can still write an inflated
> score for *their own* entry, because the client is trusted to report its own count.
> Eliminating this requires server-authoritative writes (a Cloud Function that derives
> the score from validated activity). That's noted as future work — the rules here
> close the cross-user spoofing hole, which is the high-severity one.

Deploy (not done automatically — review first):

```bash
firebase deploy --only firestore:rules
```

Validate locally with the Firebase Emulator Suite before deploying.

## Authentication

Edutok signs users in **anonymously** on first launch for frictionless onboarding,
and also supports email/password and phone auth (`FirebaseManager`). Anonymous auth
trades durable identity for zero-friction start; account management (sign-out,
deletion) is available in the in-app Settings screen.

## Transport security

App Transport Security uses **defaults** (TLS 1.2+ with forward secrecy) for all
endpoints — Gemini, Unsplash, and Firebase all support them, so `Info.plist` declares
no ATS exceptions.
