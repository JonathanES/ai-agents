---
name: sql-profiler
description: Profile SQL queries to detect and fix N+1 query issues in Python (Django, SQLAlchemy, FastAPI) and TypeScript (Prisma, TypeORM, Sequelize)
type: tool
---

# SQL Profiler: N+1 Query Detection

Detect and fix N+1 SQL query problems that cause performance issues. Works with Python (Django, SQLAlchemy, FastAPI) and TypeScript (Prisma, TypeORM, Sequelize).

## What is an N+1 Query Problem?

**N+1 occurs when**:
1. You query for N items (1 query)
2. Then for each item, you query for related data (N queries)
3. Result: 1 + N queries instead of 1 or 2 queries

**Example**:
```python
# ❌ N+1 Problem: 1 + N queries
users = User.objects.all()  # 1 query
for user in users:
    user.posts.all()  # N queries (one per user)
# Total: 1 + 100 = 101 queries for 100 users

# ✅ Fixed: 2 queries total
users = User.objects.prefetch_related('posts').all()  # 2 queries
for user in users:
    user.posts.all()  # No additional queries
# Total: 2 queries regardless of user count
```

## Purpose

This skill provides:
- **Detection tools**: Identify N+1 problems in your code
- **Profiling setup**: Configure query logging
- **Fix patterns**: Solutions for each framework
- **Testing tools**: Verify fixes work

## Python Profiling

### Django

#### Setup: django-silk

**Installation**:
```bash
pip install django-silk
```

**Configuration** (`settings.py`):
```python
INSTALLED_APPS = [
    ...
    'silk',
]

MIDDLEWARE = [
    'silk.middleware.SilkyMiddleware',
    ...
]

# Optional: Profile specific paths
SILKY_INTERCEPT_PERCENT = 100  # Profile 100% of requests
SILKY_MAX_RECORDED_REQUESTS = 10**4
```

**URLs** (`urls.py`):
```python
from django.urls import path, include

urlpatterns = [
    path('silk/', include('silk.urls', namespace='silk')),
    ...
]
```

**Usage**:
1. Run your app
2. Visit `/silk/` in browser
3. Execute the endpoint you want to profile
4. Check silk dashboard for query count and duplicates

**Detecting N+1**:
- Look for "Query count" spike
- Check for identical queries repeated multiple times
- Silk highlights duplicate queries

#### Fix Patterns: Django

**Problem**: N+1 on ForeignKey
```python
# ❌ N+1
users = User.objects.all()
for user in users:
    print(user.profile.bio)  # Query per user

# ✅ Fixed with select_related (JOIN)
users = User.objects.select_related('profile').all()
for user in users:
    print(user.profile.bio)  # No additional queries
```

**Problem**: N+1 on ManyToMany/Reverse ForeignKey
```python
# ❌ N+1
users = User.objects.all()
for user in users:
    for post in user.posts.all():  # Query per user
        print(post.title)

# ✅ Fixed with prefetch_related (separate query + join in Python)
users = User.objects.prefetch_related('posts').all()
for user in users:
    for post in user.posts.all():  # No additional queries
        print(post.title)
```

**Complex prefetching**:
```python
from django.db.models import Prefetch

# Prefetch with filtering
users = User.objects.prefetch_related(
    Prefetch(
        'posts',
        queryset=Post.objects.filter(published=True).select_related('category')
    )
).all()
```

### SQLAlchemy

#### Setup: Query logging

**Configuration**:
```python
import logging

# Enable SQLAlchemy query logging
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
```

**Or use echo=True**:
```python
from sqlalchemy import create_engine

engine = create_engine('postgresql://...', echo=True)
```

#### Fix Patterns: SQLAlchemy

**Problem**: N+1 on relationship
```python
# ❌ N+1
users = session.query(User).all()
for user in users:
    print(user.profile.bio)  # Query per user

# ✅ Fixed with joinedload (JOIN)
from sqlalchemy.orm import joinedload

users = session.query(User).options(joinedload(User.profile)).all()
for user in users:
    print(user.profile.bio)  # No additional queries
```

**Problem**: N+1 on collection
```python
# ❌ N+1
users = session.query(User).all()
for user in users:
    for post in user.posts:  # Query per user
        print(post.title)

# ✅ Fixed with selectinload (separate query)
from sqlalchemy.orm import selectinload

users = session.query(User).options(selectinload(User.posts)).all()
for user in users:
    for post in user.posts:  # No additional queries
        print(post.title)
```

**Choose load strategy**:
- `joinedload`: Use for one-to-one or small one-to-many (LEFT OUTER JOIN)
- `selectinload`: Use for large one-to-many (separate SELECT with IN)
- `subqueryload`: Alternative to selectinload (uses subquery)

### FastAPI with SQLAlchemy

Same as SQLAlchemy above, but add middleware to log queries per request:

```python
from fastapi import FastAPI, Request
import time
import logging

app = FastAPI()

@app.middleware("http")
async def log_queries(request: Request, call_next):
    # Reset query counter
    start_time = time.time()

    # Process request
    response = await call_next(request)

    # Log duration
    duration = time.time() - start_time
    logging.info(f"{request.method} {request.url.path} - {duration:.3f}s")

    return response
```

For detailed profiling, use django-silk approach or Py-Spy for production profiling.

## TypeScript/Node.js Profiling

### Prisma

#### Setup: Query logging

**Configuration** (`schema.prisma`):
```prisma
generator client {
  provider = "prisma-client-js"
  log      = ["query", "info", "warn", "error"]
}
```

**Or in code**:
```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
})
```

#### Fix Patterns: Prisma

**Problem**: N+1 on relation
```typescript
// ❌ N+1
const users = await prisma.user.findMany()
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id }
  })  // Query per user
}

// ✅ Fixed with include
const users = await prisma.user.findMany({
  include: { posts: true }
})
for (const user of users) {
  user.posts  // Already loaded
}
```

**Nested includes**:
```typescript
const users = await prisma.user.findMany({
  include: {
    posts: {
      include: {
        comments: true,
        categories: true
      }
    },
    profile: true
  }
})
```

**Selective fields**:
```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    posts: {
      select: {
        title: true,
        createdAt: true
      }
    }
  }
})
```

### TypeORM

#### Setup: Query logging

**Configuration**:
```typescript
import { createConnection } from 'typeorm'

const connection = await createConnection({
  type: 'postgres',
  ...
  logging: ['query', 'error'],
  // Or: logging: true for all logs
})
```

#### Fix Patterns: TypeORM

**Problem**: N+1 on relation
```typescript
// ❌ N+1
const users = await userRepository.find()
for (const user of users) {
  await user.posts  // Query per user (if lazy loaded)
}

// ✅ Fixed with relations
const users = await userRepository.find({
  relations: ['posts']
})
for (const user of users) {
  user.posts  // Already loaded
}
```

**Using query builder**:
```typescript
const users = await userRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.posts', 'posts')
  .leftJoinAndSelect('posts.comments', 'comments')
  .getMany()
```

### Sequelize

#### Setup: Query logging

**Configuration**:
```typescript
import { Sequelize } from 'sequelize'

const sequelize = new Sequelize('database', 'username', 'password', {
  logging: (sql, timing) => {
    console.log(`[${timing}ms] ${sql}`)
  }
})
```

#### Fix Patterns: Sequelize

**Problem**: N+1 on relation
```typescript
// ❌ N+1
const users = await User.findAll()
for (const user of users) {
  const posts = await user.getPosts()  // Query per user
}

// ✅ Fixed with include
const users = await User.findAll({
  include: [Post]
})
for (const user of users) {
  user.posts  // Already loaded (note: lowercase, not getPosts())
}
```

**Nested includes**:
```typescript
const users = await User.findAll({
  include: [
    {
      model: Post,
      include: [
        { model: Comment },
        { model: Category }
      ]
    },
    { model: Profile }
  ]
})
```

## Detection Script

Python script to detect N+1 in test output:

```python
# skills/sql-profiler/scripts/detect_n_plus_one.py
import re
import sys
from collections import Counter

def detect_n_plus_one(log_file):
    """
    Parse SQL query log and detect N+1 patterns
    """
    with open(log_file, 'r') as f:
        queries = f.readlines()

    # Normalize queries (remove parameters)
    normalized = []
    for query in queries:
        # Remove WHERE values, IN lists, etc.
        normalized_query = re.sub(r"= \d+", "= ?", query)
        normalized_query = re.sub(r"IN \([^\)]+\)", "IN (?)", normalized_query)
        normalized.append(normalized_query)

    # Count duplicates
    query_counts = Counter(normalized)

    # Flag queries that appear many times
    print("Potential N+1 queries:\\n")
    for query, count in query_counts.most_common():
        if count > 10:  # Threshold for suspicion
            print(f"[{count}x] {query}\\n")

if __name__ == "__main__":
    detect_n_plus_one(sys.argv[1])
```

**Usage**:
```bash
# Capture queries to file
python manage.py runserver > queries.log 2>&1

# Analyze
python skills/sql-profiler/scripts/detect_n_plus_one.py queries.log
```

## Testing Fixes

### Pytest assertion (Django/SQLAlchemy)

```python
from django.test import TestCase
from django.test.utils import override_settings
from django.db import connection
from django.test.utils import CaptureQueriesContext

def test_no_n_plus_one():
    with CaptureQueriesContext(connection) as queries:
        users = User.objects.prefetch_related('posts').all()
        for user in users:
            list(user.posts.all())

    # Should be 2 queries: users + posts
    assert len(queries) == 2, f"Expected 2 queries, got {len(queries)}"
```

### Jest assertion (TypeScript)

```typescript
// Mock Prisma client and count queries
let queryCount = 0

const prismaMock = {
  user: {
    findMany: jest.fn(async () => {
      queryCount++
      return mockUsers
    })
  }
}

test('should not have N+1 queries', async () => {
  queryCount = 0

  const users = await service.getUsersWithPosts()

  // Should be 1 query with include, not N+1
  expect(queryCount).toBe(1)
})
```

## Common Patterns

### DataLoader (GraphQL/TypeScript)

For GraphQL APIs, use DataLoader to batch and cache queries:

```typescript
import DataLoader from 'dataloader'

const postLoader = new DataLoader(async (userIds) => {
  const posts = await prisma.post.findMany({
    where: { authorId: { in: userIds } }
  })

  // Group by user
  const postsByUser = userIds.map(id =>
    posts.filter(post => post.authorId === id)
  )
  return postsByUser
})

// Usage: automatically batches
for (const user of users) {
  const posts = await postLoader.load(user.id)  // Batched!
}
```

### Pagination Consideration

When paginating, still use eager loading:

```python
# ❌ Still N+1 even with pagination
users = User.objects.all()[10:20]
for user in users:
    user.posts.all()  # N queries

# ✅ Eager load with pagination
users = User.objects.prefetch_related('posts').all()[10:20]
for user in users:
    user.posts.all()  # No additional queries
```

## Performance Checklist

Before deploying:

- [ ] Run profiler on critical endpoints
- [ ] Check query count doesn't scale with data size
- [ ] Add tests that assert query count
- [ ] Document expected query counts
- [ ] Monitor query times in production

## References

- **Django**: https://docs.djangoproject.com/en/stable/ref/models/querysets/#prefetch-related
- **SQLAlchemy**: https://docs.sqlalchemy.org/en/14/orm/loading_relationships.html
- **Prisma**: https://www.prisma.io/docs/concepts/components/prisma-client/relation-queries
- **TypeORM**: https://typeorm.io/eager-and-lazy-relations
- **Sequelize**: https://sequelize.org/docs/v6/advanced-association-concepts/eager-loading/
- **Django Silk**: https://github.com/jazzband/django-silk

## See Also

- Performance optimization should follow architecture principles
- Don't optimize prematurely (YAGNI)
- Profile first, then optimize based on data
