# Next.js Project Structure: Feature-Based Architecture

Scalable project organization for React/Next.js applications that grows from solo projects to team collaborations.

**Source**: Petro Lesapiti Loltolo - "How to Structure Scalable React/Next.js Projects"

## The Problem: Layer-Based Structure Doesn't Scale

### Traditional Approach (Anti-Pattern)

```
src/
├── components/
│   ├── UserProfile.jsx
│   ├── UserAvatar.jsx
│   ├── UserSettings.jsx
│   ├── ProductCard.jsx
│   └── ... (50+ files)
├── hooks/
│   ├── useUser.js
│   └── useProducts.js
├── utils/
│   ├── userHelpers.js
│   └── productHelpers.js
└── context/
    ├── UserContext.jsx
    └── ProductContext.jsx
```

**Why this fails**:
- Related code scattered across multiple folders
- Unclear which components belong together
- Naming becomes increasingly difficult
- Can't easily delete or refactor features
- New developers can't understand what the app does

**Root cause**: Structuring by **technical layers** (components, hooks, utils) instead of by **features or domains**.

## Solution: Feature-Based Architecture

Structure projects around **features/domains**, not technical layers.

### Feature-Based Approach (Correct)

```
src/
├── features/
│   ├── user/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── utils/
│   │   ├── types/
│   │   └── index.ts
│   │
│   └── products/
│       ├── components/
│       ├── hooks/
│       ├── utils/
│       └── index.ts
```

**Benefits**:
- **Colocation**: Everything related to users lives in one folder
- **Discoverability**: See what the app does at a glance
- **Scalability**: Adding features doesn't pollute existing folders
- **Removability**: Delete feature = delete one folder
- **Team collaboration**: Minimal conflicts when working on different features

## Complete Next.js Project Structure

```
my-nextjs-app/
├── public/
│   ├── images/
│   ├── fonts/
│   └── icons/
│
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (auth)/            # Route group
│   │   │   ├── login/
│   │   │   └── register/
│   │   ├── (dashboard)/       # Route group with layout
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   └── settings/
│   │   ├── api/               # API routes
│   │   │   ├── users/
│   │   │   └── products/
│   │   ├── layout.tsx         # Root layout
│   │   ├── page.tsx           # Home page
│   │   └── globals.css
│   │
│   ├── features/              # ⭐ CORE: Feature modules
│   │   ├── auth/
│   │   ├── user/
│   │   └── products/
│   │
│   ├── components/            # Shared UI components
│   │   ├── ui/               # Atomic components
│   │   ├── layout/           # Layout components
│   │   └── providers/        # Context providers
│   │
│   ├── lib/                   # Shared utilities
│   │   ├── api/
│   │   ├── utils/
│   │   ├── constants/
│   │   └── db/
│   │
│   ├── hooks/                 # Shared hooks
│   ├── types/                 # Shared types
│   └── styles/
│
├── prisma/
├── .env.local
├── next.config.js
└── package.json
```

## Anatomy of a Feature Module

Each feature is **self-contained** with everything it needs.

```
features/
└── auth/
    ├── components/         # Feature-specific components
    │   ├── LoginForm.tsx
    │   ├── RegisterForm.tsx
    │   └── AuthProvider.tsx
    ├── hooks/              # Feature-specific hooks
    │   ├── useAuth.ts
    │   └── useSession.ts
    ├── utils/              # Feature-specific utilities
    │   ├── validation.ts
    │   └── tokenHelpers.ts
    ├── types/              # Feature-specific TypeScript types
    │   └── auth.types.ts
    ├── api/                # Feature-specific API calls
    │   └── authApi.ts
    ├── constants/          # Feature-specific constants (optional)
    │   └── authConstants.ts
    └── index.ts            # ⭐ Public API of the feature
```

### The index.ts Pattern: Controlled Exports

Each feature has an `index.ts` that **explicitly exports** what other parts can use. This creates a clear **public API**:

```typescript
// features/auth/index.ts

// Export components that other features can use
export { LoginForm } from './components/LoginForm';
export { RegisterForm } from './components/RegisterForm';

// Export hooks
export { useAuth } from './hooks/useAuth';
export { useSession } from './hooks/useSession';

// Export types
export type { User, AuthState, LoginCredentials } from './types/auth.types';

// Note: AuthProvider, validation utils, and API functions are NOT exported
// They're internal implementation details
```

**Benefits**:
- Clear separation between public and private code
- Easy to refactor internal implementation
- Prevents circular dependencies
- Makes intended usage obvious

## Component Placement Decision Tree

### Where should this component go?

```
Is it used across multiple features?
├─ Yes → Is it purely presentational (no business logic)?
│  ├─ Yes → components/ui/
│  └─ No → Reconsider: might need to split into presentational + logic
│
└─ No → Is it specific to one feature?
   ├─ Yes → features/[feature]/components/
   └─ No → Is it part of page layout?
      ├─ Yes → components/layout/
      └─ No → Reconsider component purpose
```

### Examples

**Put in `components/ui/`**:
- Used across multiple features
- Purely presentational
- Generic and configurable
- Examples: Button, Input, Card, Modal, Dropdown

**Put in `features/[feature]/components/`**:
- Specific to one feature
- Contains feature-specific business logic
- Uses feature-specific hooks or types
- Examples: LoginForm, ProductCard, UserProfile

**Put in `components/layout/`**:
- Part of page layout structure
- Used across multiple pages
- Examples: Header, Footer, Sidebar

## The lib/ Folder: Shared Utilities

Shared utilities, API clients, constants, and configuration.

```
lib/
├── api/
│   ├── client.ts           # Axios/fetch wrapper
│   ├── endpoints.ts        # API endpoint constants
│   └── types.ts           # Shared API types
│
├── utils/
│   ├── cn.ts              # Tailwind class merging
│   ├── formatters.ts      # Date, currency formatters
│   ├── validators.ts      # Shared validation functions
│   └── helpers.ts         # General helper functions
│
├── constants/
│   ├── routes.ts          # Route constants
│   ├── config.ts          # App configuration
│   └── errors.ts          # Error messages
│
└── db/
    ├── prisma.ts          # Prisma client instance
    └── queries.ts         # Shared database queries
```

### Example: API Client

```typescript
// lib/api/client.ts
import axios, { type AxiosInstance } from 'axios';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: process.env.NEXT_PUBLIC_API_URL || '/api',
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Add auth token
    this.client.interceptors.request.use((config) => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });

    // Handle unauthorized
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('auth_token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  async get<T>(url: string) { return this.client.get<T>(url); }
  async post<T>(url: string, data?: unknown) { return this.client.post<T>(url, data); }
  async put<T>(url: string, data?: unknown) { return this.client.put<T>(url, data); }
  async delete<T>(url: string) { return this.client.delete<T>(url); }
}

export const apiClient = new ApiClient();
```

### Example: Type-Safe Routes

```typescript
// lib/constants/routes.ts
export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  DASHBOARD: '/dashboard',
  PROFILE: '/profile',
  SETTINGS: '/settings',
  PRODUCTS: '/products',
  PRODUCT_DETAIL: (id: string) => `/products/${id}`,
} as const;

// Usage: router.push(ROUTES.DASHBOARD)
// Benefits: Type-safe, refactorable, consistent
```

## The hooks/ Folder: Shared Hooks

**Global hooks** used across multiple features. Feature-specific hooks stay in feature folders.

```
hooks/
├── useMediaQuery.ts      # Responsive breakpoint detection
├── useDebounce.ts        # Debounce values
├── useLocalStorage.ts    # LocalStorage with React state
├── useClickOutside.ts    # Detect clicks outside element
└── index.ts
```

### Example: useDebounce

```typescript
// hooks/useDebounce.ts
import { useEffect, useState } from 'react';

export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

// Usage: const debouncedSearch = useDebounce(searchTerm, 500);
```

## The app/ Folder: Next.js App Router

### Route Groups for Organization

Use parentheses for route groups that **don't affect the URL**:

```
app/
├── (auth)/              # Auth pages (no /auth in URL)
│   ├── login/page.tsx   # → /login
│   └── register/page.tsx # → /register
│
├── (dashboard)/         # Dashboard with shared layout
│   ├── layout.tsx       # Shared layout
│   ├── page.tsx         # → /dashboard
│   ├── products/page.tsx # → /products
│   └── settings/page.tsx # → /settings
│
├── (marketing)/         # Marketing pages
│   ├── layout.tsx       # Different layout
│   ├── about/page.tsx   # → /about
│   └── pricing/page.tsx # → /pricing
│
├── api/                 # API routes
│   ├── users/route.ts   # → /api/users
│   └── products/route.ts
│
├── layout.tsx           # Root layout
└── page.tsx             # Home (/)
```

### Example: Dashboard Layout

```typescript
// app/(dashboard)/layout.tsx
import { Header } from '@/components/layout/Header';
import { Sidebar } from '@/components/layout/Sidebar';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </div>
  );
}
```

## TypeScript Organization

### Type Placement Strategy

```
├── types/
│   ├── global.d.ts        # Global type declarations
│   ├── api.types.ts       # Shared API response types
│   └── common.types.ts    # Common types
│
└── features/
    └── user/
        └── types/
            └── user.types.ts  # Feature-specific types
```

### Example: Global Types

```typescript
// types/global.d.ts
export type ID = string | number;

export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface ApiError {
  message: string;
  code: string;
  field?: string;
}
```

## File Naming Conventions

Consistency makes code discoverable:

| Type | Convention | Example |
|------|------------|---------|
| **React Components** | PascalCase | `UserProfile.tsx`, `ProductCard.tsx` |
| **Hooks** | camelCase with "use" prefix | `useAuth.ts`, `useProducts.ts` |
| **Utilities** | camelCase | `formatDate.ts`, `validation.ts` |
| **Types** | camelCase with ".types" suffix | `user.types.ts`, `api.types.ts` |
| **Constants** | camelCase or UPPER_CASE | `routes.ts`, `API_ENDPOINTS.ts` |
| **API Files** | camelCase with "Api" suffix | `userApi.ts`, `productApi.ts` |

**Rule**: Match filename to export
- File `Button.tsx` exports `Button`
- File `useAuth.ts` exports `useAuth`

## State Management Structure

### Local vs. Global State

**Use local state** (useState, useReducer) when:
- Data only needed in one component
- Data doesn't persist across route changes
- Examples: form inputs, UI toggles, filters

**Use global state** (Zustand, Redux, Context) when:
- Data needed across multiple unrelated features
- Data persists across route changes
- Data fetched from API and cached
- Examples: authentication, theme, shopping cart

### Example: Feature State (Zustand)

```typescript
// features/auth/hooks/useAuth.ts
import { create } from 'zustand';
import { authApi } from '../api/authApi';
import type { AuthState, LoginCredentials } from '../types/auth.types';

interface AuthStore extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
}

export const useAuth = create<AuthStore>((set) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,

  login: async (credentials) => {
    const user = await authApi.login(credentials);
    set({ user, isAuthenticated: true });
  },

  logout: async () => {
    await authApi.logout();
    set({ user: null, isAuthenticated: false });
  },
}));
```

## Performance Optimization

### 1. Code Splitting by Feature

Features are naturally code-split. Use dynamic imports for heavy components:

```typescript
// app/dashboard/page.tsx
import dynamic from 'next/dynamic';

const AnalyticsChart = dynamic(
  () => import('@/features/analytics/components/AnalyticsChart'),
  {
    loading: () => <Skeleton className="h-96" />,
    ssr: false,
  }
);
```

### 2. Smart Component Exports

```typescript
// ❌ Bad: Imports everything
// features/products/index.ts
export * from './components/ProductCard';
// Imports entire feature!

// ✅ Good: Named exports
export { ProductCard } from './components/ProductCard';
// Only imports ProductCard (tree-shaking works)
```

## Testing Structure

Place tests alongside code using `.test.ts` or `.spec.ts`:

```
features/
└── products/
    ├── components/
    │   ├── ProductCard.tsx
    │   └── ProductCard.test.tsx
    ├── hooks/
    │   ├── useProducts.ts
    │   └── useProducts.test.ts
    └── utils/
        ├── productHelpers.ts
        └── productHelpers.test.ts
```

## Environment Variables

### Type-Safe Configuration

```typescript
// lib/constants/config.ts
function getEnvVar(key: string, defaultValue?: string): string {
  const value = process.env[key] || defaultValue;
  if (!value) {
    throw new Error(`Missing environment variable: ${key}`);
  }
  return value;
}

export const config = {
  app: {
    name: 'My App',
    url: getEnvVar('NEXT_PUBLIC_APP_URL', 'http://localhost:3000'),
  },
  database: {
    url: getEnvVar('DATABASE_URL'),
  },
  api: {
    url: getEnvVar('NEXT_PUBLIC_API_URL'),
    timeout: 10000,
  },
} as const;
```

## Migration Strategy

### From Messy to Structured

**Phase 1**: Create structure (don't move yet)
**Phase 2**: Move shared components to `components/ui/`
**Phase 3**: Extract first feature to `features/auth/`
**Phase 4**: Extract remaining features one by one

## Integration with Architecture Principles

This structure aligns with our core principles:

### Single Responsibility (SRP)
- Each feature has one clear domain
- Each component has one purpose
- Each function has one responsibility

### Don't Repeat Yourself (DRY)
- Shared code in `lib/` and `components/`
- Feature-specific code in feature folders
- No duplication across features

### YAGNI
- Start with simple structure
- Add features as needed
- Don't over-engineer early

### Business Logic Placement
- Business logic in feature's logic layer
- Not in components (keep them presentational)
- Not scattered across app

## Checklist

Before creating a new component/file:

- [ ] Is this feature-specific? → `features/[feature]/`
- [ ] Is this a shared UI component? → `components/ui/`
- [ ] Is this a shared utility? → `lib/utils/`
- [ ] Is this a shared hook? → `hooks/`
- [ ] Does it follow naming conventions?
- [ ] Is it exported from feature's `index.ts`?
- [ ] Does it reference `referentiel/` principles?

## See Also

- `referentiel/principes-architectures.md` - Architecture principles
- `referentiel/atomic-design-frontend.md` - Component hierarchy
- `referentiel/nextjs-14-patterns.md` - Next.js 14+ specific patterns
- `referentiel/react-design-patterns.md` - React patterns

## Summary

**Feature-based architecture** > Layer-based architecture

**Key principles**:
1. **Colocation**: Related code lives together
2. **Clear boundaries**: Public API via `index.ts`
3. **Scalability**: Add features without pollution
4. **Discoverability**: Understand app by folder structure
5. **Maintainability**: Easy to refactor and delete

**Remember**: Structure follows function. Organize by **what the code does** (features), not **what the code is** (components, hooks, utils).
