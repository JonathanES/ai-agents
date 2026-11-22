# System Design Trade-offs

Comprehensive guide to fundamental trade-offs in distributed system design.

**Philosophy**: Every architectural decision involves trade-offs. Understanding both sides helps you make informed choices based on your specific requirements.

## Overview

System design is about choosing the right trade-offs for your use case. There is rarely a universally "correct" answer - the best choice depends on your specific requirements, constraints, and priorities.

This document covers essential trade-offs that come up in every system design discussion.

## Trade-offs Index

### Communication & Architecture
- [Synchronous vs Asynchronous Communication](#synchronous-vs-asynchronous-communication) ✅ Complete
- Push vs Pull Architecture 🔜 Coming soon
- Stateful vs Stateless Architecture 🔜 Coming soon
- REST vs RPC 🔜 Coming soon
- Polling vs Long-Polling vs WebSockets vs Webhooks 🔜 Coming soon
- Batch Processing vs Stream Processing 🔜 Coming soon

### Infrastructure & Scaling
- Latency vs Throughput 🔜 Coming soon
- Horizontal vs Vertical Scaling 🔜 Coming soon
- Proxy vs Reverse Proxy 🔜 Coming soon
- Load Balancer vs API Gateway 🔜 Coming soon
- API Gateway vs Direct Service Exposure 🔜 Coming soon
- Serverless Architecture vs Traditional Server-based 🔜 Coming soon

### Rate Limiting & Traffic Management
- Token Bucket vs Leaky Bucket 🔜 Coming soon
- CDN Usage vs Direct Server Serving 🔜 Coming soon

### Data & Persistence
- SQL vs NoSQL 🔜 Coming soon
- Normalization vs Denormalization 🔜 Coming soon
- ACID vs BASE Properties in Databases 🔜 Coming soon
- Strong vs Eventual Consistency 🔜 Coming soon
- Primary-Replica vs Peer-to-Peer Replication 🔜 Coming soon
- Read Heavy vs Write Heavy System 🔜 Coming soon

### Caching
- Server-Side Caching vs Client-Side Caching (see [caching-tools.md](caching-tools.md))
- Cache-Aside vs Read-Through, Write-Through vs Write-Back (see [caching-patterns.md](caching-patterns.md))

---

## Synchronous vs Asynchronous Communication

### The One Question That Decides

For every call between two services, ask: **does the caller need the result before it can continue?**

- **If yes** → make the call synchronous
- **If no** → it can be asynchronous

**Example**: User clicks "Place Order" in an online store. The system must:
1. ✅ Charge the card (need result now)
2. ✅ Save the order (need result now)
3. ⏭️ Send confirmation email (can happen later)
4. ⏭️ Notify warehouse (can happen later)
5. ⏭️ Update recommendations (can happen later)
6. ⏭️ Record analytics (can happen later)

The user should wait only for the payment and saved order. Everything else can be asynchronous.

```
If everything is synchronous:
User waits for 6 services

Split by need:
User waits for 2 services (payment + order)
4 services happen async
```

### Synchronous Communication

**Definition**: The caller sends a request and waits for the response. It cannot continue until the answer arrives.

**Examples**: HTTP request, gRPC call, database query

#### What Synchronous Communication Gives You

✅ **Simple flow**
- Call, get the answer, act on it
- Code reads from top to bottom
- Easy to reason about

✅ **Immediate answer**
- Caller knows at once if work succeeded
- User sees real result or real error
- No "processing..." state

✅ **Easier debugging**
- One request has one path
- One place where it failed
- Stack traces show the full chain

✅ **No in-between state**
- When call returns, work is done
- Strong consistency

#### What Synchronous Communication Costs You

❌ **Both services must be running at once**
- If receiving service is down, caller fails too
- Tight coupling between services

❌ **Waiting adds up**
- Service A calls B (100ms)
- B calls C (100ms)
- C calls D (100ms)
- User waits 300ms total

❌ **Availability multiplies down**
```
5 services, each 99.9% available
Total availability = 0.999^5 ≈ 99.5%

The system is LESS available than any individual service!
```

❌ **Failures spread backwards**
- Slow service makes caller hold connections open
- Caller becomes slow too
- One slow service can stop entire system
- **Mitigation**: Timeouts, retries, circuit breakers

```python
# Circuit breaker pattern
class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN

    def call(self, func):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = func()
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
            raise e
```

**Key insight**: In a synchronous chain, delays add up, availability multiplies down, and a slow service makes every caller slow.

### Asynchronous Communication

**Definition**: The caller does not wait for work to be done. It writes a message to a queue and continues immediately.

**Components**:
- **Broker**: Separate service managing the queue (Kafka, RabbitMQ, Amazon SQS)
- **Producer**: Service that writes messages
- **Consumer**: Service that reads messages and does work at its own speed

#### What Asynchronous Communication Gives You

✅ **Caller returns quickly**
- Waits only for queue to accept message
- Not for work itself
- Fast response to user

✅ **Failures stay contained**
- If email service is down, messages wait in queue
- Order still succeeds
- Emails sent when service comes back

✅ **Traffic spikes are absorbed**
- Burst of traffic makes queue longer
- Not failures
- Consumers work through it at their own rate

**Example**: Database handles 2,000 writes/sec
```
Traffic spikes to 5,000 writes/sec for 60 seconds

Without queue:
- 3,000 writes/sec fail or timeout
- Users see errors

With queue:
- Extra 3,000 writes/sec wait in queue
- After 60 seconds: 3,000 × 60 = 180,000 messages in queue
- Traffic drops to 500 writes/sec
- Backlog shrinks by 1,500 msg/sec
- Queue clears in 180,000 / 1,500 = 120 seconds
```

✅ **Each side scales separately**
- Queue grows? Add consumers
- Producer doesn't change
- Independent scaling

✅ **Producer doesn't need to know consumers**
- Write "order placed" to topic
- Every subscriber gets own copy
- Adding subscriber requires no change to producer
- **Note**: Plain queue = one consumer per message
- **Topic/fanout** = all subscribers get copy

#### What Asynchronous Communication Costs You

❌ **Users can see the delay**
- Order exists, but email not sent yet
- Interface should show honestly: "processing..."
- **Eventual consistency** (see Strong vs Eventual Consistency)

❌ **Broker to run**
- Queue is real infrastructure
- Must be operated, monitored, paid for
- Another potential failure point

❌ **Duplicate messages**
- Most queues promise **at-least-once delivery**
- Message never lost, but can arrive twice
- Consumer must be **idempotent**
- Doing same work twice = same effect as once

```python
class IdempotentPaymentProcessor:
    def __init__(self):
        self.processed_payment_ids = set()

    async def process_payment(self, payment_id: str, amount: float):
        # Check if already processed
        if payment_id in self.processed_payment_ids:
            print(f"Payment {payment_id} already processed, skipping")
            return

        # Process payment
        await charge_card(amount)

        # Mark as processed
        self.processed_payment_ids.add(payment_id)
        await db.save_processed_payment(payment_id)
```

❌ **Order not always kept**
- Messages can arrive in different order than sent
- Queues that keep order usually do so only for same key (e.g., same order ID)
- This limits throughput

❌ **Harder debugging**
- One user action becomes several separate pieces
- **Solution**: Correlation ID shared across all messages

```python
import uuid

# When user places order
correlation_id = str(uuid.uuid4())

# All related messages carry same ID
queue.publish("order-placed", {
    "correlation_id": correlation_id,
    "order_id": order_id,
    "user_id": user_id
})

queue.publish("send-email", {
    "correlation_id": correlation_id,
    "order_id": order_id,
    "email": user_email
})

# Logs and traces can be searched by correlation_id
```

❌ **Quiet failures**
- Nobody waiting for result
- Consumer can fail repeatedly without notice
- **Solution**: Dead letter queue (DLQ) + alerts

```python
class ConsumerWithDLQ:
    def __init__(self, max_retries=3):
        self.max_retries = max_retries

    async def process_message(self, message):
        retry_count = message.get("retry_count", 0)

        try:
            await do_work(message)
            await queue.ack(message)
        except Exception as e:
            if retry_count >= self.max_retries:
                # Move to dead letter queue
                await dlq.publish(message)
                await alert_team(f"Message failed {self.max_retries} times: {message}")
                await queue.ack(message)
            else:
                # Retry with exponential backoff
                message["retry_count"] = retry_count + 1
                delay = 2 ** retry_count * 1000  # 1s, 2s, 4s, etc.
                await queue.requeue(message, delay=delay)
```

### Getting an Answer Back

Asynchronous doesn't mean caller can never get a result. Common patterns:

#### 1. Accept and Notify (HTTP 202 Accepted)

```python
from fastapi import FastAPI, BackgroundTasks

app = FastAPI()

@app.post("/videos/upload")
async def upload_video(file: UploadFile, background_tasks: BackgroundTasks):
    # Accept upload immediately
    video_id = str(uuid.uuid4())

    # Save to storage
    await save_video(video_id, file)

    # Queue processing
    background_tasks.add_task(process_video, video_id)

    # Return immediately with job ID
    return {
        "video_id": video_id,
        "status": "processing",
        "status_url": f"/videos/{video_id}/status"
    }, 202

@app.get("/videos/{video_id}/status")
async def get_video_status(video_id: str):
    status = await db.get_video_status(video_id)
    return {
        "video_id": video_id,
        "status": status,  # "processing", "completed", "failed"
        "result_url": f"/videos/{video_id}" if status == "completed" else None
    }
```

**Client options for getting result**:
- **Polling**: Check status endpoint periodically
- **Webhooks**: Server sends HTTP request to client when done
- **WebSockets**: Real-time push notification

#### 2. Request-Reply Over Queues

```python
class AsyncRequestReply:
    async def request(self, request_data):
        correlation_id = str(uuid.uuid4())

        # Send request to request queue
        await request_queue.publish({
            "correlation_id": correlation_id,
            "data": request_data,
            "reply_to": "reply-queue"
        })

        # Wait for reply on reply queue
        reply = await reply_queue.consume(
            filter_by={"correlation_id": correlation_id},
            timeout=30
        )

        return reply
```

**Note**: This brings back waiting you were trying to remove. Check if direct synchronous call would be simpler.

### How to Choose

Ask the same question: **does the caller need the result to continue?**

#### Use Synchronous When:

✅ Answer decides what happens next:
- Checking password
- Authorizing payment
- Checking stock before confirming order
- Reading data to display on page
- User must see true result right now

#### Use Asynchronous When:

✅ Work is a side effect, slow, or both:
- Emails, notifications, analytics
- Search indexing
- Image or video processing
- Work that takes seconds or minutes
- Spiky traffic (queue cheaper than servers for busiest minute)

**Most real requests use both**:
```
Place Order:
1. Charge card (synchronous) ← user waits
2. Save order (synchronous) ← user waits
3. Publish "order placed" message (synchronous to queue)
   ↓
4. Email service consumes (async)
5. Warehouse consumes (async)
6. Analytics consumes (async)
7. Recommendations consume (async)

User waits only for #1-3
```

### Comparison Table

| Aspect | Synchronous | Asynchronous |
|--------|-------------|--------------|
| **Caller** | Waits for result | Continues immediately |
| **Both sides running at once** | Required | Not required |
| **Delay user sees** | Whole chain of calls | Time to accept message |
| **Dependency fails** | Request fails | Work waits in queue |
| **Traffic spike** | Hits services directly | Makes queue longer |
| **Consistency** | Immediate | Eventual |
| **Extra infrastructure** | None | Broker required |
| **Main danger** | Failure spreads to callers | Duplicate/out-of-order messages |

### Implementation Examples

#### Synchronous (Python/FastAPI)

```python
from fastapi import FastAPI, HTTPException

app = FastAPI()

@app.post("/orders")
async def create_order(order: Order):
    # Synchronous call 1: Charge card
    payment_result = await payment_service.charge(
        card_token=order.card_token,
        amount=order.total
    )

    if not payment_result.success:
        raise HTTPException(status_code=400, detail="Payment failed")

    # Synchronous call 2: Save order
    saved_order = await db.orders.insert_one({
        "user_id": order.user_id,
        "items": order.items,
        "payment_id": payment_result.id,
        "status": "confirmed"
    })

    # Return immediately - user waited only for payment + save
    return {"order_id": saved_order.id, "status": "confirmed"}
```

#### Asynchronous (Python with Queue)

```python
import asyncio
from typing import Dict

@app.post("/orders")
async def create_order(order: Order):
    # Synchronous part (user waits)
    payment_result = await payment_service.charge(order.card_token, order.total)
    if not payment_result.success:
        raise HTTPException(status_code=400, detail="Payment failed")

    saved_order = await db.orders.insert_one({...})

    # Asynchronous part (user doesn't wait)
    correlation_id = str(uuid.uuid4())

    await queue.publish("order-placed", {
        "correlation_id": correlation_id,
        "order_id": saved_order.id,
        "user_id": order.user_id,
        "items": order.items,
        "total": order.total
    })

    return {
        "order_id": saved_order.id,
        "status": "confirmed",
        "notification_status": "sending"
    }

# Separate consumers
class EmailConsumer:
    async def consume(self):
        async for message in queue.subscribe("order-placed"):
            try:
                await send_confirmation_email(
                    user_id=message["user_id"],
                    order_id=message["order_id"]
                )
                await queue.ack(message)
            except Exception as e:
                await handle_failure(message, e)

class WarehouseConsumer:
    async def consume(self):
        async for message in queue.subscribe("order-placed"):
            try:
                await notify_warehouse(
                    order_id=message["order_id"],
                    items=message["items"]
                )
                await queue.ack(message)
            except Exception as e:
                await handle_failure(message, e)
```

#### TypeScript/Next.js with Queue

```typescript
// app/api/orders/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { publishToQueue } from '@/lib/queue';

export async function POST(request: NextRequest) {
  const order = await request.json();

  // Synchronous: charge and save (user waits)
  const paymentResult = await chargeCard(order.cardToken, order.total);
  if (!paymentResult.success) {
    return NextResponse.json(
      { error: 'Payment failed' },
      { status: 400 }
    );
  }

  const savedOrder = await db.order.create({
    data: {
      userId: order.userId,
      items: order.items,
      paymentId: paymentResult.id,
      status: 'confirmed'
    }
  });

  // Asynchronous: publish to queue (user doesn't wait)
  await publishToQueue('order-placed', {
    orderId: savedOrder.id,
    userId: order.userId,
    items: order.items
  });

  return NextResponse.json({
    orderId: savedOrder.id,
    status: 'confirmed'
  });
}

// workers/email-consumer.ts
import { consumeQueue } from '@/lib/queue';

async function main() {
  await consumeQueue('order-placed', async (message) => {
    await sendConfirmationEmail(message.userId, message.orderId);
  });
}

main();
```

### Using This in an Interview

When you add a queue, **say what you gain and what it costs** in 1-2 sentences:

> "Emails go through a queue, so an email outage cannot fail an order. The user sees that the confirmation is being sent."

#### Common Follow-up Questions

**Q1: "What if a message is delivered twice?"**

A: Make consumers idempotent. Store each processed payment ID, and skip messages already handled.

```python
processed_ids = set()

def process_payment(payment_id, amount):
    if payment_id in processed_ids:
        return  # Already processed

    charge_card(amount)
    processed_ids.add(payment_id)
    db.save_processed_payment(payment_id)
```

**Q2: "What if a consumer keeps failing?"**

A: Use retries with exponential backoff. Move messages that keep failing to dead letter queue with alerts.

**Q3: "Why not make everything synchronous?"**

A: Use availability numbers. Five services at 99.9% each give user ~99.5%. Every call moved to queue removes that service's failures from what user waits for. The broker takes its place, so it must be more available than the service it replaced.

```
Without queue:
User → Service A (99.9%) → Service B (99.9%) → Service C (99.9%)
Total: 0.999³ ≈ 99.7%

With queue:
User → Service A (99.9%) → Queue (99.99%)
Service B and C consume async (don't affect user experience)
Total: 0.999 × 0.9999 ≈ 99.89%
```

### Integration with Architecture Principles

#### YAGNI (You Aren't Gonna Need It)

**Don't add async complexity prematurely**:

```python
# ❌ Bad - premature optimization
@app.post("/orders")
async def create_order(order: Order):
    # Everything through queues!
    await queue.publish("charge-card", {...})
    await queue.publish("save-order", {...})
    await queue.publish("send-email", {...})
    # User sees "processing" for everything

# ✅ Good - simple first
@app.post("/orders")
async def create_order(order: Order):
    # Synchronous for what user needs
    payment = await charge_card(...)
    saved = await save_order(...)
    # Return immediately
    return saved

# Then, AFTER profiling shows email is slow:
# Move only email to queue
```

#### SRP (Single Responsibility Principle)

**Separate sync/async concerns**:

```typescript
// ❌ Bad - mixed concerns
class OrderService {
  async createOrder(order: Order) {
    // Sync logic
    const payment = await this.chargeCard(order);
    const saved = await this.saveOrder(order);

    // Queue logic mixed in
    await this.queue.publish('order-placed', saved);
    await this.emailService.sendConfirmation(saved);

    return saved;
  }
}

// ✅ Good - separated
class OrderService {
  async createOrder(order: Order): Promise<Order> {
    const payment = await this.chargeCard(order);
    return await this.saveOrder(order);
  }
}

class OrderEventPublisher {
  async publishOrderCreated(order: Order): Promise<void> {
    await this.queue.publish('order-placed', {
      orderId: order.id,
      userId: order.userId
    });
  }
}

class OrderController {
  async handleCreateOrder(request: Request) {
    // Orchestrate sync and async
    const order = await this.orderService.createOrder(request.body);
    await this.eventPublisher.publishOrderCreated(order);
    return order;
  }
}
```

### Practice Questions

**Q1: Placing an order involves six jobs: charge card, save order, send email, notify warehouse, update recommendations, record analytics. Which should be synchronous?**

<details>
<summary>Show answer</summary>

Only charge card and save order should be synchronous.

- **Charge card**: The result decides if order exists
- **Save order**: Must confirm it's saved before returning to user
- **Email, warehouse, recommendations, analytics**: All side effects that can happen later

The user waits for 2 operations, the other 4 happen asynchronously via queue.
</details>

**Q2: A request passes synchronously through five services. Each is 99.9% available. What's total availability, and downtime in a 30-day month?**

<details>
<summary>Show answer</summary>

Total availability = 0.999⁵ ≈ 0.995 = 99.5%

Downtime = 0.5% of 30 days
- 30 days = 30 × 24 × 60 = 43,200 minutes
- 0.5% = 0.005 × 43,200 = 216 minutes = **3.6 hours**

Compare to single service at 99.9%:
- 0.1% = 0.001 × 43,200 = 43.2 minutes

Adding services reduces availability!
</details>

**Q3: Database handles 2,000 writes/sec. Traffic jumps to 5,000 writes/sec for 60 seconds. Queue sits in front. How many messages wait after spike? If traffic drops to 500 writes/sec, how long to clear backlog?**

<details>
<summary>Show answer</summary>

**During spike**:
- Excess writes = 5,000 - 2,000 = 3,000/sec
- Duration = 60 seconds
- Messages in queue = 3,000 × 60 = **180,000 messages**

**Clearing backlog**:
- Database capacity = 2,000 writes/sec
- New traffic = 500 writes/sec
- Clearing rate = 2,000 - 500 = 1,500 messages/sec
- Time to clear = 180,000 / 1,500 = **120 seconds (2 minutes)**

Without queue, 3,000 writes/sec would fail for 60 seconds = 180,000 failed writes.
</details>

**Q4: Payment consumer reads from queue with at-least-once delivery. One message is delivered twice, customer charged twice. What's the fix?**

<details>
<summary>Show answer</summary>

Make the consumer idempotent:

```python
class IdempotentPaymentProcessor:
    async def process(self, payment_id: str, amount: float):
        # Check if already processed
        if await db.payment_processed_exists(payment_id):
            logger.info(f"Payment {payment_id} already processed")
            return

        # Process payment
        await charge_card(amount)

        # Record as processed (atomic operation)
        await db.save_processed_payment(payment_id)
```

Store processed payment IDs in database. Check before processing. This ensures charging same payment ID twice has no effect.
</details>

**Q5: Users upload videos that take ~10 minutes to process. Should upload request wait for processing? What should design look like?**

<details>
<summary>Show answer</summary>

**No**, don't wait 10 minutes. Use accept-and-notify pattern:

```python
@app.post("/videos/upload")
async def upload_video(file: UploadFile):
    # Accept upload immediately
    video_id = str(uuid.uuid4())
    await storage.save(video_id, file)

    # Queue processing
    await queue.publish("video-uploaded", {"video_id": video_id})

    # Return 202 Accepted immediately
    return {
        "video_id": video_id,
        "status": "processing",
        "status_url": f"/videos/{video_id}/status"
    }, 202

@app.get("/videos/{video_id}/status")
async def get_status(video_id: str):
    video = await db.videos.find_one({"id": video_id})
    return {
        "status": video["status"],  # "processing", "completed", "failed"
        "url": video["url"] if video["status"] == "completed" else None
    }
```

**Notification options**:
1. **Polling**: Client checks status endpoint every few seconds
2. **Webhooks**: Server calls client's URL when done
3. **WebSockets**: Real-time push to open connection

For user-facing app, polling or WebSocket is typical.
</details>

## Key Takeaways

✅ **Synchronous**:
- Caller waits for result
- Simple, immediate answer
- Ties services together: delays add, availability multiplies down

✅ **Asynchronous**:
- Caller continues immediately
- Failures stay contained, spikes absorbed
- Requires broker, eventual consistency, duplicate handling

✅ **Decision rule**:
- Need result to continue? → Synchronous
- Side effect or slow work? → Asynchronous
- Most real requests use both

✅ **Availability math**:
- 5 services at 99.9% = 99.5% total (synchronous chain)
- Moving work to queue removes that service from what user waits for

✅ **Common patterns**:
- Accept-and-notify (HTTP 202) for long work
- Idempotent consumers for duplicate messages
- Dead letter queue + alerts for quiet failures
- Circuit breakers for cascading failures

## See Also

- `caching-patterns.md` - Write-Through and Write-Behind are forms of sync/async data updates
- `principes-architectures.md` - SRP: separate sync and async concerns
- Push vs Pull Architecture (coming soon) - Related: who initiates communication?
- Strong vs Eventual Consistency (coming soon) - Consequence of async communication

## Summary

**Synchronous** gives certainty now. **Asynchronous** gives resilience and speed for the caller.

The best systems use both: synchronous for work the user needs, asynchronous for everything else.

Every call you move from synchronous to asynchronous removes one service's availability from the multiplication that determines what the user experiences. That is the core trade-off.
