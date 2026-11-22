---
name: architecture-implement
description: Implement features and fixes following architecture principles (SRP, DRY, YAGNI, business logic placement, no boolean parameters, design patterns as remedy). Use when implementing new code or making changes to ensure clean architecture from the start.
---

# Architecture-Driven Implementation

Implement features and fixes while applying architecture principles. These principles guide design decisions **without overengineering**.

## Principles Source

**ALWAYS read** `referentiel/principes-architectures.md` before implementing to load the current principles.

This skill applies:
- **SRP** (Single Responsibility Principle) - `referentiel/principes-architectures.md#srp`
- **DRY** (Don't Repeat Yourself) - `referentiel/principes-architectures.md#dry`
- **YAGNI** (You Aren't Gonna Need It) - `referentiel/principes-architectures.md#yagni`
- **Business Logic Placement** - `referentiel/principes-architectures.md#business-logic-placement`
- **Code Smells** - `referentiel/principes-architectures.md#code-smells`
- **No Boolean Parameters** - `referentiel/principes-architectures.md#no-boolean-parameters`
- **Design Patterns** - `referentiel/principes-architectures.md#design-patterns`

## Before You Write Code

### 1. Load Principles

```
Read referentiel/principes-architectures.md
```

This ensures you're using the current, authoritative definitions.

### 2. Identify Where Business Logic Belongs

See `referentiel/principes-architectures.md#business-logic-placement` for the rule.

Ask yourself:
- Which app/module owns this responsibility?
- Does the logic file already exist? (`logic.py`, `service.ts`)
- Am I tempted to add logic to a model? → Move it to logic file
- Am I accessing another app's data to apply logic? → Feature envy

**File structure reference**: `referentiel/principes-architectures.md#file-naming`

### 3. Name the Pain First (Design Patterns)

**Critical**: Design patterns are a **remedy**, never a goal.

See `referentiel/principes-architectures.md#design-patterns` for full guidance.

Before reaching for a pattern, **name the specific friction**:

```
❌ "I should use Strategy here"
✅ "I have payment providers spread across 3 files — routing friction"

❌ "Let me add a Factory"
✅ "Object creation logic duplicated in 5 places — creation centralization needed"
```

**Only use a pattern if**:
1. You can name the friction precisely
2. Problem appears 2-3+ times (rule of three)
3. Simple code tried and failed
4. Pattern reduces complexity

**Decision tree**: See `referentiel/principes-architectures.md#decision-tree`

## While Writing Code

### 4. Apply Core Principles

For each principle's details, see `referentiel/principes-architectures.md`:

#### SRP (Single Responsibility)
- Each function/class has **one reason to change**
- If you need "and"/"or" to describe it → split it
- Keep layers separate

#### DRY (Don't Repeat Yourself)
- One piece of **knowledge**, one representation
- Same business rule in 2+ places? → Extract
- Wait for 2-3 occurrences before abstracting

#### YAGNI (You Aren't Gonna Need It)
- Solve **today's problem**, not hypothetical future
- No "just in case" abstractions
- Start simple, refactor when pain is **real**

### 5. Avoid Code Smells

See `referentiel/principes-architectures.md#code-smells` for details:

Watch for:
- **Duplicated knowledge**: Same rule in multiple places
- **Mystery boolean**: `func(data, True)` - unclear meaning
- **None for behavior**: `func(filter=None)` changes what function does
- **Feature envy**: Accessing another app's data to apply logic
- **Business logic in model**: Logic that belongs in logic.py

### 6. No Boolean Parameters

See `referentiel/principes-architectures.md#no-boolean-parameters` for alternatives:

1. Two separate functions
2. Enum for distinct modes
3. Original value when boolean represents data
4. Options dataclass for multiple related booleans

## Implementation Workflow

### Step 1: Plan with Principles in Mind

Before coding:
1. Which app/file does this logic belong to?
2. What is this function's **one** responsibility?
3. Am I solving today's problem or a hypothetical future one?
4. If I need a pattern, what **specific friction** does it solve?

### Step 2: Write the Simplest Thing First

- Start with straightforward, readable code
- Inline first, extract when you see duplication (2-3 times)
- Use guard clauses instead of nested ifs
- Clear names over clever code

### Step 3: Refactor with Principles

After the basic solution works:
- **DRY**: Did I duplicate knowledge? Extract it
- **SRP**: Is each piece doing one thing? Split if not
- **Boolean params**: Replace with clearer alternatives
- **Conditionals**: 3+ elif? Consider Dictionary Dispatch
- **Patterns**: Only if you have a **named friction** that's not solved by simpler refactoring

### Step 4: Naming and Structure

**Files**: Name after what they do
- `logic.py` / `service.ts` - business logic
- `validators.py` - validation rules
- `handlers.py` / `controllers.ts` - request handling

**Functions**: Should clearly state their purpose
- `calculate_discount` not `process`
- `save_user_and_notify` not `save_user(user, True)`

## Red Flags During Implementation

Stop and reconsider if:
- You're adding logic to a model when a logic file exists
- You're checking another app's data to apply business rules (feature envy)
- A function needs "and" to describe it
- You're adding a boolean parameter
- You're using `None` to change function behavior
- You're adding a pattern but can't name the specific pain it solves
- You're adding abstraction "for future flexibility"
- The "solution" is longer than the problem

## Decision Checklist

Before committing code, verify:

✅ **Business logic**: In the right app's logic file?
✅ **SRP**: Each function has one clear responsibility?
✅ **DRY**: No duplicated business rules?
✅ **YAGNI**: Solving actual problem, not hypothetical?
✅ **Code smells**: No mystery booleans, None-switching, or duplicated knowledge?
✅ **Boolean params**: Replaced with clearer alternatives?
✅ **Patterns**: Only if solving a named, real friction?
✅ **Guard clauses**: Used to flatten nested conditionals?
✅ **Files**: Named after their purpose?

## Examples

### Example 1: Payment Processing

**Initial thought**: "I need to handle multiple payment providers"

**❌ Wrong approach**: Immediately create Strategy pattern with abstract base class

**✅ Right approach**:
1. Start simple: One payment provider, straightforward function in `payments/logic.py`
2. Add second provider when actually needed
3. See duplication: routing logic appears in 2 places
4. **Name the friction**: "Provider routing spread across files"
5. Now apply pattern: Dictionary Dispatch or Strategy

```python
# Start: Simple, one provider
def process_payment(order, card):
    return stripe.charge(order.amount, card)

# Later: Second provider needed
def process_payment(order, card, provider):
    if provider == "stripe":
        return stripe.charge(order.amount, card)
    elif provider == "paypal":
        return paypal.charge(order.amount, card)

# Friction appears: routing in multiple places
# Now pattern makes sense:
PAYMENT_HANDLERS = {
    "stripe": stripe_handler,
    "paypal": paypal_handler,
}

def process_payment(order, card, provider):
    handler = PAYMENT_HANDLERS.get(provider)
    if handler is None:
        raise ValueError(f"Unknown provider: {provider}")
    return handler(order, card)
```

### Example 2: User Notification

**Task**: Send welcome email after user creation

**❌ Wrong**:
```python
# In models.py
class User(Model):
    def save(self, send_email=False):  # Boolean param!
        super().save()
        if send_email:  # Business logic in model!
            send_welcome_email(self.email)
```

**✅ Right**:
```python
# In users/logic.py (business logic home)
def create_user(user_data):
    user = User(**user_data)
    user.save()
    return user

def create_user_and_notify(user_data):
    user = create_user(user_data)
    send_welcome_email(user.email)
    return user

# Two clear functions, no boolean parameter
# Logic in the right place
```

### Example 3: Report Generation

**Task**: Generate reports in multiple formats

**❌ Wrong**: Builder pattern for 2 parameters
```python
report = ReportBuilder().data(data).format("pdf").build()
```

**✅ Right**: Start simple
```python
# Just starting: one format
def generate_pdf_report(data): ...

# Second format needed: straightforward branching
def generate_report(data, format):
    if format == "pdf":
        return generate_pdf(data)
    return generate_csv(data)

# Third format + complexity grows:
# Now name friction: "Format-specific logic scattered"
# Apply pattern: Strategy or Dictionary Dispatch
```

## Working with Existing Code

When modifying existing code:
1. **Don't make it worse**: Follow existing patterns in that file unless refactoring
2. **Boy Scout Rule**: Leave it cleaner than you found it
3. **Refactor scope**: Clean up what you touch, not the entire codebase
4. **Extract when duplicating**: If your change duplicates existing knowledge, extract first

## Summary

**Three questions before writing code**:
1. Where does this logic belong? (Right app/file)
2. What is the simplest solution? (YAGNI)
3. What specific friction am I solving? (Patterns as remedy)

**Remember**: Principles guide decisions, they don't constrain them. Favor simplicity, readability, and solving real problems over architectural perfection.
