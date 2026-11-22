---
name: implement-fullstack
description: Implement a fullstack feature with backend and frontend engineers working in parallel, then integrate and review
---

# Implement Fullstack

## Purpose

Implement a complete fullstack feature by running FastAPI and Next.js engineers **in parallel**, ensuring clean integration between backend and frontend.

This command is optimized for speed when both backend and frontend work is required.

## Orchestration

### Step 1: Split Feature (Sequential)

**Purpose**: Analyze the feature and create clear contracts for backend and frontend

**Analysis**:
- Extract API contract (endpoints, request/response shapes)
- Identify backend responsibilities (data model, business logic, validation)
- Identify frontend responsibilities (UI, state management, forms)
- Define integration points (API calls, error handling)

**Output**:
- Backend task description with API contract
- Frontend task description with API contract
- Shared TypeScript types for API

### Step 2: Parallel Implementation (PARALLEL ⚡)

**fastapi-engineer** and **nextjs-engineer** run simultaneously

#### fastapi-engineer
**Input**:
- Backend task description
- API contract (endpoints, schemas)
- Optional: `--tdd` flag

**Tools**: Read, Write, Edit, Bash, Grep, Glob

**Output**:
- FastAPI routes, models, services
- Pydantic schemas
- Tests (if `--tdd`)
- Backend implementation report

#### nextjs-engineer
**Input**:
- Frontend task description
- API contract (endpoints, TypeScript types)
- Optional: `--tdd` flag

**Tools**: Read, Write, Edit, Bash, Grep, Glob

**Output**:
- React components, hooks, server actions
- TypeScript types (matching backend)
- Tests (if `--tdd`)
- Frontend implementation report

**Key**: Both agents work at the same time using the shared API contract

### Step 3: Integration Check (Sequential)

**Purpose**: Verify backend and frontend integrate correctly

**Checks**:
- [ ] TypeScript types match Pydantic schemas
- [ ] API endpoints called by frontend exist in backend
- [ ] Error handling on both sides
- [ ] Status codes handled correctly (200, 400, 404, 500)
- [ ] Authentication/authorization consistent

**If mismatches found**: Report and suggest fixes

### Step 4: Code Review (Sequential)

**Purpose**: Review all changes against architecture principles

**Agent**: code-reviewer

**Input**: All changes from both engineers

**Tools**: Read, Grep, Bash (git)

**Output**: Review comments following DRY, SRP, Strategy pattern

## Flow Control

- [x] Step 1 runs first (sequential)
- [x] Step 2 runs in parallel (fastapi-engineer || nextjs-engineer)
- [x] Step 3 waits for Step 2 to complete
- [x] Step 4 runs after Step 3
- [x] If `--tdd` flag provided → both engineers work test-first
- [x] If integration check fails → report issues, don't review yet
- [x] Data passed: API contract defined in Step 1, used by both Step 2 agents

## Error Handling

- **Step 1 (Split) fails**: Cannot parse feature description → ask user for clarification
- **fastapi-engineer fails**: Frontend may still succeed → report partial completion with integration warnings
- **nextjs-engineer fails**: Backend may still succeed → report partial completion with integration warnings
- **Both engineers fail**: Report both failures, suggest splitting the task
- **Integration check fails**: Report mismatches, suggest which agent should fix what
- **Review finds issues**: Report as normal review, suggest fixes

## Usage

```bash
/ai-agents:implement-fullstack [--tdd] <feature description>
```

**Examples**:

```bash
# Basic usage
/ai-agents:implement-fullstack Add user authentication with email/password

# With TDD
/ai-agents:implement-fullstack --tdd Add todo CRUD API and UI

# Complex feature
/ai-agents:implement-fullstack --tdd Create order placement flow:
  - Backend: validate stock, calculate total, create order
  - Frontend: cart summary, payment form, confirmation page
```

## Implementation Example

**User request**: `/ai-agents:implement-fullstack --tdd Add user profile editing`

**Step 1**: Split feature
```
API Contract:
- PATCH /api/users/{id}
  Request: { name?: string, email?: string, avatar_url?: string }
  Response: { id: string, name: string, email: string, avatar_url: string | null }
  Errors: 400 (validation), 404 (not found), 401 (unauthorized)

Backend tasks:
- Update User model if needed
- Add PATCH endpoint with validation
- Write tests for validation rules

Frontend tasks:
- Create ProfileEditForm component
- Add useUpdateProfile hook
- Handle loading, success, error states
- Write component tests
```

**Step 2**: Call both agents in parallel
```python
# Orchestrator calls Task twice in ONE message:

Task({
  "prompt": """
    Implement user profile editing backend:

    API Contract:
    - PATCH /api/users/{id}
      Request: { name?: string, email?: string, avatar_url?: string }
      Response: { id: string, name: string, email: string, avatar_url: string | null }

    Tasks:
    1. Add Pydantic schema: UserUpdateRequest
    2. Add endpoint: PATCH /api/users/{id}
    3. Validate: email format, name length
    4. Return 404 if user not found

    Use TDD: write tests first.
  """,
  "subagent_type": "ai-agents:fastapi-engineer",
  "description": "Backend user profile editing"
})

Task({
  "prompt": """
    Implement user profile editing frontend:

    API Contract:
    - PATCH /api/users/{id}
      Request: { name?: string, email?: string, avatar_url?: string }
      Response: { id: string, name: string, email: string, avatar_url: string | null }

    Tasks:
    1. Create ProfileEditForm.tsx with controlled inputs
    2. Create useUpdateProfile hook using TanStack Query
    3. Show loading spinner during save
    4. Show success message on 200
    5. Show error message on 400/404/500

    Use TDD: write tests first.
  """,
  "subagent_type": "ai-agents:nextjs-engineer",
  "description": "Frontend user profile editing"
})

# Both run simultaneously ⚡
```

**Step 3**: Check integration
- Backend returns `{ id, name, email, avatar_url }`
- Frontend expects `{ id, name, email, avatar_url }` ✅
- Error codes match ✅
- TypeScript types align with Pydantic schemas ✅

**Step 4**: Review both implementations for DRY, SRP, etc.

## Advantages of This Command

✅ **Parallel execution**: Backend + frontend at the same time = 2x faster
✅ **Clear contract**: API defined upfront prevents integration issues
✅ **Independent work**: Agents don't block each other
✅ **Automatic integration check**: Catches mismatches before review
✅ **Full review**: All code reviewed together for consistency

## When NOT to Use This Command

❌ Feature is backend-only → use `/ai-agents:implement` with fastapi-engineer
❌ Feature is frontend-only → use `/ai-agents:implement` with nextjs-engineer
❌ API contract unclear → clarify requirements first
❌ Backend depends on frontend or vice versa → can't parallelize, use sequential

## Notes

- This command assumes backend and frontend can be developed independently once the API contract is defined
- If agents touch the same files, git conflicts possible → orchestrator should detect and merge
- Both agents use the same `--tdd` flag for consistency
- Integration check uses TypeScript compiler to verify type compatibility
- References: `referentiel/principes-architectures.md`, `referentiel/system-design-tradeoffs.md` (Synchronous vs Asynchronous)
