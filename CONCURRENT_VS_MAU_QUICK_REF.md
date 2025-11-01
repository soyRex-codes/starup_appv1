# Quick Reference: Concurrent vs MAU - 60 Second Version

## TL;DR

**Concurrent Users (50-100)** = How many people online RIGHT NOW
**Monthly Active Users (10,000-30,000)** = Different people in November

**They're not related.** Your app can have 30,000 MAU but break at 100 concurrent.

---

## The Numbers Explained

```
┌──────────────────────────────────────────────────────────┐
│ CONCURRENT USERS (What Breaks First)                     │
├──────────────────────────────────────────────────────────┤
│ • 50-100 users online simultaneously RIGHT NOW           │
│ • Limits: Real-time connections (100 max)               │
│ • When: Peak hour on busy day (Friday 6-9 PM)           │
│ • Current status: AT LIMIT ⚠️                            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ MONTHLY ACTIVE USERS (Rarely the Problem)                │
├──────────────────────────────────────────────────────────┤
│ • 10,000-30,000 different users throughout November     │
│ • Limits: Storage, bandwidth, API rate limits           │
│ • When: Accumulated over entire month                   │
│ • Current status: PLENTY OF HEADROOM ✅                 │
└──────────────────────────────────────────────────────────┘
```

---

## Why You Can Have 30,000 Users But Only Support 100 Concurrent

```
Concurrent Example:
├─ 6 AM: User A opens app
├─ 7 AM: User A closes, User B opens app
├─ 8 AM: User B closes, User C opens app
└─ Result: Only 1 person at a time using each connection

Peak Hour Example:
├─ 6 PM: Users A, B, C, D, E...Z all open app at once
├─ = 26 people × 1 connection each = 26 connections used
├─ 6:05 PM: More people join = 80 connections used
├─ 6:15 PM: Even more people = 100 connections FULL ← BREAKING POINT
└─ User #101 trying to connect: ❌ NO SLOT AVAILABLE
```

**Monthly:** Those 26 people from the example? If they all used the app once in November, they're 26 of your 30,000 MAU. ✅ No problem!

**Concurrency:** If they're ALL online at 6:15 PM? You're hitting your 100 connection limit. ⚠️ Problem!

---

## Impact of Your Typing Indicators

### Currently With Typing:
```
1 user online = 1-2 real-time subscriptions
Capacity: 100 connections ÷ 1.5 = ~66 users
```

### Without Typing Indicators:
```
1 user online = 1 real-time subscription
Capacity: 100 connections ÷ 1 = 100 users
```

**Benefit:** Remove typing indicator → **Support 1.5x more concurrent users**

**Code:** Delete 5 lines from `dm_service.dart` + remove UI widget

**User impact:** No "User is typing..." indicator shown. Life goes on.

---

## What Breaks When

### Concurrent Users Hit 101:
```
❌ User #101 tries to open messaging
   └─ Can't connect (real-time connection limit)
   └─ Messages delay 5-10 seconds
   └─ App feels laggy
   
Solution: Remove typing indicators (→100 max) or upgrade plan (→1000 max)
```

### MAU Hits 30,000:
```
✅ Still works fine
   └─ You have storage for millions of messages
   └─ Bandwidth supports normal usage
   └─ API limits handle the volume
   
Only problem if you hit 100,000 MAU with massive engagement
```

---

## Your Action Plan

| Timeline | Action | Impact |
|----------|--------|--------|
| **This week** | Remove typing indicators | +50% concurrent capacity |
| **When peak hits 80-90** | Upgrade to Team Plan | +10x concurrent capacity |
| **Never urgent** | Worry about MAU | It won't break before you're profitable |

---

## Peak Hour Scenario

```
Friday 6 PM - Your app hits peak usage:

User count timeline:
6:00 PM: 20 users online
6:05 PM: 40 users online  
6:10 PM: 70 users online
6:15 PM: 100 users online ← Real-time limit reached
6:20 PM: 130 users trying online ← 30 USERS CAN'T GET REAL-TIME

Those 30 blocked users:
├─ See messages delayed 5-10 seconds (polling works)
├─ No "typing indicators"
├─ Unread badges update slower
└─ App works but feels sluggish

Your monthly active users:
├─ All 30,000 might eventually use the app
├─ But never all at once
├─ Storage is fine (8 GB can hold millions)
└─ No problem at all
```

---

## The Real Bottleneck

```
Your Real-Time Connection Limit (100):
  = Max concurrent users at peak hour
  
Your Database Storage (8 GB):
  = Can store millions of messages
  
Your Bandwidth (250 GB/month):
  = Can serve normal amount of downloads

What breaks first: The concurrent connection limit during peak hours
What breaks last: Database storage (after 1-2 years of data)
```

---

## Copy-Paste One-Liner

**For explaining to your team:**
> "We can support 30,000 monthly users but only 100 online at the same time. That's a real-time connection limit, not a storage problem. Need to remove typing indicators or upgrade Supabase Team plan before we hit 100 concurrent users during peak hours."

---

## Files To Read

1. **CONCURRENT_VS_MAU_EXPLAINED.md** - Full deep dive (10 min read)
2. **SCALING_IMPACT_MATRIX.md** - What affects what (5 min read)
3. **This file** - Quick reference (2 min read)

---

## Action Items

- [ ] Test peak hour concurrent users (check Supabase dashboard)
- [ ] Remove typing indicators if peak approaches 80 users
- [ ] Plan Team Plan upgrade when peak hits 100 users
- [ ] Monitor storage growth (currently nowhere near 8 GB limit)
