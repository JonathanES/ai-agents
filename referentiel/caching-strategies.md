# Caching Eviction Algorithms: What to Remove When Cache is Full

Comprehensive guide to cache eviction algorithms - the SECOND decision after choosing your caching pattern.

**Prerequisites**: Read `caching-patterns.md` FIRST to choose HOW to use cache (write-through, cache-aside, etc.). This document covers WHAT to evict when cache is full.

**Decision order**:
1. **Caching Pattern** (`caching-patterns.md`) - HOW to use cache
2. **Eviction Algorithm** (this document) - WHAT to evict when full

**Philosophy**: Cache is an optimization. Apply YAGNI - measure first, cache only when you can prove it helps.

## Overview

**Eviction algorithms** determine which items to remove when cache reaches capacity. They answer: "The cache is full, what should I delete?"

**Core principle**: The right eviction algorithm depends on your access patterns. No single algorithm is universally best.

### When to Cache

✅ **Cache when**:
- Same data accessed repeatedly
- Data is expensive to compute/fetch
- Data changes infrequently
- You've profiled and confirmed performance issue
- Hit rate can be measured

❌ **Don't cache when**:
- Data accessed once
- Data changes constantly
- Cache overhead > benefit
- Memory is constrained
- You haven't profiled (premature optimization)

## Decision Tree: Which Caching Strategy?

```
What is your access pattern?

Do items have equal importance?
├─ Yes → Do you need simplicity?
│  ├─ Yes → FIFO (simplest)
│  └─ No → Are accesses truly random?
│     ├─ Yes → RR (Random Replacement)
│     └─ No → Continue below
└─ No → Is recent access more important than frequency?
   ├─ Yes → LRU (most popular)
   │  └─ Or CLOCK (LRU approximation, lower overhead)
   └─ No → Is frequency more important than recency?
      ├─ Yes → LFU (track usage count)
      └─ No → Do you need both recency AND frequency?
         ├─ Yes → Need tunable weights?
         │  ├─ Yes → LRFU (weighted recency + frequency)
         │  └─ No → ARC (adaptive, automatic balance)
         │     └─ Or 2Q (two queues: short-term + long-term)
         │     └─ Or SLRU (segmented LRU with probationary period)
         └─ No → Do items expire after a time period?
            ├─ Yes → TTL (time-based expiration)
            └─ No → Do you have cyclical/backward access?
               ├─ Yes → MRU (most recently used)
               └─ No → Start with LRU (safest default)
```

## 1. FIFO (First-In-First-Out)

### Principle

**First item added is the first item removed** when cache is full.

### Implementation (Python)

```python
from collections import OrderedDict

class FIFOCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = OrderedDict()

    def get(self, key: str):
        """Retrieve value, returns None if not found"""
        return self.cache.get(key)

    def put(self, key: str, value: any):
        """Add item to cache, evict oldest if full"""
        if key not in self.cache and len(self.cache) >= self.capacity:
            # Remove first item (FIFO eviction)
            self.cache.popitem(last=False)
        self.cache[key] = value
```

### Implementation (TypeScript)

```typescript
class FIFOCache<T> {
  private capacity: number;
  private cache: Map<string, T>;

  constructor(capacity: number) {
    this.capacity = capacity;
    this.cache = new Map();
  }

  get(key: string): T | undefined {
    return this.cache.get(key);
  }

  put(key: string, value: T): void {
    if (!this.cache.has(key) && this.cache.size >= this.capacity) {
      // Remove first item (FIFO)
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    this.cache.set(key, value);
  }
}
```

### Use Cases

- ✅ Simple caching scenarios where all items have equal importance
- ✅ Systems with predictable sequential access patterns
- ✅ Embedded systems or IoT devices with limited resources
- ✅ Message queues or task buffers

### Advantages / Disadvantages

**Advantages**:
- Simple to implement
- Low computational overhead
- Predictable behavior

**Disadvantages**:
- Doesn't consider frequency or recency
- May evict still-useful items
- Poor hit rate for uneven access patterns

## 2. LRU (Least Recently Used)

### Principle

**Discard least recently used items first** when cache is full.

### Implementation (Python)

```python
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = OrderedDict()

    def get(self, key: str):
        """Get value and mark as recently used"""
        if key not in self.cache:
            return None
        # Move to end (most recently used)
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key: str, value: any):
        """Add/update item, mark as recently used"""
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            # Remove least recently used (first item)
            self.cache.popitem(last=False)
```

### Implementation (TypeScript)

```typescript
class LRUCache<T> {
  private capacity: number;
  private cache: Map<string, T>;

  constructor(capacity: number) {
    this.capacity = capacity;
    this.cache = new Map();
  }

  get(key: string): T | undefined {
    if (!this.cache.has(key)) return undefined;

    // Move to end (most recently used)
    const value = this.cache.get(key)!;
    this.cache.delete(key);
    this.cache.set(key, value);
    return value;
  }

  put(key: string, value: T): void {
    // Remove if exists (to re-insert at end)
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    this.cache.set(key, value);

    if (this.cache.size > this.capacity) {
      // Remove least recently used (first item)
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
  }
}
```

### Use Cases

- ✅ **General-purpose caching** (most popular choice)
- ✅ Operating system page replacement
- ✅ Database buffer pools
- ✅ Web browser caching (recently visited pages)
- ✅ CDN caching
- ✅ Redis default eviction policy

### Advantages / Disadvantages

**Advantages**:
- Good hit rate for most workloads
- Adapts to changing access patterns
- Well-understood and proven

**Disadvantages**:
- Doesn't track frequency (one-hit wonders evict popular items)
- Vulnerable to cache poisoning (sequential scan)
- Higher overhead than FIFO

### Real-World Example: Redis

```python
# Redis with LRU eviction
import redis

r = redis.Redis(host='localhost', port=6379, db=0)

# Configure maxmemory and eviction policy
r.config_set('maxmemory', '100mb')
r.config_set('maxmemory-policy', 'allkeys-lru')

# Use cache
r.set('user:123', json.dumps(user_data), ex=3600)  # 1 hour TTL
cached_user = r.get('user:123')
```

## 3. LFU (Least Frequently Used)

### Principle

**Remove least frequently used item** when cache is full.

### Implementation (Python)

```python
from collections import defaultdict, OrderedDict

class LFUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}  # key -> (value, frequency)
        # frequency -> OrderedDict of keys
        self.frequency = defaultdict(OrderedDict)
        self.min_freq = 0

    def get(self, key: str):
        """Get value and increment frequency"""
        if key not in self.cache:
            return None

        value, freq = self.cache[key]

        # Remove from current frequency list
        del self.frequency[freq][key]

        # Update min_freq if needed
        if not self.frequency[freq] and freq == self.min_freq:
            self.min_freq += 1

        # Add to next frequency list
        self.frequency[freq + 1][key] = None
        self.cache[key] = (value, freq + 1)

        return value

    def put(self, key: str, value: any):
        """Add item with frequency tracking"""
        if self.capacity == 0:
            return

        if key in self.cache:
            # Update existing key
            _, freq = self.cache[key]
            self.cache[key] = (value, freq)
            self.get(key)  # Increment frequency
        else:
            # Add new key
            if len(self.cache) >= self.capacity:
                # Evict least frequently used
                evict_key, _ = self.frequency[self.min_freq].popitem(last=False)
                del self.cache[evict_key]

            self.cache[key] = (value, 1)
            self.frequency[1][key] = None
            self.min_freq = 1
```

### Use Cases

- ✅ **Compiled code caching** in language runtimes
- ✅ Database query result caching (popular queries)
- ✅ Content recommendation systems (popular items stay popular)
- ✅ CDN for static assets (frequently accessed files)
- ✅ DNS caching (popular domains)

### Advantages / Disadvantages

**Advantages**:
- Excellent for workloads with strong frequency patterns
- Resists cache poisoning (one-time accesses don't evict popular items)
- Good for long-running systems

**Disadvantages**:
- Complex implementation
- Higher memory overhead (tracking frequencies)
- Slow to adapt to changing patterns (old popular items stick around)
- Poor for temporal locality (recent access not prioritized)

## 4. MRU (Most Recently Used)

### Principle

**Discard most recently used items first** (opposite of LRU).

### Implementation (Python)

```python
from collections import OrderedDict

class MRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = OrderedDict()

    def get(self, key: str):
        """Get value and mark as most recently used"""
        if key not in self.cache:
            return None
        value = self.cache.pop(key)
        self.cache[key] = value  # Re-insert at end
        return value

    def put(self, key: str, value: any):
        """Add item, evict most recently used if full"""
        if key in self.cache:
            self.cache.pop(key)
        elif len(self.cache) >= self.capacity:
            # Remove most recently used (last item)
            self.cache.popitem(last=True)
        self.cache[key] = value
```

### Use Cases

- ✅ **Cyclical access patterns** (users navigate back/forward)
- ✅ Graphics rendering pipelines (recently rendered objects are modified next)
- ✅ Undo/redo stacks in editors
- ✅ Database query caching for iterative scans
- ✅ Navigation systems (back button in mobile apps)

### Advantages / Disadvantages

**Advantages**:
- Perfect for cyclical/backward access patterns
- Simple implementation
- Good for certain specialized workloads

**Disadvantages**:
- Poor for general-purpose caching
- Counterintuitive behavior
- Rare use case

## 5. ARC (Adaptive Replacement Cache)

### Principle

**Combines recency and frequency** adaptively to maximize hit rate.

Maintains four lists:
- **T1**: Recently accessed once (recency)
- **T2**: Recently accessed multiple times (frequency)
- **B1**: Ghost entries evicted from T1
- **B2**: Ghost entries evicted from T2

Adapts the balance between T1 and T2 based on workload.

### Implementation (Python - Simplified)

```python
class ARCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.t1 = {}  # Recent items
        self.t2 = {}  # Frequent items
        self.b1 = {}  # Ghost cache for t1
        self.b2 = {}  # Ghost cache for t2
        self.p = 0    # Target size for t1

    def get(self, key: str):
        """Get value and promote to t2 if in t1"""
        if key in self.t1:
            self.t1.pop(key)
            self.t2[key] = True
            return True
        if key in self.t2:
            return True
        return None

    def put(self, key: str, value: any):
        """Add item with adaptive replacement"""
        if key in self.t1 or key in self.t2:
            return

        # Adaptation logic based on ghost caches
        if key in self.b1:
            # Increase t1 target size
            self.p = min(self.p + 1, self.capacity)
        elif key in self.b2:
            # Decrease t1 target size
            self.p = max(self.p - 1, 0)

        # Eviction and insertion logic
        if len(self.t1) + len(self.b1) == self.capacity:
            if len(self.t1) < self.capacity:
                self.b1.popitem()
                self.replace(key)
            else:
                self.t1.popitem()
        elif len(self.t1) + len(self.t2) + len(self.b1) + len(self.b2) >= self.capacity:
            if len(self.t1) + len(self.t2) + len(self.b1) + len(self.b2) >= 2 * self.capacity:
                if self.b2:
                    self.b2.popitem()
            self.replace(key)

        self.t1[key] = value

    def replace(self, key: str):
        """Replacement logic based on adaptive parameter p"""
        if len(self.t1) > 0 and (len(self.t1) > self.p or (key in self.b2 and len(self.t1) == self.p)):
            old = self.t1.popitem()
            self.b1[old[0]] = True
        else:
            old = self.t2.popitem()
            self.b2[old[0]] = True
```

### Use Cases

- ✅ **Enterprise storage systems** with diverse workloads
- ✅ VM hypervisors for memory management
- ✅ Database systems with varying query patterns
- ✅ Cloud storage gateways
- ✅ When you can't predict if recency or frequency dominates

### Advantages / Disadvantages

**Advantages**:
- Adapts to changing workloads automatically
- Better hit rate than LRU/LFU in mixed workloads
- Self-tuning (no manual parameter adjustment)

**Disadvantages**:
- Complex implementation
- Higher memory overhead (ghost caches)
- Patent encumbered (expired 2010, now free to use)
- Overkill for simple use cases

## 6. CLOCK (Second Chance)

### Principle

**Approximation of LRU** using a circular buffer and a "use" bit.

Each item has a reference bit:
- **1**: Recently accessed
- **0**: Not recently accessed

Clock hand sweeps, giving items with bit=1 a "second chance" (set bit to 0), evicting items with bit=0.

### Implementation (Python)

```python
class CLOCKCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}
        self.reference_bits = {}
        self.clock_hand = 0
        self.keys_list = []

    def get(self, key: str):
        """Get value and set reference bit"""
        if key in self.cache:
            self.reference_bits[key] = 1
            return self.cache[key]
        return None

    def put(self, key: str, value: any):
        """Add item with CLOCK eviction"""
        if key not in self.cache:
            if len(self.cache) >= self.capacity:
                self.evict()
            self.cache[key] = value
            self.reference_bits[key] = 1
            self.keys_list.append(key)
        else:
            self.cache[key] = value
            self.reference_bits[key] = 1

    def evict(self):
        """CLOCK eviction algorithm"""
        while True:
            if self.clock_hand >= len(self.keys_list):
                self.clock_hand = 0

            current_key = self.keys_list[self.clock_hand]

            if self.reference_bits[current_key] == 0:
                # Evict this item
                del self.cache[current_key]
                del self.reference_bits[current_key]
                self.keys_list.pop(self.clock_hand)
                return

            # Give second chance
            self.reference_bits[current_key] = 0
            self.clock_hand = (self.clock_hand + 1) % len(self.keys_list)
```

### Use Cases

- ✅ **Operating system page replacement** (Linux uses Clock-Pro)
- ✅ In-memory databases
- ✅ Embedded systems (low computational overhead)
- ✅ When LRU overhead is too high
- ✅ Hardware cache implementations

### Advantages / Disadvantages

**Advantages**:
- Lower overhead than LRU
- Good approximation of LRU behavior
- Simple bit manipulation (hardware-friendly)

**Disadvantages**:
- Not as accurate as true LRU
- Requires circular buffer management
- Reference bits need periodic clearing

## 7. RR (Random Replacement)

### Principle

**Randomly select item to evict** when cache is full.

### Implementation (Python)

```python
import random

class RRCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}

    def get(self, key: str):
        """Simple get"""
        return self.cache.get(key)

    def put(self, key: str, value: any):
        """Add item, randomly evict if full"""
        if len(self.cache) >= self.capacity and key not in self.cache:
            # Randomly evict
            evict_key = random.choice(list(self.cache.keys()))
            del self.cache[evict_key]
        self.cache[key] = value
```

### Use Cases

- ✅ **Truly random access patterns**
- ✅ Baseline for benchmarking other algorithms
- ✅ Simplicity and low overhead more important than hit rate
- ✅ Prototyping (temporary placeholder)

### Advantages / Disadvantages

**Advantages**:
- Extremely simple
- Lowest overhead
- No pathological worst cases

**Disadvantages**:
- Poor hit rate
- Unpredictable behavior
- No exploitation of access patterns

## 8. 2Q (Two Queue)

### Principle

**Two queues to capture both short-term and long-term access patterns**.

- **A1 (FIFO in)**: Items accessed once (25% of cache)
- **Am (LRU)**: Items accessed multiple times (75% of cache)

Items enter A1, promoted to Am on second access.

### Implementation (Python)

```python
from collections import OrderedDict

class TwoQCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.a1 = OrderedDict()  # Short-term (25%)
        self.a1_size = capacity // 4
        self.am = OrderedDict()  # Long-term (75%)
        self.am_size = capacity - self.a1_size

    def get(self, key: str):
        """Get and promote to am if in a1"""
        if key in self.a1:
            value = self.a1.pop(key)
            self.add_to_am(key, value)
            return value
        elif key in self.am:
            # Move to end (LRU)
            value = self.am.pop(key)
            self.am[key] = value
            return value
        return None

    def put(self, key: str, value: any):
        """Add to a1, promote to am on subsequent access"""
        if key in self.a1:
            self.a1.pop(key)
            self.add_to_am(key, value)
        elif key in self.am:
            self.am.pop(key)
            self.am[key] = value
        else:
            # New key - add to a1
            if len(self.a1) >= self.a1_size:
                if len(self.am) >= self.am_size:
                    self.am.popitem(last=False)
                k, v = self.a1.popitem(last=False)
                self.add_to_am(k, v)
            self.a1[key] = value

    def add_to_am(self, key: str, value: any):
        """Add to long-term queue"""
        if len(self.am) >= self.am_size:
            self.am.popitem(last=False)
        self.am[key] = value
```

### Use Cases

- ✅ **Database buffer management**
- ✅ Social media content caching (trending + evergreen)
- ✅ File system caching (recent + frequent files)
- ✅ Workloads with both scan and locality patterns

### Advantages / Disadvantages

**Advantages**:
- Resistant to cache pollution from scans
- Balances recency and frequency
- Better than LRU for mixed workloads

**Disadvantages**:
- More complex than LRU
- Fixed 25%/75% split may not be optimal
- Higher memory overhead

## 9. SLRU (Segmented LRU)

### Principle

**Cache divided into segments**, each managed with LRU.

- **Probationary segment**: New items (50%)
- **Protected segment**: Frequently accessed items (50%)

Items promoted from probationary to protected on second access.

### Implementation (Python)

```python
from collections import OrderedDict

class SLRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.probationary = OrderedDict()
        self.protected = OrderedDict()
        self.prob_size = capacity // 2
        self.prot_size = capacity - self.prob_size

    def get(self, key: str):
        """Get and promote to protected"""
        if key in self.probationary:
            value = self.probationary.pop(key)
            self.add_to_protected(key, value)
            return value
        elif key in self.protected:
            value = self.protected.pop(key)
            self.protected[key] = value  # Move to end
            return value
        return None

    def put(self, key: str, value: any):
        """Add to probationary, promote on re-access"""
        if key in self.probationary:
            self.probationary.pop(key)
            self.add_to_protected(key, value)
        elif key in self.protected:
            self.protected.pop(key)
            self.protected[key] = value
        else:
            if len(self.probationary) >= self.prob_size:
                if len(self.protected) >= self.prot_size:
                    self.protected.popitem(last=False)
                k, v = self.probationary.popitem(last=False)
                self.add_to_protected(k, v)
            self.probationary[key] = value

    def add_to_protected(self, key: str, value: any):
        """Add to protected segment"""
        if len(self.protected) >= self.prot_size:
            k, v = self.protected.popitem(last=False)
            self.probationary[k] = v
        self.protected[key] = value
```

### Use Cases

- ✅ **Multi-tier caching** in cloud environments
- ✅ Browser caching (popular + recent pages)
- ✅ Big data processing (Spark, Hadoop)
- ✅ Workloads needing protection from one-hit wonders

### Advantages / Disadvantages

**Advantages**:
- Protects frequently accessed items
- Resists scan pollution
- Good for workloads with both hot and warm data

**Disadvantages**:
- More complex than LRU
- Requires tuning segment sizes
- Higher overhead

## 10. TTL (Time To Live)

### Principle

**Items expire after a fixed time period**.

### Implementation (Python)

```python
import time

class TTLCache:
    def __init__(self, capacity: int, ttl: int):
        self.capacity = capacity
        self.ttl = ttl  # seconds
        self.cache = {}
        self.timestamps = {}

    def get(self, key: str):
        """Get if not expired"""
        if key in self.cache:
            if time.time() - self.timestamps[key] < self.ttl:
                return self.cache[key]
            else:
                # Expired - remove
                del self.cache[key]
                del self.timestamps[key]
        return None

    def put(self, key: str, value: any):
        """Add with timestamp"""
        if len(self.cache) >= self.capacity and key not in self.cache:
            self.evict()
        self.cache[key] = value
        self.timestamps[key] = time.time()

    def evict(self):
        """Evict expired items, then oldest"""
        current_time = time.time()
        expired = [k for k, t in self.timestamps.items()
                   if current_time - t >= self.ttl]
        for key in expired:
            del self.cache[key]
            del self.timestamps[key]

        if not expired and self.cache:
            # No expired items - evict oldest
            oldest = min(self.timestamps, key=self.timestamps.get)
            del self.cache[oldest]
            del self.timestamps[oldest]
```

### Implementation (TypeScript with Redis)

```typescript
import Redis from 'ioredis';

class TTLCache {
  private redis: Redis;

  constructor(redisUrl: string) {
    this.redis = new Redis(redisUrl);
  }

  async get(key: string): Promise<string | null> {
    return await this.redis.get(key);
  }

  async put(key: string, value: string, ttlSeconds: number): Promise<void> {
    await this.redis.setex(key, ttlSeconds, value);
  }

  async putJSON<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
    await this.redis.setex(key, ttlSeconds, JSON.stringify(value));
  }

  async getJSON<T>(key: string): Promise<T | null> {
    const value = await this.redis.get(key);
    return value ? JSON.parse(value) : null;
  }
}

// Usage
const cache = new TTLCache('redis://localhost:6379');
await cache.putJSON('user:123', userData, 3600); // 1 hour
const user = await cache.getJSON('user:123');
```

### Use Cases

- ✅ **DNS caching** (IP addresses change)
- ✅ Session management (sessions expire)
- ✅ API rate limiting (time-window based)
- ✅ Financial data (quotes expire)
- ✅ Authentication tokens (JWTs expire)
- ✅ Real-time systems (data has shelf life)

### Advantages / Disadvantages

**Advantages**:
- Guarantees data freshness
- Prevents stale data issues
- Simple to understand and implement

**Disadvantages**:
- May evict still-useful items
- Requires choosing appropriate TTL (too short = poor hit rate, too long = stale data)
- Clock skew issues in distributed systems

## 11. LRFU (Least Recently/Frequently Used)

### Principle

**Combines LRU and LFU** by assigning weights to both recency and frequency.

Calculates a score for each item based on:
- **When** it was last accessed (recency)
- **How often** it's been accessed (frequency)

Formula: `Score = Frequency_Weight × Frequency + Recency_Weight × Recency`

### Implementation (Python)

```python
import time
from typing import Dict, Any, Tuple

class LRFUCache:
    def __init__(self, capacity: int, lambda_param: float = 0.5):
        """
        Initialize LRFU cache

        Args:
            capacity: Maximum cache size
            lambda_param: Weight parameter (0 = pure LRU, 1 = pure LFU)
                         0.5 = balanced between recency and frequency
        """
        self.capacity = capacity
        self.lambda_param = lambda_param  # Controls recency vs frequency balance
        self.cache: Dict[str, Tuple[Any, float, int]] = {}  # key -> (value, last_access_time, access_count)
        self.current_time = 0

    def _calculate_crf(self, key: str) -> float:
        """Calculate Combined Recency and Frequency (CRF) value"""
        if key not in self.cache:
            return 0

        _, last_access, access_count = self.cache[key]

        # Calculate recency component (exponential decay)
        time_since_access = self.current_time - last_access
        recency_score = (1 / (1 + self.lambda_param * time_since_access))

        # Frequency component
        frequency_score = access_count

        # Combined score (higher is better)
        return recency_score * frequency_score

    def get(self, key: str):
        """Get value and update access metadata"""
        self.current_time += 1

        if key not in self.cache:
            return None

        value, _, access_count = self.cache[key]

        # Update metadata
        self.cache[key] = (value, self.current_time, access_count + 1)

        return value

    def put(self, key: str, value: Any):
        """Add item with LRFU scoring"""
        self.current_time += 1

        if key in self.cache:
            # Update existing key
            _, _, access_count = self.cache[key]
            self.cache[key] = (value, self.current_time, access_count + 1)
        else:
            # Add new key
            if len(self.cache) >= self.capacity:
                # Evict item with lowest CRF score
                min_key = min(self.cache.keys(), key=lambda k: self._calculate_crf(k))
                del self.cache[min_key]

            self.cache[key] = (value, self.current_time, 1)

# Usage examples
# Pure LRU behavior
lru_like_cache = LRFUCache(capacity=100, lambda_param=0.0)

# Pure LFU behavior
lfu_like_cache = LRFUCache(capacity=100, lambda_param=1.0)

# Balanced (default)
balanced_cache = LRFUCache(capacity=100, lambda_param=0.5)
```

### Implementation (TypeScript)

```typescript
class LRFUCache<T> {
  private capacity: number;
  private lambda: number;
  private cache: Map<string, { value: T; lastAccess: number; accessCount: number }>;
  private currentTime: number;

  constructor(capacity: number, lambda: number = 0.5) {
    this.capacity = capacity;
    this.lambda = lambda; // 0 = LRU, 1 = LFU, 0.5 = balanced
    this.cache = new Map();
    this.currentTime = 0;
  }

  private calculateCRF(key: string): number {
    const entry = this.cache.get(key);
    if (!entry) return 0;

    const timeSinceAccess = this.currentTime - entry.lastAccess;
    const recencyScore = 1 / (1 + this.lambda * timeSinceAccess);
    const frequencyScore = entry.accessCount;

    return recencyScore * frequencyScore;
  }

  get(key: string): T | undefined {
    this.currentTime++;

    const entry = this.cache.get(key);
    if (!entry) return undefined;

    // Update metadata
    this.cache.set(key, {
      value: entry.value,
      lastAccess: this.currentTime,
      accessCount: entry.accessCount + 1
    });

    return entry.value;
  }

  put(key: string, value: T): void {
    this.currentTime++;

    if (this.cache.has(key)) {
      const entry = this.cache.get(key)!;
      this.cache.set(key, {
        value,
        lastAccess: this.currentTime,
        accessCount: entry.accessCount + 1
      });
    } else {
      if (this.cache.size >= this.capacity) {
        // Evict item with lowest CRF score
        let minKey: string | null = null;
        let minScore = Infinity;

        for (const [k] of this.cache) {
          const score = this.calculateCRF(k);
          if (score < minScore) {
            minScore = score;
            minKey = k;
          }
        }

        if (minKey) this.cache.delete(minKey);
      }

      this.cache.set(key, {
        value,
        lastAccess: this.currentTime,
        accessCount: 1
      });
    }
  }
}

// Usage
const cache = new LRFUCache<User>(100, 0.5); // Balanced
```

### Tuning Lambda Parameter

```python
# Lambda = 0.0 → Pure LRU (only recency matters)
lru_cache = LRFUCache(100, lambda_param=0.0)

# Lambda = 1.0 → Pure LFU (only frequency matters)
lfu_cache = LRFUCache(100, lambda_param=1.0)

# Lambda = 0.5 → Balanced (default, recommended)
balanced_cache = LRFUCache(100, lambda_param=0.5)

# Lambda = 0.2 → More weight on recency
recency_focused = LRFUCache(100, lambda_param=0.2)

# Lambda = 0.8 → More weight on frequency
frequency_focused = LRFUCache(100, lambda_param=0.8)
```

### Use Cases

- ✅ **Workloads needing balanced consideration** of recency and frequency
- ✅ Systems where both temporal and frequency-based patterns exist
- ✅ **Fine-tuning cache behavior** for specific access patterns
- ✅ Research and experimentation (academic use)
- ✅ When ARC is too complex but LRU/LFU alone aren't sufficient

### Advantages / Disadvantages

**Advantages**:
- Flexible tuning via lambda parameter
- Combines best of LRU and LFU
- Can adapt to different workloads by adjusting weights
- More sophisticated than pure LRU or LFU

**Disadvantages**:
- More complex than LRU or LFU alone
- Requires tuning lambda parameter (not adaptive like ARC)
- Higher computational overhead (score calculation)
- Tracking both recency and frequency increases memory usage
- Less intuitive than pure LRU or LFU

### When to Choose LRFU vs ARC

**Choose LRFU when**:
- You understand your workload and can tune lambda
- You need explicit control over recency/frequency balance
- Simpler than ARC, don't need adaptive behavior

**Choose ARC when**:
- Workload changes over time
- Want automatic adaptation (no manual tuning)
- Enterprise system with unpredictable patterns

**Choose LRU when**:
- Recency dominates (most common case)
- Simplicity matters more than optimization

## Comparison Table

| Strategy | Hit Rate | Complexity | Overhead | Best For |
|----------|----------|------------|----------|----------|
| **FIFO** | Low | Very Low | Very Low | Simple use cases, equal importance |
| **LRU** | High | Medium | Medium | General-purpose, recency matters |
| **LFU** | High* | High | High | Frequency matters, stable workloads |
| **MRU** | Low* | Low | Low | Cyclical access, specific patterns |
| **ARC** | Very High | Very High | High | Mixed workloads, enterprise systems |
| **CLOCK** | Medium-High | Low | Low | OS page replacement, low overhead |
| **RR** | Very Low | Very Low | Very Low | Random access, simplicity critical |
| **2Q** | High | Medium-High | Medium | Mixed short/long-term patterns |
| **SLRU** | High | Medium | Medium | Protection from scans, multi-tier |
| **TTL** | Varies | Low-Medium | Low | Time-sensitive data, freshness critical |
| **LRFU** | High* | Medium-High | Medium-High | Tunable balance of recency + frequency |

*Depends heavily on workload and lambda tuning

## Real-World Implementation Examples

### Example 1: API Response Caching (Next.js)

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

// In-memory LRU cache
const cache = new LRUCache<User>(100);

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const userId = params.id;

  // Check cache first
  const cached = cache.get(userId);
  if (cached) {
    return NextResponse.json(cached, {
      headers: { 'X-Cache': 'HIT' }
    });
  }

  // Cache miss - fetch from database
  const user = await db.user.findUnique({ where: { id: userId } });

  if (user) {
    cache.put(userId, user);
  }

  return NextResponse.json(user, {
    headers: { 'X-Cache': 'MISS' }
  });
}
```

### Example 2: Redis with TTL (Python/FastAPI)

```python
from fastapi import FastAPI
import redis
import json

app = FastAPI()
r = redis.Redis(host='localhost', port=6379, decode_responses=True)

@app.get("/products/{product_id}")
async def get_product(product_id: str):
    # Try cache first
    cache_key = f"product:{product_id}"
    cached = r.get(cache_key)

    if cached:
        return {"data": json.loads(cached), "cache": "HIT"}

    # Fetch from database
    product = await db.products.find_one({"_id": product_id})

    # Cache for 1 hour
    r.setex(cache_key, 3600, json.dumps(product))

    return {"data": product, "cache": "MISS"}
```

### Example 3: React Query (Client-Side LRU + TTL)

```typescript
import { useQuery } from '@tanstack/react-query';

function UserProfile({ userId }: { userId: string }) {
  const { data, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    staleTime: 5 * 60 * 1000, // 5 minutes (TTL)
    cacheTime: 10 * 60 * 1000, // 10 minutes (keep in cache)
    // React Query uses LRU internally for cache management
  });

  if (isLoading) return <Spinner />;
  return <div>{data.name}</div>;
}
```

### Example 4: Memoization with LRU (Python)

```python
from functools import lru_cache

@lru_cache(maxsize=128)  # Built-in LRU cache
def expensive_computation(n: int) -> int:
    """Fibonacci with memoization"""
    if n < 2:
        return n
    return expensive_computation(n - 1) + expensive_computation(n - 2)

# Usage
result = expensive_computation(100)  # Cached after first call
```

## Integration with Architecture Principles

### YAGNI (You Aren't Gonna Need It)

**Don't cache prematurely**:

```python
# ❌ Bad - premature optimization
class UserService:
    def __init__(self):
        self.cache = LRUCache(1000)  # Why? No proof it helps

    def get_user(self, id: str):
        cached = self.cache.get(id)
        if cached:
            return cached
        user = db.query(...)
        self.cache.put(id, user)
        return user

# ✅ Good - cache only after profiling
class UserService:
    def get_user(self, id: str):
        # Simple version first
        return db.query(...)

# Then, AFTER profiling shows database is slow:
# - Add caching
# - Measure hit rate
# - Confirm improvement
```

### DRY (Don't Repeat Yourself)

**Extract caching logic**:

```typescript
// ❌ Bad - repeated caching logic
async function getUser(id: string) {
  const cached = cache.get(`user:${id}`);
  if (cached) return cached;
  const user = await db.user.findUnique({ where: { id } });
  cache.put(`user:${id}`, user);
  return user;
}

async function getProduct(id: string) {
  const cached = cache.get(`product:${id}`);
  if (cached) return cached;
  const product = await db.product.findUnique({ where: { id } });
  cache.put(`product:${id}`, product);
  return product;
}

// ✅ Good - abstracted caching wrapper
async function withCache<T>(
  key: string,
  fetchFn: () => Promise<T>,
  ttl?: number
): Promise<T> {
  const cached = cache.get(key);
  if (cached) return cached as T;

  const data = await fetchFn();
  cache.put(key, data, ttl);
  return data;
}

async function getUser(id: string) {
  return withCache(`user:${id}`, () =>
    db.user.findUnique({ where: { id } })
  );
}
```

### SRP (Single Responsibility Principle)

**Separate caching from business logic**:

```python
# ❌ Bad - business logic + caching mixed
class ProductService:
    def calculate_price(self, product_id: str, quantity: int) -> float:
        cache_key = f"price:{product_id}:{quantity}"
        cached = self.cache.get(cache_key)
        if cached:
            return cached

        # Business logic
        product = self.get_product(product_id)
        base_price = product.price * quantity
        discount = self.calculate_discount(quantity)
        final_price = base_price * (1 - discount)

        self.cache.put(cache_key, final_price)
        return final_price

# ✅ Good - separated concerns
class ProductService:
    def calculate_price(self, product_id: str, quantity: int) -> float:
        """Pure business logic - no caching"""
        product = self.get_product(product_id)
        base_price = product.price * quantity
        discount = self.calculate_discount(quantity)
        return base_price * (1 - discount)

class CachedProductService:
    def __init__(self, service: ProductService, cache: Cache):
        self.service = service
        self.cache = cache

    def calculate_price(self, product_id: str, quantity: int) -> float:
        """Caching wrapper - single responsibility"""
        cache_key = f"price:{product_id}:{quantity}"
        cached = self.cache.get(cache_key)
        if cached:
            return cached

        result = self.service.calculate_price(product_id, quantity)
        self.cache.put(cache_key, result)
        return result
```

## Measuring Cache Performance

### Key Metrics

```python
class CacheMetrics:
    def __init__(self):
        self.hits = 0
        self.misses = 0
        self.evictions = 0

    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0

    @property
    def miss_rate(self) -> float:
        return 1 - self.hit_rate

    def report(self):
        print(f"Hit Rate: {self.hit_rate:.2%}")
        print(f"Hits: {self.hits}")
        print(f"Misses: {self.misses}")
        print(f"Evictions: {self.evictions}")

# Usage
class MonitoredCache:
    def __init__(self, cache: Cache):
        self.cache = cache
        self.metrics = CacheMetrics()

    def get(self, key: str):
        result = self.cache.get(key)
        if result is not None:
            self.metrics.hits += 1
        else:
            self.metrics.misses += 1
        return result
```

**What's a good hit rate?**
- 90%+ = Excellent
- 70-90% = Good
- 50-70% = Acceptable
- <50% = Consider if caching is worth it

## Checklist: Before Adding Cache

- [ ] Have you profiled and confirmed a performance issue?
- [ ] Can you measure the hit rate?
- [ ] Is the data accessed multiple times?
- [ ] Is the data expensive to compute/fetch?
- [ ] Does the data change infrequently enough?
- [ ] Have you chosen the right eviction strategy for your access pattern?
- [ ] Do you have a plan to invalidate stale data?
- [ ] Is memory available for the cache?
- [ ] Is the caching logic separated from business logic (SRP)?

## Common Anti-Patterns

| Anti-Pattern | Why Bad | Fix |
|--------------|---------|-----|
| Cache everything | Memory waste, complexity | Profile first, cache only bottlenecks |
| Wrong eviction strategy | Poor hit rate | Match strategy to access pattern |
| No TTL for changing data | Stale data bugs | Add TTL or invalidation |
| Caching in business logic | Violates SRP, hard to test | Separate cache layer |
| No metrics | Can't measure if cache helps | Add hit/miss tracking |
| Too small cache size | Constant evictions, poor hit rate | Size based on working set |
| Caching non-serializable objects | Memory leaks, stale references | Cache serialized data |
| No cache warming | Cold start performance issues | Pre-populate critical data |

## See Also

- `referentiel/principes-architectures.md` - Architecture principles (YAGNI, DRY, SRP)
- `referentiel/tensions-architecturales.md` - Performance vs other principles
- Redis documentation: https://redis.io/docs/manual/eviction/
- Caffeine (Java): https://github.com/ben-manes/caffeine
- React Query: https://tanstack.com/query/latest

## Summary

**Cache selection guide**:

1. **Don't know pattern?** → Start with **LRU** (safest default)
2. **Recency matters most?** → **LRU**
3. **Frequency matters most?** → **LFU**
4. **Data expires?** → **TTL**
5. **Mixed workload?** → **ARC** (adaptive) or **2Q** (simpler)
6. **Need tunable weights?** → **LRFU** (manual tuning)
7. **Low overhead critical?** → **CLOCK** or **FIFO**
8. **Need protection from scans?** → **SLRU** or **2Q**

**Golden rule**: Profile first, cache second. Measure hit rate, adjust strategy if needed.

**Remember**: The best caching strategy is the one that solves YOUR specific performance problem. Start simple (LRU), measure, adapt.
