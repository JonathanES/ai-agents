# React Design Patterns

Comprehensive guide to proven React design patterns for building maintainable, reusable components.

**React Version**: 18+
**Philosophy**: Patterns are a remedy, never a goal. Use only when you can NAME the specific friction.

## Overview

React design patterns solve recurring problems:

1. **Container/Presentational** - Separate logic from UI
2. **Custom Hooks** - Reusable stateful logic
3. **Compound Components** - Flexible component composition
4. **Controlled/Uncontrolled** - Input state management
5. **Higher-Order Components (HOC)** - Component enhancement
6. **Render Props** - Logic sharing through render callbacks
7. **Provider Pattern** - Global state distribution
8. **State Reducer** - User-controlled state updates

**When to use patterns**: Only when you can identify a specific problem they solve.

## Decision Tree: Which Pattern?

```
What problem are you solving?

Need to share stateful logic across components?
├─ Modern solution → Custom Hooks
└─ Legacy solution → HOC or Render Props

Need flexible component composition?
├─ For component families → Compound Components
└─ For configuration → Props with sensible defaults

Need to manage form input state?
├─ React controls state → Controlled Component
└─ DOM controls state → Uncontrolled Component (useRef)

Need global state accessible anywhere?
├─ For React-specific → Context Provider Pattern
└─ For complex state → External library (Zustand, Redux)

Need to let users control component behavior?
└─ State Reducer Pattern

Need to enhance components with extra functionality?
├─ Preferred → Custom Hooks
└─ Legacy → Higher-Order Component (HOC)
```

## 1. Container/Presentational Pattern

### Problem

Components mix data fetching, business logic, and UI rendering.

### Solution

**Split into two types**:
- **Container** (Smart): Handles logic, data, state
- **Presentational** (Dumb): Handles UI only, receives props

### Example

**Before** (mixed concerns):
```typescript
// ❌ UserProfile mixes logic and UI
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => {
        setUser(data)
        setLoading(false)
      })
  }, [userId])

  if (loading) return <div>Loading...</div>
  if (!user) return <div>Not found</div>

  return (
    <div className="user-profile">
      <img src={user.avatar} alt={user.name} />
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </div>
  )
}
```

**After** (separated):
```typescript
// ✅ Container - handles logic
function UserProfileContainer({ userId }: { userId: string }) {
  const { user, loading, error } = useUser(userId)

  if (loading) return <LoadingSpinner />
  if (error) return <ErrorMessage error={error} />
  if (!user) return <NotFound />

  return <UserProfileView user={user} />
}

// ✅ Presentational - pure UI
interface UserProfileViewProps {
  user: User
}

function UserProfileView({ user }: UserProfileViewProps) {
  return (
    <div className="user-profile">
      <img src={user.avatar} alt={user.name} />
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </div>
  )
}

// Logic extracted to custom hook
function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    setLoading(true)
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => {
        setUser(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err)
        setLoading(false)
      })
  }, [userId])

  return { user, loading, error }
}
```

### Benefits

- ✅ Presentational components easy to test (just props)
- ✅ Reusable UI components
- ✅ Clear separation of concerns
- ✅ Easy to style (no logic mixed in)

### When to Use

- Component has both data fetching and UI
- Need to reuse UI with different data sources
- Testing UI without mocking APIs

**Modern alternative**: Server Components (Next.js 14+) are natural containers.

## 2. Custom Hooks Pattern

### Problem

Multiple components need the same stateful logic.

### Solution

Extract logic into a custom hook (function starting with `use`).

### Examples

**Form state management**:
```typescript
function useForm<T>(initialValues: T) {
  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({})

  const handleChange = (name: keyof T, value: any) => {
    setValues(prev => ({ ...prev, [name]: value }))
    // Clear error when user types
    setErrors(prev => ({ ...prev, [name]: undefined }))
  }

  const reset = () => {
    setValues(initialValues)
    setErrors({})
  }

  return {
    values,
    errors,
    handleChange,
    setErrors,
    reset,
  }
}

// Usage
function LoginForm() {
  const { values, errors, handleChange, setErrors } = useForm({
    email: '',
    password: '',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    // Validation logic...
    if (!values.email) {
      setErrors({ email: 'Required' })
      return
    }
    // Submit...
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={values.email}
        onChange={(e) => handleChange('email', e.target.value)}
      />
      {errors.email && <span>{errors.email}</span>}
    </form>
  )
}
```

**Debounced value**:
```typescript
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// Usage
function SearchInput() {
  const [query, setQuery] = useState('')
  const debouncedQuery = useDebounce(query, 500)

  useEffect(() => {
    if (debouncedQuery) {
      // API call with debounced value
      searchAPI(debouncedQuery)
    }
  }, [debouncedQuery])

  return <input value={query} onChange={(e) => setQuery(e.target.value)} />
}
```

**Local storage sync**:
```typescript
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      console.error(error)
      return initialValue
    }
  })

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)
      window.localStorage.setItem(key, JSON.stringify(valueToStore))
    } catch (error) {
      console.error(error)
    }
  }

  return [storedValue, setValue] as const
}

// Usage
function ThemeToggle() {
  const [theme, setTheme] = useLocalStorage('theme', 'light')

  return (
    <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>
      Current theme: {theme}
    </button>
  )
}
```

**Media query**:
```typescript
function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false)

  useEffect(() => {
    const media = window.matchMedia(query)
    if (media.matches !== matches) {
      setMatches(media.matches)
    }

    const listener = () => setMatches(media.matches)
    media.addEventListener('change', listener)
    return () => media.removeEventListener('change', listener)
  }, [query, matches])

  return matches
}

// Usage
function ResponsiveComponent() {
  const isMobile = useMediaQuery('(max-width: 768px)')

  return isMobile ? <MobileView /> : <DesktopView />
}
```

### Rules for Custom Hooks

1. **Must start with `use`** (enforced by linter)
2. **Call hooks at top level** (not in conditions/loops)
3. **Return what's needed**, not everything
4. **Keep them focused** (single responsibility)

### When to Use

- Same stateful logic needed in multiple components
- Complex logic that obscures component's purpose
- Side effects that should be reusable

## 3. Compound Components Pattern

### Problem

Components need flexible composition without prop drilling.

### Solution

Create a family of components that share implicit state.

### Example

**Before** (inflexible, prop drilling):
```typescript
// ❌ Rigid structure, many props
function Accordion({ items, defaultOpen, onChange }: AccordionProps) {
  return (
    <div>
      {items.map(item => (
        <div key={item.id}>
          <button onClick={() => onChange(item.id)}>{item.title}</button>
          {item.isOpen && <div>{item.content}</div>}
        </div>
      ))}
    </div>
  )
}
```

**After** (compound components):
```typescript
// ✅ Flexible, composable
interface AccordionContextValue {
  openItems: Set<string>
  toggleItem: (id: string) => void
}

const AccordionContext = createContext<AccordionContextValue | null>(null)

function Accordion({ children, defaultOpen = [] }: { children: React.ReactNode; defaultOpen?: string[] }) {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set(defaultOpen))

  const toggleItem = (id: string) => {
    setOpenItems(prev => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  return (
    <AccordionContext.Provider value={{ openItems, toggleItem }}>
      <div className="accordion">{children}</div>
    </AccordionContext.Provider>
  )
}

function AccordionItem({ id, children }: { id: string; children: React.ReactNode }) {
  return <div className="accordion-item">{children}</div>
}

function AccordionTrigger({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(AccordionContext)
  if (!context) throw new Error('AccordionTrigger must be used within Accordion')

  return (
    <button onClick={() => context.toggleItem(id)} className="accordion-trigger">
      {children}
    </button>
  )
}

function AccordionContent({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(AccordionContext)
  if (!context) throw new Error('AccordionContent must be used within Accordion')

  if (!context.openItems.has(id)) return null

  return <div className="accordion-content">{children}</div>
}

// Attach as properties for discoverability
Accordion.Item = AccordionItem
Accordion.Trigger = AccordionTrigger
Accordion.Content = AccordionContent

// Usage - maximum flexibility
function FAQPage() {
  return (
    <Accordion defaultOpen={['1']}>
      <Accordion.Item id="1">
        <Accordion.Trigger id="1">
          <h3>What is React?</h3>
          <ChevronIcon />
        </Accordion.Trigger>
        <Accordion.Content id="1">
          <p>React is a JavaScript library...</p>
        </Accordion.Content>
      </Accordion.Item>

      <Accordion.Item id="2">
        <Accordion.Trigger id="2">
          <h3>How do I install it?</h3>
        </Accordion.Trigger>
        <Accordion.Content id="2">
          <p>Run npm install react...</p>
          <CodeBlock>npm install react</CodeBlock>
        </Accordion.Content>
      </Accordion.Item>
    </Accordion>
  )
}
```

### Benefits

- ✅ Flexible composition
- ✅ No prop drilling
- ✅ Implicit state sharing
- ✅ Discoverable API (`Accordion.Item`)

### When to Use

- Building component families (Tabs, Dropdown, Menu)
- Need flexible order/structure
- Avoid massive prop lists

**Examples in popular libraries**: Radix UI, Headless UI, React Aria

## 4. Controlled vs Uncontrolled Components

### Problem

Who should own the input state: React or the DOM?

### Controlled Components

**React owns the state**:

```typescript
function ControlledInput() {
  const [value, setValue] = useState('')

  return (
    <input
      value={value} // React controls value
      onChange={(e) => setValue(e.target.value)} // React updates state
    />
  )
}
```

**Benefits**:
- Full control over input
- Can validate on every keystroke
- Can transform input (uppercase, format)
- Easy to reset/manipulate

**Use when**:
- Need validation
- Need to transform input
- Multiple inputs interact
- Need to control value programmatically

### Uncontrolled Components

**DOM owns the state**:

```typescript
function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null)

  const handleSubmit = () => {
    console.log(inputRef.current?.value) // Read value from DOM
  }

  return (
    <>
      <input ref={inputRef} defaultValue="Initial" /> {/* DOM controls value */}
      <button onClick={handleSubmit}>Submit</button>
    </>
  )
}
```

**Benefits**:
- Less code
- Better performance (no re-renders)
- Easier integration with non-React code

**Use when**:
- Simple forms
- Don't need instant validation
- Performance matters (many inputs)
- File inputs (must be uncontrolled)

### Decision Tree

```
Do you need to validate on every keystroke?
├─ Yes → Controlled
└─ No → Do you need to transform input?
    ├─ Yes → Controlled
    └─ No → Do multiple inputs depend on each other?
        ├─ Yes → Controlled
        └─ No → Uncontrolled (simpler)
```

### Mixed Approach

**Controlled validation + Uncontrolled submission**:

```typescript
function MixedForm() {
  const [errors, setErrors] = useState<Record<string, string>>({})
  const formRef = useRef<HTMLFormElement>(null)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    // Validate, but don't store value
    if (!e.target.value) {
      setErrors(prev => ({ ...prev, [e.target.name]: 'Required' }))
    } else {
      setErrors(prev => {
        const next = { ...prev }
        delete next[e.target.name]
        return next
      })
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const formData = new FormData(formRef.current!)
    const email = formData.get('email')
    // Submit...
  }

  return (
    <form ref={formRef} onSubmit={handleSubmit}>
      <input name="email" onChange={handleChange} />
      {errors.email && <span>{errors.email}</span>}
      <button type="submit">Submit</button>
    </form>
  )
}
```

## 5. Higher-Order Component (HOC)

### Problem

Need to enhance multiple components with same functionality.

### Solution

Function that takes a component and returns a new enhanced component.

### Example

**Authentication HOC**:
```typescript
function withAuth<P extends object>(Component: React.ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { user, loading } = useAuth()

    if (loading) return <LoadingSpinner />
    if (!user) return <Navigate to="/login" />

    return <Component {...props} />
  }
}

// Usage
const ProtectedDashboard = withAuth(Dashboard)
const ProtectedSettings = withAuth(Settings)
```

**Logging HOC**:
```typescript
function withLogging<P extends object>(Component: React.ComponentType<P>, componentName: string) {
  return function LoggedComponent(props: P) {
    useEffect(() => {
      console.log(`${componentName} mounted`)
      return () => console.log(`${componentName} unmounted`)
    }, [])

    return <Component {...props} />
  }
}

const LoggedUserProfile = withLogging(UserProfile, 'UserProfile')
```

### Rules for HOCs

1. **Don't mutate component**, wrap it
2. **Pass unrelated props through** to wrapped component
3. **Use displayName** for debugging
4. **Don't use HOCs inside render** (creates new component each time)

### When to Use

**Prefer Custom Hooks** (modern approach):
```typescript
// ✅ Preferred modern approach
function Dashboard() {
  const { user, loading } = useAuth()

  if (loading) return <LoadingSpinner />
  if (!user) return <Navigate to="/login" />

  return <div>Dashboard content</div>
}
```

**Use HOC when**:
- Working with legacy code
- Need to wrap class components
- Library pattern (like `withRouter` in React Router v5)

## 6. Render Props Pattern

### Problem

Share logic between components without HOCs.

### Solution

Component with a prop that is a function, used to determine what to render.

### Example

**Before** (duplicated logic):
```typescript
function UserProfile() {
  const { user, loading } = useUser()
  if (loading) return <Spinner />
  return <div>{user.name}</div>
}

function UserSettings() {
  const { user, loading } = useUser()
  if (loading) return <Spinner />
  return <div>Settings for {user.name}</div>
}
```

**After** (render props):
```typescript
interface UserLoaderProps {
  render: (user: User) => React.ReactNode
}

function UserLoader({ render }: UserLoaderProps) {
  const { user, loading, error } = useUser()

  if (loading) return <Spinner />
  if (error) return <ErrorMessage error={error} />
  if (!user) return <NotFound />

  return <>{render(user)}</>
}

// Usage
function UserProfile() {
  return (
    <UserLoader
      render={(user) => (
        <div>
          <h1>{user.name}</h1>
          <p>{user.bio}</p>
        </div>
      )}
    />
  )
}

function UserSettings() {
  return (
    <UserLoader
      render={(user) => (
        <div>
          <h2>Settings for {user.name}</h2>
          <SettingsForm userId={user.id} />
        </div>
      )}
    />
  )
}
```

**Children as function** (alternative syntax):
```typescript
interface UserLoaderProps {
  children: (user: User) => React.ReactNode
}

function UserLoader({ children }: UserLoaderProps) {
  const { user, loading, error } = useUser()
  // Same logic...
  return <>{children(user)}</>
}

// Usage
<UserLoader>
  {(user) => (
    <div>{user.name}</div>
  )}
</UserLoader>
```

### When to Use

**Prefer Custom Hooks** (modern approach):
```typescript
// ✅ Cleaner with hooks
function UserProfile() {
  const { user, loading, error } = useUser()
  if (loading) return <Spinner />
  return <div>{user.name}</div>
}
```

**Use Render Props when**:
- Working with legacy code
- Need to control rendering from parent
- Component library pattern (like Downshift, React Query v3)

## 7. Provider Pattern (Context)

### Problem

Pass data through component tree without prop drilling.

### Solution

React Context API with Provider/Consumer pattern.

### Example

**Theme provider**:
```typescript
interface ThemeContextValue {
  theme: 'light' | 'dark'
  toggleTheme: () => void
}

const ThemeContext = createContext<ThemeContextValue | null>(null)

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light')

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light')
  }

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  )
}

// Custom hook for consuming context
export function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}

// Usage
function App() {
  return (
    <ThemeProvider>
      <Header />
      <Main />
      <Footer />
    </ThemeProvider>
  )
}

function Header() {
  const { theme, toggleTheme } = useTheme()
  return (
    <header className={theme}>
      <button onClick={toggleTheme}>Toggle theme</button>
    </header>
  )
}
```

**Auth provider**:
```typescript
interface User {
  id: string
  name: string
  email: string
}

interface AuthContextValue {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  loading: boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check if user is logged in on mount
    checkAuth().then(user => {
      setUser(user)
      setLoading(false)
    })
  }, [])

  const login = async (email: string, password: string) => {
    const user = await loginAPI(email, password)
    setUser(user)
  }

  const logout = () => {
    logoutAPI()
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

// Usage
function ProtectedRoute() {
  const { user, loading } = useAuth()

  if (loading) return <Spinner />
  if (!user) return <Navigate to="/login" />

  return <Dashboard />
}
```

### Performance Optimization

**Problem**: Context updates re-render all consumers.

**Solution**: Split contexts or use selectors.

```typescript
// ❌ Bad - all consumers re-render on any change
const AppContext = createContext({ user, theme, notifications, settings })

// ✅ Good - separate concerns
const UserContext = createContext({ user })
const ThemeContext = createContext({ theme })
const NotificationsContext = createContext({ notifications })
```

**Or use external state manager** (Zustand, Jotai):
```typescript
import { create } from 'zustand'

const useStore = create((set) => ({
  user: null,
  theme: 'light',
  setUser: (user) => set({ user }),
  setTheme: (theme) => set({ theme }),
}))

// Only re-renders when user changes
function UserProfile() {
  const user = useStore((state) => state.user)
  return <div>{user?.name}</div>
}
```

### When to Use Context

- Truly global data (auth, theme, locale)
- Data needed by many distant components
- Avoid prop drilling 5+ levels deep

**Don't use for**:
- Frequent updates (use external state)
- Data only needed in 2-3 components (pass props)
- Performance-critical state

## 8. State Reducer Pattern

### Problem

Users need to control or extend component behavior.

### Solution

Expose reducer for custom state transitions.

### Example

**Toggle with state reducer**:
```typescript
type ToggleState = { on: boolean }
type ToggleAction = { type: 'toggle' } | { type: 'reset' }

function toggleReducer(state: ToggleState, action: ToggleAction): ToggleState {
  switch (action.type) {
    case 'toggle':
      return { on: !state.on }
    case 'reset':
      return { on: false }
    default:
      return state
  }
}

interface UseToggleOptions {
  initialOn?: boolean
  reducer?: (state: ToggleState, action: ToggleAction) => ToggleState
}

function useToggle({ initialOn = false, reducer = toggleReducer }: UseToggleOptions = {}) {
  const [state, dispatch] = useReducer(reducer, { on: initialOn })

  const toggle = () => dispatch({ type: 'toggle' })
  const reset = () => dispatch({ type: 'reset' })

  return { on: state.on, toggle, reset }
}

// Usage 1: Default behavior
function SimpleToggle() {
  const { on, toggle } = useToggle()
  return <Switch on={on} onClick={toggle} />
}

// Usage 2: Custom behavior (limit toggles)
function LimitedToggle() {
  const { on, toggle } = useToggle({
    reducer(state, action) {
      const changes = toggleReducer(state, action)
      // User intercepts state changes
      if (this.toggleCount >= 4) {
        return state // Don't allow more toggles
      }
      return changes
    }
  })

  return <Switch on={on} onClick={toggle} />
}
```

### When to Use

- Building libraries/component systems
- Users need to customize behavior
- Complex state logic that users might extend

**Examples**: Downshift, React Table

## Integration with Architecture Principles

### SRP (Single Responsibility Principle)

**One pattern, one problem**:
```typescript
// ✅ Good - hook does one thing
function useAuth() {
  // Only handles authentication
}

function useTheme() {
  // Only handles theming
}

// ❌ Bad - does too much
function useApp() {
  // Handles auth, theme, notifications, settings...
}
```

### DRY (Don't Repeat Yourself)

**Extract repeated logic into hooks**:
```typescript
// ❌ Repeated
function ComponentA() {
  const [data, setData] = useState(null)
  useEffect(() => {
    fetch('/api/data').then(res => res.json()).then(setData)
  }, [])
}

function ComponentB() {
  const [data, setData] = useState(null)
  useEffect(() => {
    fetch('/api/data').then(res => res.json()).then(setData)
  }, [])
}

// ✅ DRY
function useData(url: string) {
  const [data, setData] = useState(null)
  useEffect(() => {
    fetch(url).then(res => res.json()).then(setData)
  }, [url])
  return data
}
```

### YAGNI (You Aren't Gonna Need It)

**Don't prematurely apply patterns**:
```typescript
// ❌ Over-engineered for simple case
function useCounter() {
  const [state, dispatch] = useReducer(counterReducer, { count: 0 })
  // Complex reducer for simple increment...
}

// ✅ YAGNI - simple case, simple solution
function useCounter() {
  const [count, setCount] = useState(0)
  return { count, increment: () => setCount(c => c + 1) }
}
```

**Add complexity only when needed**:
1. Start with useState
2. If logic complex → useReducer
3. If shared → Custom hook
4. If global → Context
5. If performance issue → External state library

## Common Anti-Patterns

| Anti-Pattern | Why Bad | Fix |
|--------------|---------|-----|
| Unnecessary HOCs | Hooks are simpler | Use custom hooks |
| Deep prop drilling (5+ levels) | Hard to maintain | Use Context or state library |
| Massive Context providers | Performance, re-renders | Split contexts or use selectors |
| Render props everywhere | Verbose, hard to read | Use custom hooks |
| Uncontrolled when need validation | Can't validate | Use controlled |
| Controlled when unnecessary | Performance overhead | Use uncontrolled with ref |
| useState for derived state | Bugs, sync issues | Calculate from props/state |
| Premature optimization | Complexity without benefit | YAGNI - add patterns when needed |

## Pattern Selection Checklist

Before applying a pattern:

- [ ] Can I name the specific problem this solves?
- [ ] Have I tried a simpler solution first?
- [ ] Does this pattern align with SRP/DRY/YAGNI?
- [ ] Will other developers understand this pattern?
- [ ] Is the added complexity worth it?

**Remember**: Patterns are a remedy, never a goal.

## See Also

- `referentiel/principes-architectures.md` - Architecture principles
- `referentiel/atomic-design-frontend.md` - Component hierarchy
- `referentiel/nextjs-14-patterns.md` - Next.js specific patterns
- React Patterns: https://www.patterns.dev/
- Kent C. Dodds - Application State Management: https://kentcdodds.com/blog/application-state-management-with-react

## Summary

**Modern React (2024+) pattern priorities**:

1. **Custom Hooks** (preferred) - Share stateful logic
2. **Context** - Global state (auth, theme)
3. **Compound Components** - Flexible composition
4. **Controlled Components** - Forms with validation
5. **Container/Presentational** - Separate logic from UI

**Legacy patterns** (use only when necessary):
- Higher-Order Components (HOCs)
- Render Props

**Core principle**: Start simple (useState, props), add complexity only when you can name the problem the pattern solves.
