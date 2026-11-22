# Clean-code examples

## Strategy instead of if/else: Python / FastAPI

Before: every new provider means editing this function, and the branching is likely
repeated elsewhere.

```python
def charge(order: Order) -> Receipt:
    if order.provider == "stripe":
        ...  # stripe-specific logic
    elif order.provider == "paypal":
        ...  # paypal-specific logic
    elif order.provider == "adyen":
        ...
    else:
        raise ValueError(order.provider)
```

After: one strategy per provider, selected from a registry and injected with `Depends`.

```python
from enum import StrEnum
from typing import Protocol


class Provider(StrEnum):
    STRIPE = "stripe"
    PAYPAL = "paypal"


class PaymentStrategy(Protocol):
    def charge(self, order: Order) -> Receipt: ...


class StripePayment:
    def charge(self, order: Order) -> Receipt: ...


class PaypalPayment:
    def charge(self, order: Order) -> Receipt: ...


PAYMENT_STRATEGIES: dict[Provider, PaymentStrategy] = {
    Provider.STRIPE: StripePayment(),
    Provider.PAYPAL: PaypalPayment(),
}


def get_payment_strategy(order: Order) -> PaymentStrategy:
    return PAYMENT_STRATEGIES[order.provider]
```

## Strategy instead of switch: TypeScript / React

```ts
type Kind = "image" | "video" | "pdf";

interface PreviewStrategy {
  render(file: FileMeta): React.ReactNode;
}

const previewStrategies: Record<Kind, PreviewStrategy> = {
  image: { render: (f) => <img src={f.url} alt={f.name} /> },
  video: { render: (f) => <video src={f.url} controls /> },
  pdf: { render: (f) => <PdfViewer url={f.url} /> },
};

export function FilePreview({ file }: { file: FileMeta }) {
  return previewStrategies[file.kind].render(file);
}
```

`Record<Kind, …>` makes the compiler fail when a new `Kind` is added without a strategy.

## SRP: FastAPI route doing too much

Before:

```python
@router.post("/orders")
def create_order(payload: dict, db: Session = Depends(get_db)):
    if not payload.get("items"):
        raise HTTPException(400)
    total = sum(i["price"] * i["qty"] for i in payload["items"])
    if payload.get("coupon") == "WELCOME":
        total *= 0.9
    order = OrderModel(total=total, **payload)
    db.add(order); db.commit()
    send_email(payload["email"], f"Order total {total}")
    return order
```

After: the router handles HTTP only, the service owns the business rules, the repository owns
persistence, and validation lives in the Pydantic schema.

```python
@router.post("/orders", response_model=OrderOut, status_code=201)
def create_order(payload: OrderIn, service: OrderService = Depends(get_order_service)):
    return service.create(payload)
```

## SRP: React component doing too much

Split `useOrders()` (data), `OrdersTable` (presentation) and `formatMoney()` (pure logic,
unit-tested on its own) instead of one component that fetches, formats and renders.

## DRY: duplicated knowledge

```ts
// ❌ the same rule in two places, which will drift apart
if (user.role === "admin" || user.role === "owner") { ... }   // page.tsx
if (["admin", "owner"].includes(user.role)) { ... }           // api/route.ts

// ✅ one authoritative definition
export const canManageBilling = (u: User) => MANAGER_ROLES.has(u.role);
```
