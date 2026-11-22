# Caching Patterns: Architecture and Strategy Selection

Guide to cache architecture patterns - the FIRST decision before choosing eviction algorithms.

**Order of decisions**:
1. **Caching Pattern** (this document) - HOW to use cache (write-through, cache-aside, etc.)
2. **Eviction Algorithm** (`caching-strategies.md`) - WHAT to evict when full (LRU, LFU, etc.)

## Overview

**Caching patterns** define the architecture and behavior of your caching layer:
- **When** to write to cache
- **When** to write to database
- **Who** is responsible (application vs cache system)
- **How** to handle consistency

**Eviction algorithms** (LRU, LFU) only matter AFTER you've chosen your caching pattern.

## Decision Tree: Which Caching Pattern?

```
What is your primary operation?

Reads dominate (90%+ reads)?
├─ Yes → Do you need simplicity?
│  ├─ Yes → Cache-Aside (most common) ✅
│  └─ No → Want automatic cache population?
│     └─ Yes → Read-Through
└─ No → Heavy writes?
   ├─ Yes → Can you tolerate data loss?
   │  ├─ Yes → Write-Behind (highest performance)
   │  └─ No → Write-Through (consistency critical)
   └─ No → Balanced read/write?
      └─ Do you want to skip cache for writes?
         ├─ Yes → Write-Around
         └─ No → Write-Through

Need to prevent stampedes?
└─ Add Refresh-Ahead

Need multi-layer caching?
└─ Use combination (e.g., Cache-Aside + Write-Through)
```

## 1. Cache-Aside (Lazy Loading)

### Pattern

**Application manages cache explicitly**. Load data into cache only when needed.

```
READ:
1. Check cache
2. If MISS → fetch from DB → store in cache → return
3. If HIT → return from cache

WRITE:
1. Write to DB
2. Invalidate cache (or update it)
```

### Diagram

```
Application          Cache           Database
    |                  |                 |
    |-- GET key ------>|                 |
    |<--- MISS --------|                 |
    |                  |                 |
    |------------ SELECT * ------------>|
    |<----------- data ---------------- |
    |                  |                 |
    |-- SET key ------>|                 |
    |<--- OK ----------|                 |
    |                  |                 |

On write:
    |-- UPDATE ----------------------->|
    |<--- OK -------------------------|
    |-- DELETE key --->|                |
    |<--- OK ----------|                |
```

### Implementation (Python/FastAPI + Redis)

```python
import redis
import json
from typing import Optional

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

class UserService:
    async def get_user(self, user_id: str) -> Optional[dict]:
        """Cache-Aside read"""
        cache_key = f"user:{user_id}"

        # 1. Try cache first
        cached = r.get(cache_key)
        if cached:
            print("Cache HIT")
            return json.loads(cached)

        # 2. Cache miss - fetch from DB
        print("Cache MISS")
        user = await db.users.find_one({"_id": user_id})

        if user:
            # 3. Store in cache
            r.setex(cache_key, 3600, json.dumps(user))

        return user

    async def update_user(self, user_id: str, data: dict) -> dict:
        """Cache-Aside write - invalidate"""
        cache_key = f"user:{user_id}"

        # 1. Write to database
        updated_user = await db.users.update_one(
            {"_id": user_id},
            {"$set": data}
        )

        # 2. Invalidate cache
        r.delete(cache_key)

        return updated_user
```

### Implementation (TypeScript/Next.js)

```typescript
// lib/cache/userCache.ts
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

export class UserCache {
  private static TTL = 3600; // 1 hour

  static async getUser(userId: string): Promise<User | null> {
    const cacheKey = `user:${userId}`;

    // 1. Try cache first
    const cached = await redis.get(cacheKey);
    if (cached) {
      console.log('Cache HIT');
      return JSON.parse(cached);
    }

    // 2. Cache miss - fetch from DB
    console.log('Cache MISS');
    const user = await db.user.findUnique({
      where: { id: userId }
    });

    if (user) {
      // 3. Store in cache
      await redis.setex(cacheKey, this.TTL, JSON.stringify(user));
    }

    return user;
  }

  static async updateUser(userId: string, data: Partial<User>): Promise<User> {
    const cacheKey = `user:${userId}`;

    // 1. Write to database
    const updatedUser = await db.user.update({
      where: { id: userId },
      data
    });

    // 2. Invalidate cache
    await redis.del(cacheKey);

    return updatedUser;
  }
}
```

### Use Cases

- ✅ **Most common pattern** (default choice)
- ✅ Read-heavy workloads
- ✅ Application needs full control over caching
- ✅ Different data has different caching needs
- ✅ When you understand your access patterns

### Advantages / Disadvantages

**Advantages**:
- Simple and flexible
- Only caches data that's actually accessed (no wasted space)
- Resilient (cache failure doesn't break app)
- Application controls cache logic

**Disadvantages**:
- Initial request is slow (cache miss)
- Cache stampede possible (many requests miss and hit DB)
- Application code handles cache logic (more code)
- Stale data possible if cache not invalidated

### Stampede Prevention

```python
import asyncio
from typing import Optional

# In-flight request tracking
_inflight_requests = {}

async def get_user_with_stampede_protection(user_id: str) -> Optional[dict]:
    """Prevent cache stampede with request coalescing"""
    cache_key = f"user:{user_id}"

    # Try cache
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)

    # Check if request already in-flight
    if user_id in _inflight_requests:
        # Wait for in-flight request to complete
        return await _inflight_requests[user_id]

    # Create future for this request
    future = asyncio.Future()
    _inflight_requests[user_id] = future

    try:
        # Fetch from DB
        user = await db.users.find_one({"_id": user_id})

        if user:
            r.setex(cache_key, 3600, json.dumps(user))

        # Notify waiting requests
        future.set_result(user)
        return user
    finally:
        del _inflight_requests[user_id]
```

## 2. Read-Through

### Pattern

**Cache sits between application and database**. Cache automatically loads data from DB on miss.

```
READ:
1. Check cache
2. If MISS → cache fetches from DB → stores → returns
3. If HIT → return from cache

Application doesn't know about DB - only talks to cache.
```

### Diagram

```
Application          Cache           Database
    |                  |                 |
    |-- GET key ------>|                 |
    |                  |-- (MISS) ------>|
    |                  |    SELECT *     |
    |                  |<--- data -------|
    |                  | (auto store)    |
    |<--- data --------|                 |
```

### Implementation (Python with Cache Abstraction)

```python
from abc import ABC, abstractmethod
from typing import Optional, Callable

class DataSource(ABC):
    """Data source interface for read-through cache"""

    @abstractmethod
    async def load(self, key: str):
        pass

class UserDataSource(DataSource):
    async def load(self, key: str):
        """Load from database"""
        user_id = key.replace("user:", "")
        return await db.users.find_one({"_id": user_id})

class ReadThroughCache:
    def __init__(self, data_source: DataSource):
        self.cache = {}
        self.data_source = data_source

    async def get(self, key: str):
        """Read-through: cache automatically loads on miss"""
        if key in self.cache:
            return self.cache[key]

        # Cache miss - automatically load from data source
        value = await self.data_source.load(key)

        if value:
            self.cache[key] = value

        return value

# Usage
user_cache = ReadThroughCache(UserDataSource())
user = await user_cache.get("user:123")  # Auto-loads if missing
```

### Implementation (TypeScript with Proxy Pattern)

```typescript
interface DataLoader<T> {
  load(key: string): Promise<T | null>;
}

class ReadThroughCache<T> {
  private cache = new Map<string, T>();

  constructor(private loader: DataLoader<T>) {}

  async get(key: string): Promise<T | null> {
    // Check cache
    if (this.cache.has(key)) {
      return this.cache.get(key)!;
    }

    // Cache miss - auto-load
    const value = await this.loader.load(key);

    if (value) {
      this.cache.set(key, value);
    }

    return value;
  }
}

// User loader implementation
class UserLoader implements DataLoader<User> {
  async load(key: string): Promise<User | null> {
    const userId = key.replace('user:', '');
    return await db.user.findUnique({ where: { id: userId } });
  }
}

// Usage
const userCache = new ReadThroughCache(new UserLoader());
const user = await userCache.get('user:123'); // Auto-loads
```

### Use Cases

- ✅ Cleaner separation (app doesn't handle cache logic)
- ✅ Consistent caching behavior across app
- ✅ When using cache libraries (Ehcache, Caffeine)
- ✅ All data loaded the same way

### Advantages / Disadvantages

**Advantages**:
- Application code is simpler (no cache logic)
- Consistent caching behavior
- Cache manages data loading

**Disadvantages**:
- Less flexible (one loading strategy for all)
- Tighter coupling (cache knows about DB)
- Harder to customize per data type

## 3. Write-Through

### Pattern

**Write to cache AND database synchronously**. Both updated before returning.

```
WRITE:
1. Write to cache
2. Write to database (synchronously)
3. Return success (only after both complete)
```

### Diagram

```
Application          Cache           Database
    |                  |                 |
    |-- SET key ------>|                 |
    |                  |-- UPDATE ------>|
    |                  |<--- OK ---------|
    |<--- OK ----------|                 |

(Both updated before response)
```

### Implementation (Python)

```python
class WriteThoughCache:
    async def set_user(self, user_id: str, data: dict) -> dict:
        """Write-through: update cache AND DB synchronously"""
        cache_key = f"user:{user_id}"

        # 1. Write to cache
        r.setex(cache_key, 3600, json.dumps(data))

        # 2. Write to database (synchronously)
        await db.users.update_one(
            {"_id": user_id},
            {"$set": data}
        )

        # 3. Return (both are now consistent)
        return data

    async def get_user(self, user_id: str) -> Optional[dict]:
        """Read is simple - always up-to-date"""
        cache_key = f"user:{user_id}"

        cached = r.get(cache_key)
        if cached:
            return json.loads(cached)

        # Cold start - load from DB
        user = await db.users.find_one({"_id": user_id})
        if user:
            r.setex(cache_key, 3600, json.dumps(user))

        return user
```

### Implementation (TypeScript)

```typescript
class WriteThroughCache {
  async setUser(userId: string, data: Partial<User>): Promise<User> {
    const cacheKey = `user:${userId}`;

    // 1. Update database
    const updatedUser = await db.user.update({
      where: { id: userId },
      data
    });

    // 2. Update cache (synchronously)
    await redis.setex(cacheKey, 3600, JSON.stringify(updatedUser));

    // 3. Return (both consistent)
    return updatedUser;
  }

  async getUser(userId: string): Promise<User | null> {
    const cacheKey = `user:${userId}`;

    // Always up-to-date
    const cached = await redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // Cold start
    const user = await db.user.findUnique({ where: { id: userId } });
    if (user) {
      await redis.setex(cacheKey, 3600, JSON.stringify(user));
    }

    return user;
  }
}
```

### Use Cases

- ✅ **Consistency critical** (finance, inventory, orders)
- ✅ Reads much more frequent than writes
- ✅ Can tolerate slower writes
- ✅ Cache must always be accurate

### Advantages / Disadvantages

**Advantages**:
- Cache and DB always consistent
- No stale data
- Simple mental model (always in sync)

**Disadvantages**:
- Slower writes (wait for both cache and DB)
- Write latency doubled
- Cache write failure can fail entire operation

## 4. Write-Behind (Write-Back)

### Pattern

**Write to cache immediately, write to database asynchronously** (later).

```
WRITE:
1. Write to cache
2. Return success immediately
3. Asynchronously write to database (background)
```

### Diagram

```
Application          Cache           Database
    |                  |                 |
    |-- SET key ------>|                 |
    |<--- OK ----------|                 |
    |  (immediate)     |                 |
    |                  |                 |
    |                  |-- (async) ----->|
    |                  |    UPDATE       |
    |                  |<--- OK ---------|

(DB updated later in background)
```

### Implementation (Python with Queue)

```python
import asyncio
from queue import Queue

# Write queue for async DB updates
write_queue = Queue()

class WriteBehindCache:
    async def set_user(self, user_id: str, data: dict) -> dict:
        """Write-behind: immediate cache, async DB"""
        cache_key = f"user:{user_id}"

        # 1. Write to cache immediately
        r.setex(cache_key, 3600, json.dumps(data))

        # 2. Queue for async DB write
        write_queue.put({
            "key": cache_key,
            "user_id": user_id,
            "data": data
        })

        # 3. Return immediately (DB not updated yet!)
        return data

# Background worker
async def write_behind_worker():
    """Background task that processes queued writes"""
    while True:
        if not write_queue.empty():
            item = write_queue.get()

            try:
                # Write to database
                await db.users.update_one(
                    {"_id": item["user_id"]},
                    {"$set": item["data"]}
                )
                print(f"Async write completed: {item['key']}")
            except Exception as e:
                print(f"Write failed: {e}")
                # Retry logic or dead letter queue

        await asyncio.sleep(0.1)

# Start worker
asyncio.create_task(write_behind_worker())
```

### Implementation (TypeScript with Bull Queue)

```typescript
import Bull from 'bull';

// Redis-backed queue for write-behind
const writeQueue = new Bull('db-writes', process.env.REDIS_URL);

// Process queued writes
writeQueue.process(async (job) => {
  const { userId, data } = job.data;

  await db.user.update({
    where: { id: userId },
    data
  });

  console.log(`Async write completed: user:${userId}`);
});

class WriteBehindCache {
  async setUser(userId: string, data: Partial<User>): Promise<void> {
    const cacheKey = `user:${userId}`;

    // 1. Write to cache immediately
    await redis.setex(cacheKey, 3600, JSON.stringify(data));

    // 2. Queue for async DB write
    await writeQueue.add({
      userId,
      data
    }, {
      attempts: 3,
      backoff: 5000
    });

    // 3. Return immediately
  }
}
```

### Use Cases

- ✅ **Write-heavy workloads** (analytics, logging, metrics)
- ✅ Performance critical (lowest write latency)
- ✅ Can tolerate data loss on crash
- ✅ Batch writes to database
- ✅ Gaming leaderboards, counters, activity feeds

### Advantages / Disadvantages

**Advantages**:
- Fastest write performance
- Can batch DB writes (efficiency)
- Reduces DB load

**Disadvantages**:
- Risk of data loss (cache failure before DB write)
- Complex error handling
- Eventual consistency (cache ≠ DB temporarily)
- Requires retry/dead letter queue

## 5. Write-Around

### Pattern

**Write directly to database, bypass cache**. Invalidate cache on write.

```
WRITE:
1. Write to database
2. Invalidate cache (don't update it)
3. Next read will miss and reload

READ:
1. Check cache
2. If MISS → load from DB → store in cache
```

### Diagram

```
Application          Cache           Database
    |                  |                 |
    |------------ UPDATE -------------->|
    |<----------- OK -------------------|
    |                  |                 |
    |-- DELETE key --->|                 |
    |<--- OK ----------|                 |

(Cache bypassed on write, invalidated)
```

### Implementation (Python)

```python
class WriteAroundCache:
    async def update_user(self, user_id: str, data: dict) -> dict:
        """Write-around: bypass cache, go straight to DB"""
        cache_key = f"user:{user_id}"

        # 1. Write directly to database
        updated_user = await db.users.update_one(
            {"_id": user_id},
            {"$set": data}
        )

        # 2. Invalidate cache (don't update it)
        r.delete(cache_key)

        # Next read will miss and reload from DB
        return updated_user

    async def get_user(self, user_id: str) -> Optional[dict]:
        """Standard cache-aside read"""
        cache_key = f"user:{user_id}"

        cached = r.get(cache_key)
        if cached:
            return json.loads(cached)

        user = await db.users.find_one({"_id": user_id})
        if user:
            r.setex(cache_key, 3600, json.dumps(user))

        return user
```

### Use Cases

- ✅ **Write-once, read-rarely data** (logs, archives)
- ✅ Large objects (don't want to cache immediately)
- ✅ Writes are infrequent
- ✅ Cache space is limited

### Advantages / Disadvantages

**Advantages**:
- Don't cache data that's rarely read
- Prevents cache pollution from writes
- Simple implementation

**Disadvantages**:
- Next read after write is slow (cache miss)
- Read-after-write inconsistency possible (if read happens before cache invalidates)

## 6. Refresh-Ahead

### Pattern

**Proactively refresh cache before expiration** to prevent cache misses.

```
1. Set TTL with buffer (e.g., expire in 50min, refresh at 45min)
2. Background job refreshes popular items before expiration
3. Cache never expires for hot data
```

### Implementation (Python with Background Task)

```python
import asyncio
from datetime import datetime, timedelta

class RefreshAheadCache:
    def __init__(self):
        self.refresh_threshold = 0.9  # Refresh at 90% of TTL
        self.ttl = 3600  # 1 hour

    async def get_user(self, user_id: str) -> Optional[dict]:
        """Get with refresh-ahead logic"""
        cache_key = f"user:{user_id}"

        cached = r.get(cache_key)
        if cached:
            # Check if needs refresh
            ttl_remaining = r.ttl(cache_key)
            if ttl_remaining < self.ttl * (1 - self.refresh_threshold):
                # Trigger async refresh
                asyncio.create_task(self._refresh_in_background(user_id))

            return json.loads(cached)

        # Cold miss - load normally
        user = await db.users.find_one({"_id": user_id})
        if user:
            r.setex(cache_key, self.ttl, json.dumps(user))

        return user

    async def _refresh_in_background(self, user_id: str):
        """Background refresh - prevents cache miss"""
        cache_key = f"user:{user_id}"

        try:
            user = await db.users.find_one({"_id": user_id})
            if user:
                r.setex(cache_key, self.ttl, json.dumps(user))
                print(f"Refreshed ahead: {cache_key}")
        except Exception as e:
            print(f"Refresh failed: {e}")
```

### Implementation (TypeScript with Bull Scheduler)

```typescript
import Bull from 'bull';

const refreshQueue = new Bull('cache-refresh', process.env.REDIS_URL);

// Process refresh jobs
refreshQueue.process(async (job) => {
  const { userId } = job.data;
  const cacheKey = `user:${userId}`;

  // Refresh from DB
  const user = await db.user.findUnique({ where: { id: userId } });

  if (user) {
    await redis.setex(cacheKey, 3600, JSON.stringify(user));
    console.log(`Refreshed ahead: ${cacheKey}`);
  }
});

class RefreshAheadCache {
  private static REFRESH_THRESHOLD = 0.9;
  private static TTL = 3600;

  static async getUser(userId: string): Promise<User | null> {
    const cacheKey = `user:${userId}`;

    const cached = await redis.get(cacheKey);
    if (cached) {
      // Check TTL and schedule refresh if needed
      const ttl = await redis.ttl(cacheKey);

      if (ttl < this.TTL * (1 - this.REFRESH_THRESHOLD)) {
        // Schedule background refresh
        await refreshQueue.add(
          { userId },
          { delay: 1000 } // 1 second delay
        );
      }

      return JSON.parse(cached);
    }

    // Cold miss
    const user = await db.user.findUnique({ where: { id: userId } });
    if (user) {
      await redis.setex(cacheKey, this.TTL, JSON.stringify(user));
    }

    return user;
  }
}
```

### Use Cases

- ✅ **Prevent cache stampedes** on popular items
- ✅ Hot data that must always be fast
- ✅ Predictable access patterns
- ✅ Time-sensitive applications (trading, gaming)

### Advantages / Disadvantages

**Advantages**:
- Eliminates cache misses for hot data
- Smooth performance (no sudden slowdowns)
- Prevents thundering herd

**Disadvantages**:
- Background refresh overhead
- May refresh data that won't be accessed
- Complexity in implementation

## Pattern Comparison Table

| Pattern | Write Speed | Read Speed | Consistency | Complexity | Best For |
|---------|-------------|------------|-------------|------------|----------|
| **Cache-Aside** | Medium | Fast | Eventual | Low | General-purpose (most common) ✅ |
| **Read-Through** | Medium | Fast | Eventual | Medium | Consistent read logic |
| **Write-Through** | Slow | Fast | Strong | Low | Consistency critical |
| **Write-Behind** | Very Fast | Fast | Weak | High | Write-heavy, perf critical |
| **Write-Around** | Medium | Medium | Eventual | Low | Write-once, read-rarely |
| **Refresh-Ahead** | Medium | Very Fast | Eventual | High | Hot data, prevent misses |

## Combining Patterns

Real-world systems often combine patterns:

### Example 1: Cache-Aside + Refresh-Ahead

```python
class HybridCache:
    async def get_user(self, user_id: str) -> Optional[dict]:
        """Cache-aside with refresh-ahead for hot data"""
        cache_key = f"user:{user_id}"

        # Cache-aside read
        cached = r.get(cache_key)
        if cached:
            # Refresh-ahead logic
            ttl_remaining = r.ttl(cache_key)
            if ttl_remaining < 300:  # 5 min remaining
                asyncio.create_task(self._refresh(user_id))

            return json.loads(cached)

        # Load on miss
        user = await db.users.find_one({"_id": user_id})
        if user:
            r.setex(cache_key, 3600, json.dumps(user))

        return user
```

### Example 2: Write-Through for Critical Data + Write-Behind for Analytics

```python
class MultiTierCache:
    async def update_user_profile(self, user_id: str, data: dict):
        """Write-through for critical profile data"""
        cache_key = f"user:{user_id}"

        # Write-through (consistent)
        await db.users.update_one({"_id": user_id}, {"$set": data})
        r.setex(cache_key, 3600, json.dumps(data))

    async def track_user_activity(self, user_id: str, activity: dict):
        """Write-behind for analytics (high volume)"""
        cache_key = f"activity:{user_id}"

        # Write-behind (fast, eventual)
        r.lpush(cache_key, json.dumps(activity))
        activity_queue.put({"user_id": user_id, "activity": activity})
```

## Integration with Eviction Algorithms

**After choosing a pattern, choose an eviction algorithm**:

```python
# 1. Choose pattern: Cache-Aside
class CacheAsideService:
    def __init__(self, cache):
        # 2. Choose eviction: LRU, LFU, etc.
        self.cache = cache  # Could be LRUCache, LFUCache, etc.

    async def get_data(self, key: str):
        # Cache-Aside logic
        cached = self.cache.get(key)
        if cached:
            return cached

        data = await self.fetch_from_source(key)
        self.cache.put(key, data)  # Eviction handled by algorithm
        return data
```

**Pattern = HOW to use cache**
**Algorithm = WHAT to evict**

See `caching-strategies.md` for eviction algorithms (LRU, LFU, ARC, etc.).

## Integration with Architecture Principles

### SRP (Single Responsibility Principle)

**Separate cache pattern from business logic**:

```typescript
// ❌ Bad - business logic + cache pattern mixed
class OrderService {
  async createOrder(order: Order): Promise<Order> {
    // Business logic
    const validated = this.validateOrder(order);
    const created = await db.order.create({ data: validated });

    // Cache logic mixed in
    await redis.setex(`order:${created.id}`, 3600, JSON.stringify(created));
    await db.order.create({ data: created }); // Write-through

    return created;
  }
}

// ✅ Good - separated
class OrderService {
  async createOrder(order: Order): Promise<Order> {
    const validated = this.validateOrder(order);
    return await db.order.create({ data: validated });
  }
}

class CachedOrderService {
  constructor(
    private orderService: OrderService,
    private cache: WriteThroughCache
  ) {}

  async createOrder(order: Order): Promise<Order> {
    const created = await this.orderService.createOrder(order);
    await this.cache.set(`order:${created.id}`, created);
    return created;
  }
}
```

### YAGNI

**Don't add cache patterns prematurely**:

```python
# ✅ Start simple
class UserService:
    async def get_user(self, user_id: str):
        return await db.users.find_one({"_id": user_id})

# Then, AFTER profiling shows it's slow:
# 1. Add Cache-Aside
# 2. Measure hit rate
# 3. If stampedes occur, add Refresh-Ahead
# 4. If still slow, consider Read-Through

# Don't start with complex Write-Behind + Refresh-Ahead!
```

## Checklist: Choosing Cache Pattern

- [ ] Read-heavy (90%+ reads)?
  - → Consider Cache-Aside or Read-Through
- [ ] Write-heavy?
  - → Consider Write-Behind
- [ ] Consistency critical?
  - → Must use Write-Through
- [ ] Can tolerate data loss?
  - → Write-Behind is fastest
- [ ] Need simplicity?
  - → Cache-Aside (most common)
- [ ] Hot data must never miss?
  - → Add Refresh-Ahead
- [ ] Large objects, write-once?
  - → Write-Around

**Default recommendation**: Start with **Cache-Aside** (lazy loading), it's the safest and most flexible.

## Cache Invalidation Strategies

**Cache invalidation** removes or marks cache entries as invalid when underlying data changes. Unlike eviction (driven by capacity), invalidation is driven by data changes to maintain consistency.

> "There are only two hard things in Computer Science: cache invalidation and naming things." — Phil Karlton

### 1. Time-Based Invalidation (TTL)

**Cache entries expire after a fixed time period**.

```python
# Automatic expiration
r.setex("user:123", 3600, json.dumps(user))  # Expires in 1 hour
```

**Characteristics**:
- Simple to implement
- Guarantees data freshness
- May invalidate entries that haven't changed
- Good when data staleness is predictable

**Use cases**:
- API responses with known update frequency
- Session data
- Data that changes periodically

### 2. Event-Based Invalidation

**Cache entries invalidated when specific events occur** (data updates/deletes).

```python
class EventBasedCache:
    async def update_user(self, user_id: str, data: dict):
        # Update DB
        await db.users.update_one({"_id": user_id}, {"$set": data})

        # Event: invalidate all related caches
        await self.invalidate_user_caches(user_id)

    async def invalidate_user_caches(self, user_id: str):
        """Invalidate all caches related to this user"""
        await redis.delete(f"user:{user_id}")
        await redis.delete(f"user:{user_id}:profile")
        await redis.delete(f"user:{user_id}:settings")
        await redis.delete(f"user:{user_id}:permissions")
```

**Characteristics**:
- Maintains better consistency
- Requires tracking dependencies
- More complex than TTL
- Invalidates only when needed

**Use cases**:
- Critical data consistency (orders, inventory)
- Complex data relationships
- When staleness is unacceptable

### 3. Manual Invalidation

**Cache entries explicitly invalidated by application code or administrators**.

```python
# Admin API endpoint for cache management
@app.post("/admin/cache/invalidate")
async def invalidate_cache(pattern: str):
    """Manually invalidate caches matching pattern"""
    keys = r.keys(pattern)
    if keys:
        r.delete(*keys)
    return {"invalidated": len(keys)}

# Usage: POST /admin/cache/invalidate?pattern=user:*
```

**Characteristics**:
- Full control
- Good for debugging
- Requires careful management
- Can be error-prone

**Use cases**:
- Debugging cache issues
- Emergency invalidation
- One-time data migrations
- Administrative operations

### 4. Tag-Based Invalidation

**Cache entries tagged with metadata**, invalidation occurs by tag.

```python
class TaggedCache:
    async def set_with_tags(self, key: str, value: any, tags: list[str]):
        """Set cache entry with tags"""
        # Store value
        r.setex(key, 3600, json.dumps(value))

        # Store tags mapping
        for tag in tags:
            r.sadd(f"tag:{tag}", key)

    async def invalidate_by_tag(self, tag: str):
        """Invalidate all entries with this tag"""
        # Get all keys with this tag
        keys = r.smembers(f"tag:{tag}")

        if keys:
            # Delete all keys
            r.delete(*keys)
            # Delete tag set
            r.delete(f"tag:{tag}")

        return len(keys)

# Usage
await cache.set_with_tags("post:123", post_data, tags=["user:456", "category:tech"])
await cache.set_with_tags("post:124", post_data, tags=["user:456", "category:tech"])

# Invalidate all posts by user 456
await cache.invalidate_by_tag("user:456")  # Invalidates both posts
```

**Characteristics**:
- Invalidate multiple related entries at once
- Useful for hierarchical data
- Requires tag management
- More memory overhead (storing tag mappings)

**Use cases**:
- Invalidating all user's data
- Clearing category caches
- Hierarchical relationships
- Multi-tenant applications

### 5. Write-Through Invalidation Pattern

**Combined with write-through pattern**, automatically invalidate on write.

```python
class WriteInvalidateCache:
    async def update_user(self, user_id: str, data: dict):
        """Update DB and invalidate dependent caches"""
        # 1. Update database
        await db.users.update_one({"_id": user_id}, {"$set": data})

        # 2. Update primary cache
        await redis.setex(f"user:{user_id}", 3600, json.dumps(data))

        # 3. Invalidate dependent caches
        await self.invalidate_dependent_caches(user_id)

    async def invalidate_dependent_caches(self, user_id: str):
        """Invalidate caches that depend on user data"""
        # Invalidate aggregated views
        await redis.delete(f"user:{user_id}:dashboard")
        await redis.delete(f"user:{user_id}:stats")

        # Invalidate list caches containing this user
        await redis.delete("users:all")
        await redis.delete("users:active")
```

### Cache Invalidation Decision Tree

```
How often does data change?

Frequently (< 1 minute)?
├─ No cache or very short TTL
└─ Predictably (hourly, daily)?
   ├─ Yes → Time-Based (TTL)
   └─ No → Unpredictably?
      ├─ Yes → Event-Based Invalidation
      └─ No → Do you need to invalidate related data?
         ├─ Yes → Tag-Based Invalidation
         └─ No → Event-Based or Manual

Is consistency critical?
├─ Yes → Event-Based (immediate invalidation)
└─ No → Time-Based (simpler)
```

### Invalidation Anti-Patterns

| Anti-Pattern | Why Bad | Fix |
|--------------|---------|-----|
| No invalidation strategy | Stale data bugs | Add TTL or event-based |
| TTL too long | Stale data persists | Shorter TTL or event-based |
| Invalidate too aggressively | Poor hit rate | Invalidate only what changed |
| Forget dependent caches | Inconsistent state | Track dependencies, use tags |
| Manual invalidation only | Human error, forgotten | Automate with events |

## Common Anti-Patterns

| Anti-Pattern | Why Bad | Fix |
|--------------|---------|-----|
| Write-Through everywhere | Slow writes unnecessarily | Use Cache-Aside for non-critical data |
| Write-Behind without retry | Data loss on failure | Add dead letter queue, retries |
| No invalidation strategy | Stale data bugs | Use event-based or TTL invalidation |
| Mixing patterns inconsistently | Confusing, bugs | Standardize per data type |
| Cache-Aside without stampede protection | DB overload on popular items | Add refresh-ahead or locking |

## See Also

- `caching-strategies.md` - Eviction algorithms (LRU, LFU, etc.) - choose AFTER pattern
- `principes-architectures.md` - Architecture principles (YAGNI, SRP)
- `tensions-architecturales.md` - Performance vs other principles

## Summary

**Decision order**:
1. **Choose pattern** (this document) - HOW to use cache
   - Cache-Aside (most common, flexible) ✅
   - Write-Through (consistency)
   - Write-Behind (performance)
   - Read-Through (clean separation)
   - Write-Around (rare reads)
   - Refresh-Ahead (prevent misses)

2. **Choose eviction algorithm** (see `caching-strategies.md`) - WHAT to evict
   - LRU (default)
   - LFU (frequency matters)
   - TTL (time-based)
   - etc.

**Default recommendation**: **Cache-Aside** pattern + **LRU** eviction. Measure, then optimize.
