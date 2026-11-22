# Caching Tools: From Server to Client

Comprehensive guide to modern caching tools and when to use each.

**Prerequisites**: Read `caching-patterns.md` and `caching-strategies.md` first.

**Decision order**:
1. **Pattern** (`caching-patterns.md`) - HOW to use cache
2. **Algorithm** (`caching-strategies.md`) - WHAT to evict
3. **Tool** (this document) - WHERE to cache (server vs client, in-memory vs persistent)

## Overview

**Caching tools** differ in:
- **Location**: Server-side vs Client-side
- **Scope**: Cross-user vs Per-user
- **Persistence**: Volatile (in-memory) vs Durable (disk)
- **Network**: Requires network vs Embedded in app

## Decision Tree: Which Caching Tool?

```
Where does caching happen?

Server-side (backend)?
├─ Need distributed caching across multiple servers?
│  ├─ Yes → Redis (networked, shared state)
│  └─ No → In-memory cache (simpler, single instance)
└─ Client-side (browser/app)?
   ├─ Caching API responses?
   │  └─ TanStack Query (network state management)
   └─ Need structured data storage?
      ├─ Large datasets (100+ MB)?
      │  └─ IndexedDB (browser NoSQL DB)
      └─ Small settings/flags?
         └─ localStorage (simple key-value, 5-10MB)

Need reactive client-side database?
└─ TanStack DB (live queries, relations, optimistic mutations)
```

## 1. Redis: Server-Side Powerhouse

### What is Redis?

**Redis** is a real in-memory data store that runs as its own server process.

**Key characteristics**:
- **Runs as separate server** (not embedded in app)
- **Stores data across requests and users**
- **Data persists** until explicitly expired or deleted
- **Networked service** accessible via TCP
- **Multi-user shared state**

### When to Use Redis

✅ **Use Redis for**:
- Server-side caching to reduce database load
- Session storage (shared across app instances)
- Cross-request caching in distributed systems
- Message queues and pub/sub
- Rate limiting
- Real-time analytics

❌ **Don't use Redis for**:
- Client-side caching (use TanStack Query)
- Single-user data (use localStorage or IndexedDB)
- Data that doesn't need to be shared

### Redis vs In-App Cache

| Feature | Redis | In-App Cache (Python dict/JS Map) |
|---------|-------|-----------------------------------|
| **Location** | External server | Same process as app |
| **Scope** | Cross-user, cross-instance | Single instance only |
| **Persistence** | Can persist to disk | Lost on restart |
| **Network** | Requires TCP connection | No network |
| **Performance** | Network latency (~1ms) | Direct memory access (~μs) |
| **Complexity** | Higher (separate service) | Lower (just code) |

**Rule of thumb**: Use Redis for multi-instance deployments, in-app cache for single-instance.

### Implementation (Python/FastAPI)

```python
import redis
import json
from fastapi import FastAPI

app = FastAPI()
r = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Configure eviction policy
r.config_set('maxmemory', '100mb')
r.config_set('maxmemory-policy', 'allkeys-lru')

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    cache_key = f"user:{user_id}"

    # Try cache
    cached = r.get(cache_key)
    if cached:
        return {"data": json.loads(cached), "cache": "HIT"}

    # Fetch from DB
    user = await db.users.find_one({"_id": user_id})

    # Cache for 1 hour
    r.setex(cache_key, 3600, json.dumps(user))

    return {"data": user, "cache": "MISS"}
```

### Implementation (TypeScript/Next.js)

```typescript
// lib/redis.ts
import Redis from 'ioredis';

export const redis = new Redis(process.env.REDIS_URL);

// Set eviction policy on initialization
await redis.config('SET', 'maxmemory-policy', 'allkeys-lru');

// lib/cache.ts
export async function withRedisCache<T>(
  key: string,
  fetchFn: () => Promise<T>,
  ttl: number = 3600
): Promise<T> {
  // Check cache
  const cached = await redis.get(key);
  if (cached) {
    return JSON.parse(cached);
  }

  // Fetch data
  const data = await fetchFn();

  // Cache result
  await redis.setex(key, ttl, JSON.stringify(data));

  return data;
}

// Usage in API route
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { withRedisCache } from '@/lib/cache';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = await withRedisCache(
    `user:${params.id}`,
    () => db.user.findUnique({ where: { id: params.id } }),
    3600
  );

  return NextResponse.json(user);
}
```

### Redis Data Structures

Redis isn't just key-value:

```python
# Strings (simple cache)
r.set('user:123', json.dumps(user))
r.get('user:123')

# Lists (queues, feeds)
r.lpush('notifications:user:123', json.dumps(notif))
r.lrange('notifications:user:123', 0, 9)  # Get 10 most recent

# Sets (unique items, tags)
r.sadd('user:123:interests', 'python', 'ai', 'caching')
r.smembers('user:123:interests')

# Sorted Sets (leaderboards, rankings)
r.zadd('leaderboard', {'player1': 100, 'player2': 150})
r.zrevrange('leaderboard', 0, 9, withscores=True)  # Top 10

# Hashes (object fields)
r.hset('user:123', mapping={'name': 'John', 'email': 'john@example.com'})
r.hgetall('user:123')
```

## 2. TanStack Query (React Query): Client-Side API Caching

### What is TanStack Query?

**TanStack Query** runs in your app's memory (client-side) and caches API responses.

**Key characteristics**:
- **Runs in app memory**, not a separate server
- **Stores data per user session**
- **Data is ephemeral** (tied to app lifetime)
- **Can use localStorage/sessionStorage** for persistence (~5-10MB)
- **Or IndexedDB** for larger datasets

### When to Use TanStack Query

✅ **Use TanStack Query for**:
- Client-side caching of API calls
- Avoiding redundant fetches during navigation
- Managing loading, error, and retry states
- Automatic refetching and cache invalidation
- Optimistic UI updates

❌ **Don't use TanStack Query for**:
- Server-side caching (use Redis)
- Cross-user data sharing
- Large local databases (use TanStack DB or IndexedDB directly)

### TanStack Query vs Redis

| Feature | TanStack Query | Redis |
|---------|----------------|-------|
| **Location** | Client-side (browser) | Server-side |
| **Scope** | Per-user session | Cross-user |
| **Persistence** | Session lifetime (or localStorage) | Until expired/deleted |
| **Network** | No (embedded in app) | Yes (TCP) |
| **Best For** | Caching API responses in browser | Server-side shared cache |

**TL;DR**: Redis speeds up server DB queries. TanStack Query speeds up reusing data already fetched in the browser.

### Implementation (React)

```typescript
// hooks/useUser.ts
import { useQuery } from '@tanstack/react-query';

export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetch(`/api/users/${userId}`).then(res => res.json()),
    staleTime: 5 * 60 * 1000, // 5 minutes (data considered fresh)
    cacheTime: 10 * 60 * 1000, // 10 minutes (keep in cache)
    // TanStack Query uses LRU internally for cache management
  });
}

// components/UserProfile.tsx
export function UserProfile({ userId }: { userId: string }) {
  const { data: user, isLoading, error } = useUser(userId);

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return <div>{user.name}</div>;
}
```

### Cache Invalidation with TanStack Query

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { userId: string; updates: Partial<User> }) =>
      fetch(`/api/users/${data.userId}`, {
        method: 'PATCH',
        body: JSON.stringify(data.updates)
      }).then(res => res.json()),

    onSuccess: (data, variables) => {
      // Invalidate cache - refetch on next access
      queryClient.invalidateQueries({ queryKey: ['user', variables.userId] });

      // Or update cache directly (optimistic)
      queryClient.setQueryData(['user', variables.userId], data);
    }
  });
}
```

### With React 19 + Server Components

**Client Components**: Caches API results in browser for that user session
**Server Components**: Only lasts for single request, avoiding duplicate fetches within render

```typescript
// app/users/[id]/page.tsx (Server Component)
async function UserPage({ params }: { params: { id: string } }) {
  // Fetched on server, no TanStack Query needed
  const user = await db.user.findUnique({ where: { id: params.id } });

  return (
    <div>
      <h1>{user.name}</h1>
      {/* Client component with TanStack Query for mutations */}
      <UserActions userId={user.id} />
    </div>
  );
}

// components/UserActions.tsx (Client Component)
'use client'

export function UserActions({ userId }: { userId: string }) {
  const updateUser = useUpdateUser();

  return (
    <button onClick={() => updateUser.mutate({ userId, updates: {...} })}>
      Update
    </button>
  );
}
```

## 3. TanStack DB: Reactive Client-Side Database

### What is TanStack DB?

**TanStack DB** is a client-side embedded database layer extending TanStack Query.

**Key features**:
- **Collections**: Local, typed sets of objects (normalized tables)
- **Live Queries**: Reactive queries updating in <1ms
- **Optimistic Mutations**: Instant UI updates while syncing
- **Transactions**: Rollback capabilities
- **Entirely client-side**: In-memory or localStorage/IndexedDB

### When to Use TanStack DB

✅ **Use TanStack DB for**:
- Complex client-side relationships
- SQL-like queries locally
- Real-time local UI updates
- Combining multiple data sources into unified graph
- Apps with structured, relational data

❌ **Don't use TanStack DB for**:
- Simple apps (just use useState)
- Small settings (use localStorage)
- Large-scale offline-first without tuning

### TanStack DB vs localStorage

| Feature | TanStack DB | localStorage |
|---------|-------------|--------------|
| **Speed** | In-memory, <1ms queries | Synchronous, not optimized |
| **Data Shape** | Typed objects, collections, relations | Strings only (manual JSON) |
| **Reactivity** | Built-in live queries | None (manual tracking) |
| **Queries** | Indexed, filtered, sorted, paginated | Fetch entire object/array, filter manually |
| **Mutations** | Optimistic, rollbacks, transactions | Manual overwrite |
| **Persistence** | In-memory (can persist to localStorage/IndexedDB) | Survives reloads |

**When localStorage makes sense**: Small settings or flags across reloads (`theme=dark`, `rememberMe=true`)

**When TanStack DB makes sense**: Structured data, live UI updates, fast client-side queries (10k+ items)

### Implementation

```typescript
import { createDB, defineCollection } from '@tanstack/db';

// Define collections (like SQL tables)
const usersCollection = defineCollection({
  name: 'users',
  schema: {
    id: 'string',
    name: 'string',
    email: 'string'
  }
});

const postsCollection = defineCollection({
  name: 'posts',
  schema: {
    id: 'string',
    title: 'string',
    authorId: 'string' // Foreign key
  }
});

// Create database
const db = createDB({
  collections: [usersCollection, postsCollection]
});

// Live query (auto-updates UI)
function UserPosts({ userId }: { userId: string }) {
  const posts = db.posts.useLiveQuery({
    where: { authorId: userId },
    orderBy: { createdAt: 'desc' }
  });

  return (
    <div>
      {posts.map(post => (
        <div key={post.id}>{post.title}</div>
      ))}
    </div>
  );
}

// Optimistic mutation
async function createPost(title: string) {
  // Instant UI update
  const tempId = crypto.randomUUID();
  db.posts.insert({ id: tempId, title, authorId: currentUserId });

  try {
    // Sync to server
    const created = await fetch('/api/posts', {
      method: 'POST',
      body: JSON.stringify({ title })
    }).then(r => r.json());

    // Replace temp with real
    db.posts.update({ where: { id: tempId }, data: { id: created.id } });
  } catch (error) {
    // Rollback on error
    db.posts.delete({ where: { id: tempId } });
  }
}
```

### TanStack DB Limitations

- Very new (early versions)
- Not standalone storage - needs persistence layer
- Bundle size larger than basic state management
- Learning curve (SQL-like relational model)
- SSR & server components: persistence strategies evolving

## 4. IndexedDB: Browser-Based Persistence

### What is IndexedDB?

**IndexedDB** is a built-in browser NoSQL database for large datasets.

**Key characteristics**:
- **Built-in browser database**
- **Hundreds of MBs** storage (vs ~5-10MB for localStorage)
- **Asynchronous** (non-blocking)
- **Stores structured data** (objects, arrays, blobs)
- **Great for offline-first apps**

### When to Use IndexedDB

✅ **Use IndexedDB for**:
- Large datasets locally (100+ MB)
- Offline caching
- Complex data structures
- TanStack DB persistence layer

❌ **Don't use IndexedDB for**:
- Small settings (use localStorage)
- Simple key-value (localStorage simpler)
- Server-side storage (use database)

### IndexedDB vs localStorage

| Feature | IndexedDB | localStorage |
|---------|-----------|--------------|
| **Max Storage** | Hundreds of MBs | ~5-10 MB |
| **Data Format** | Objects, arrays, blobs | Strings only |
| **Performance** | Async, non-blocking | Sync, blocks main thread |
| **Best For** | Large datasets, offline caching | Small settings, flags |

**Browser Limits**:
- **Chrome/Edge/Firefox**: ~10 MB localStorage, unlimited* IndexedDB
- **Safari (macOS)**: ~5 MB localStorage
- **Safari (iOS)**: ~5 MB localStorage

*IndexedDB quota varies by browser and disk space

### Implementation (Vanilla JS)

```javascript
// Open database
const request = indexedDB.open('MyAppDB', 1);

request.onupgradeneeded = (event) => {
  const db = event.target.result;

  // Create object store (like a table)
  if (!db.objectStoreNames.contains('users')) {
    const objectStore = db.createObjectStore('users', { keyPath: 'id' });
    objectStore.createIndex('email', 'email', { unique: true });
  }
};

request.onsuccess = (event) => {
  const db = event.target.result;

  // Write
  const transaction = db.transaction(['users'], 'readwrite');
  const objectStore = transaction.objectStore('users');
  objectStore.add({ id: '123', name: 'John', email: 'john@example.com' });

  // Read
  const getRequest = objectStore.get('123');
  getRequest.onsuccess = () => {
    console.log(getRequest.result);
  };
};
```

### Implementation (with idb library - easier)

```typescript
import { openDB } from 'idb';

const db = await openDB('MyAppDB', 1, {
  upgrade(db) {
    const store = db.createObjectStore('users', { keyPath: 'id' });
    store.createIndex('email', 'email', { unique: true });
  }
});

// Write
await db.put('users', { id: '123', name: 'John', email: 'john@example.com' });

// Read
const user = await db.get('users', '123');

// Query by index
const userByEmail = await db.getFromIndex('users', 'email', 'john@example.com');

// Get all
const allUsers = await db.getAll('users');
```

## 5. localStorage: Simple Persistent Storage

### What is localStorage?

**localStorage** is a synchronous key-value store built into browsers.

**Key characteristics**:
- **~5-10 MB** per origin
- **Strings only** (manual JSON serialization)
- **Synchronous** (blocks main thread)
- **Survives page reloads**
- **No expiration** (manual cleanup)

### When to Use localStorage

✅ **Use localStorage for**:
- Small settings/preferences
- Simple flags (`theme`, `locale`, `rememberMe`)
- Persist form data
- Simple client-side state

❌ **Don't use localStorage for**:
- Large datasets (use IndexedDB)
- Structured queries (use TanStack DB)
- Fast reactivity (use TanStack Query/DB)

### Implementation

```typescript
// Simple key-value
localStorage.setItem('theme', 'dark');
const theme = localStorage.getItem('theme');

// Objects (manual JSON)
const user = { id: '123', name: 'John' };
localStorage.setItem('user', JSON.stringify(user));
const storedUser = JSON.parse(localStorage.getItem('user')!);

// Type-safe wrapper
class TypedLocalStorage {
  static set<T>(key: string, value: T): void {
    localStorage.setItem(key, JSON.stringify(value));
  }

  static get<T>(key: string): T | null {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  }

  static remove(key: string): void {
    localStorage.removeItem(key);
  }
}

// Usage
TypedLocalStorage.set('user', { id: '123', name: 'John' });
const user = TypedLocalStorage.get<User>('user');
```

## Tool Comparison Matrix

| Tool | Location | Scope | Persistence | Max Size | Reactive | Best For |
|------|----------|-------|-------------|----------|----------|----------|
| **Redis** | Server | Cross-user | Durable (optional) | GBs | No | Server-side cache, shared state |
| **TanStack Query** | Client | Per-user | Session | ~100MB | Yes | API response caching |
| **TanStack DB** | Client | Per-user | Optional | ~100MB+ | Yes | Structured local data, live queries |
| **IndexedDB** | Client | Per-user | Durable | 100s MB | No | Large offline datasets |
| **localStorage** | Client | Per-user | Durable | 5-10 MB | No | Simple settings/flags |

## Multi-Layer Caching Strategy

**Real-world apps use multiple layers**:

```
User Request
    ↓
1. TanStack Query (client-side)
   ├─ HIT → Return (fastest)
   └─ MISS ↓
2. API Request to Server
    ↓
3. Redis (server-side)
   ├─ HIT → Return
   └─ MISS ↓
4. Database Query
   └─ Cache in Redis → Return
```

**Example implementation**:

```typescript
// Client-side (TanStack Query)
function useProduct(productId: string) {
  return useQuery({
    queryKey: ['product', productId],
    queryFn: () => fetch(`/api/products/${productId}`).then(r => r.json()),
    staleTime: 5 * 60 * 1000 // 5 min
  });
}

// Server-side API (Redis + DB)
// app/api/products/[id]/route.ts
export async function GET(req, { params }) {
  const { id } = params;

  // Check Redis
  const cached = await redis.get(`product:${id}`);
  if (cached) {
    return NextResponse.json(JSON.parse(cached), {
      headers: { 'X-Cache': 'HIT' }
    });
  }

  // Query DB
  const product = await db.product.findUnique({ where: { id } });

  // Cache in Redis (1 hour)
  await redis.setex(`product:${id}`, 3600, JSON.stringify(product));

  return NextResponse.json(product, {
    headers: { 'X-Cache': 'MISS' }
  });
}
```

## Integration with Architecture Principles

### YAGNI

**Don't add tools prematurely**:

```
Start: Just fetch from API
  ↓ Slow? Profile first!
Add: TanStack Query (client-side)
  ↓ Still slow? Server bottleneck?
Add: Redis (server-side)
  ↓ Need offline? Large data?
Add: IndexedDB

Don't start with all layers!
```

### SRP

**Separate concerns by layer**:

```typescript
// ❌ Bad - mixed responsibilities
async function getProduct(id: string) {
  // Client cache logic
  const clientCached = localCache.get(id);
  if (clientCached) return clientCached;

  // API call
  const serverCached = await fetch(`/api/${id}`);
  // Redis logic mixed in...
}

// ✅ Good - separated layers
// Client: TanStack Query handles client cache
// Server: API route handles Redis cache
// DB: Repository handles DB access
```

## Checklist: Choosing Cache Tool

- [ ] Is this server-side or client-side caching?
- [ ] Is data shared across users (server) or per-user (client)?
- [ ] How much data? (<10MB = localStorage, >10MB = IndexedDB)
- [ ] Need persistence across reloads?
- [ ] Need reactivity/live updates?
- [ ] Simple settings or complex queries?

**Default recommendations**:
- **Server cache**: Start with Redis (or in-memory for single instance)
- **Client API cache**: TanStack Query
- **Client settings**: localStorage
- **Client large data**: IndexedDB (or TanStack DB if need queries)

## See Also

- `caching-patterns.md` - HOW to use cache (write-through, cache-aside, etc.)
- `caching-strategies.md` - WHAT to evict (LRU, LFU, etc.)
- Redis docs: https://redis.io/docs/
- TanStack Query: https://tanstack.com/query/latest
- TanStack DB: https://tanstack.com/db/latest
- IndexedDB API: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API

## Summary

**Tool selection by layer**:

**Server-Side**:
- **Redis** - Distributed, shared cache (most common)
- **In-memory** - Single instance, simpler

**Client-Side**:
- **TanStack Query** - API response caching (default choice)
- **TanStack DB** - Structured data, live queries, relations
- **IndexedDB** - Large datasets, offline-first
- **localStorage** - Simple settings, flags

**Key principle**: Start simple, add complexity only when measured performance issues demand it. Most apps need: TanStack Query (client) + Redis (server).
