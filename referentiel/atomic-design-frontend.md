# Atomic Design Methodology for Frontend

Methodology for building frontend interfaces in a hierarchical, component-based manner.

**Source**: Brad Frost - Atomic Design (https://atomicdesign.bradfrost.com/)

## Overview

Atomic design is a methodology for creating interface design systems in a deliberate and hierarchical manner. Inspired by chemistry, it breaks interfaces into their fundamental building blocks.

**The five stages**:
1. **Atoms** - Basic building blocks
2. **Molecules** - Simple groups of atoms
3. **Organisms** - Complex components
4. **Templates** - Page-level layouts
5. **Pages** - Specific instances with real content

## Core Principle

**Not linear, but concurrent**: Atomic design is a mental model to think of UIs as both:
- A cohesive whole
- A collection of parts

Work on all levels simultaneously, not sequentially. The parts influence the whole, and the whole influences the parts.

## 1. Atoms

### Definition

The foundational building blocks that cannot be broken down further without losing their function.

### Examples

HTML elements:
- Form labels
- Inputs
- Buttons
- Headings
- Paragraphs
- Images
- Icons

### Characteristics

- **Indivisible**: Can't be broken down further
- **Intrinsic properties**: Each has unique characteristics (button styles, input types)
- **Rarely used alone**: Atoms gain meaning through application
- **Style reference**: Show all base styles at a glance

### In Code

```typescript
// atoms/Button.tsx
export const Button: React.FC<ButtonProps> = ({ children, variant = 'primary', ...props }) => (
  <button className={`btn btn-${variant}`} {...props}>
    {children}
  </button>
)

// atoms/Input.tsx
export const Input: React.FC<InputProps> = ({ label, ...props }) => (
  <div className="input-wrapper">
    <label>{label}</label>
    <input {...props} />
  </div>
)
```

**Anti-patterns**:
- ❌ Button with complex business logic
- ❌ Input that fetches its own data
- ❌ Atoms that contain other atoms (should be molecules)

## 2. Molecules

### Definition

Relatively simple groups of UI elements functioning together as a unit. Molecules take on distinct new properties when atoms bond together.

### Examples

- Search form (label + input + button)
- Card header (image + title + date)
- Navigation item (icon + text + badge)
- Social share group (multiple social buttons)

### Characteristics

- **Single responsibility**: Do one thing well
- **Portable**: Can be dropped anywhere
- **Reusable**: Same molecule in different contexts
- **Purposeful**: Atoms gain meaning when combined

### In Code

```typescript
// molecules/SearchForm.tsx
import { Input } from '../atoms/Input'
import { Button } from '../atoms/Button'

export const SearchForm: React.FC<SearchFormProps> = ({ onSearch }) => {
  const [query, setQuery] = useState('')

  return (
    <form onSubmit={() => onSearch(query)}>
      <Input
        label="Search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      <Button type="submit">Search</Button>
    </form>
  )
}
```

**Benefits**:
- Adheres to Single Responsibility Principle (SRP)
- Easy to test
- Encourages reusability
- Promotes consistency

**Anti-patterns**:
- ❌ Molecule doing too many things (should split or promote to organism)
- ❌ Molecule with complex state management (might be organism)
- ❌ Molecule fetching data (should be organism or use container pattern)

## 3. Organisms

### Definition

Relatively complex UI components composed of groups of molecules, atoms, and/or other organisms. Form distinct sections of an interface.

### Examples

- Header (logo + nav + search + user menu)
- Product grid (repeated product cards)
- Article list (repeated article cards)
- Footer (multiple navigation groups + social links + legal)

### Characteristics

- **Standalone sections**: Distinct interface regions
- **Can be complex**: Multiple molecule types
- **Can be repeated**: Same molecules repeated (product grids)
- **Demonstrate context**: Show molecules in action

### In Code

```typescript
// organisms/Header.tsx
import { Logo } from '../atoms/Logo'
import { SearchForm } from '../molecules/SearchForm'
import { Navigation } from '../molecules/Navigation'
import { UserMenu } from '../molecules/UserMenu'

export const Header: React.FC<HeaderProps> = ({ user, onSearch }) => (
  <header className="site-header">
    <Logo />
    <Navigation items={mainNavItems} />
    <SearchForm onSearch={onSearch} />
    {user && <UserMenu user={user} />}
  </header>
)

// organisms/ProductGrid.tsx
import { ProductCard } from '../molecules/ProductCard'

export const ProductGrid: React.FC<ProductGridProps> = ({ products }) => (
  <div className="product-grid">
    {products.map(product => (
      <ProductCard key={product.id} product={product} />
    ))}
  </div>
)
```

**When to create organisms**:
- Component forms a distinct section
- Multiple molecules working together
- Repeatable pattern across pages

**Anti-patterns**:
- ❌ Organism that's just a wrapper (might be template instead)
- ❌ Organism with page-specific logic (should be in page)
- ❌ Overly generic organism that doesn't add value

## 4. Templates

### Definition

Page-level objects that place components into a layout and articulate the design's underlying content structure. Focus on skeleton, not final content.

### Examples

- Homepage template (header + hero + feature grid + footer)
- Article template (header + article header + content + sidebar + footer)
- Dashboard template (header + sidebar + main content + footer)
- Product page template (header + breadcrumbs + product organism + related products + footer)

### Characteristics

- **Layout focus**: Arrange components spatially
- **Content structure**: Define image sizes, text lengths, spacing
- **No real content**: Use placeholders
- **Reusable**: Same template, different content

### In Code

```typescript
// templates/HomeTemplate.tsx
import { Header } from '../organisms/Header'
import { Hero } from '../organisms/Hero'
import { FeatureGrid } from '../organisms/FeatureGrid'
import { Footer } from '../organisms/Footer'

export const HomeTemplate: React.FC<HomeTemplateProps> = ({
  header,
  hero,
  features,
  footer
}) => (
  <div className="home-template">
    <Header {...header} />
    <main>
      <Hero {...hero} />
      <FeatureGrid features={features} />
    </main>
    <Footer {...footer} />
  </div>
)
```

**Content structure guidelines**:
```typescript
// templates/ArticleTemplate.tsx
interface ArticleTemplateProps {
  title: string        // Max 60 characters
  excerpt: string      // Max 160 characters
  heroImage: {
    src: string
    alt: string
    aspectRatio: '16:9'  // Fixed aspect
  }
  content: string
  author: AuthorData
  relatedArticles: ArticleCard[]  // Max 3
}
```

**Anti-patterns**:
- ❌ Template with actual business data
- ❌ Template with logic that should be in organism
- ❌ Template that's too specific (can't be reused)

## 5. Pages

### Definition

Specific instances of templates showing what UI looks like with real representative content. This is what users see.

### Examples

- Homepage with actual featured products
- Article page with real article content
- Dashboard with user's actual data
- Product page with specific product details

### Characteristics

- **Most concrete**: Final interface users interact with
- **Real content**: Actual text, images, media
- **Testing ground**: Verify design system effectiveness
- **Show variations**: Different content lengths, states, edge cases

### In Code

```typescript
// pages/HomePage.tsx
import { HomeTemplate } from '../templates/HomeTemplate'
import { useHomePageData } from '../hooks/useHomePageData'

export const HomePage: React.FC = () => {
  const { header, hero, features, footer } = useHomePageData()

  return (
    <HomeTemplate
      header={header}
      hero={hero}
      features={features}
      footer={footer}
    />
  )
}
```

**Testing variations**:
```typescript
// pages/HomePage.test.tsx
describe('HomePage', () => {
  it('renders with minimal content', () => {
    render(<HomePage features={[oneFeature]} />)
  })

  it('renders with maximum content', () => {
    render(<HomePage features={tenFeatures} />)
  })

  it('handles long titles gracefully', () => {
    render(<HomePage title={longTitle340Chars} />)
  })

  it('shows empty state for new users', () => {
    render(<HomePage user={newUser} />)
  })
})
```

**Variations to account for**:
- Empty states vs. populated
- Short content vs. long content
- Different user permissions
- Loading states
- Error states
- Mobile vs. desktop

**Anti-patterns**:
- ❌ Page with business logic (should be in organisms or services)
- ❌ Not testing content variations
- ❌ Hardcoding content that should come from CMS/API

## File Structure

```
src/
├── atoms/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx
│   │   └── Button.module.css
│   ├── Input/
│   └── ...
├── molecules/
│   ├── SearchForm/
│   │   ├── SearchForm.tsx
│   │   ├── SearchForm.test.tsx
│   │   └── SearchForm.module.css
│   ├── ProductCard/
│   └── ...
├── organisms/
│   ├── Header/
│   │   ├── Header.tsx
│   │   ├── Header.test.tsx
│   │   └── Header.module.css
│   ├── ProductGrid/
│   └── ...
├── templates/
│   ├── HomeTemplate/
│   │   ├── HomeTemplate.tsx
│   │   ├── HomeTemplate.test.tsx
│   │   └── HomeTemplate.module.css
│   └── ...
└── pages/
    ├── HomePage.tsx
    ├── ArticlePage.tsx
    └── ...
```

## Decision Tree

### "What level is this component?"

```
Is it a basic HTML element (button, input, heading)?
├─ Yes → Atom
└─ No → Does it combine 2-3 atoms into a simple unit?
   ├─ Yes → Molecule
   └─ No → Does it form a distinct section with multiple parts?
      ├─ Yes → Organism
      └─ No → Does it define page layout and content structure?
         ├─ Yes → Template
         └─ No → Does it have real content?
            ├─ Yes → Page
            └─ No → Re-evaluate the component's purpose
```

### "Should I split this component?"

```
Is the component doing multiple distinct things?
├─ Yes → Split into smaller molecules
└─ No → Is it hard to name without "and"?
   ├─ Yes → Split it (violates SRP)
   └─ No → Does it have complex state management?
      ├─ Yes → Might be organism, or use container pattern
      └─ No → Current level is probably correct
```

## Integration with Architecture Principles

Atomic design aligns with our architecture principles:

### Single Responsibility (SRP)

- **Atoms**: One element, one responsibility
- **Molecules**: One simple function
- **Organisms**: One distinct section

### Don't Repeat Yourself (DRY)

- Build once at the right level
- Reuse across pages
- Consistent styling and behavior

### YAGNI

- Start with atoms, build up as needed
- Don't create organisms until you need them
- Don't over-engineer molecules

### No Boolean Parameters

```typescript
// ❌ Bad
<Button primary={true} large={false} />

// ✅ Good - use variants
<Button variant="primary" size="medium" />
```

## Common Patterns

### Container/Presentational Pattern

Split data fetching from presentation:

```typescript
// organisms/ProductGridContainer.tsx (data)
export const ProductGridContainer: React.FC = () => {
  const { products, loading } = useProducts()

  if (loading) return <Skeleton />

  return <ProductGrid products={products} />
}

// organisms/ProductGrid.tsx (presentation)
export const ProductGrid: React.FC<{ products }> = ({ products }) => (
  <div className="product-grid">
    {products.map(product => <ProductCard key={product.id} product={product} />)}
  </div>
)
```

### Compound Components

For flexible, composable organisms:

```typescript
// organisms/Card/Card.tsx
export const Card = ({ children }) => <div className="card">{children}</div>
Card.Header = ({ children }) => <div className="card-header">{children}</div>
Card.Body = ({ children }) => <div className="card-body">{children}</div>
Card.Footer = ({ children }) => <div className="card-footer">{children}</div>

// Usage - flexible composition
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Body>Content</Card.Body>
  <Card.Footer>Actions</Card.Footer>
</Card>
```

### Slots Pattern (Vue-style in React)

```typescript
// templates/DashboardTemplate.tsx
interface DashboardTemplateProps {
  header: React.ReactNode
  sidebar: React.ReactNode
  main: React.ReactNode
}

export const DashboardTemplate = ({ header, sidebar, main }) => (
  <div className="dashboard">
    <header>{header}</header>
    <aside>{sidebar}</aside>
    <main>{main}</main>
  </div>
)
```

## Benefits of Atomic Design

1. **Quick context switching**: Move between detailed work and big-picture view
2. **Clean separation**: Structure (templates) vs. content (pages)
3. **Shared vocabulary**: Team communication using atoms/molecules/organisms
4. **Systematic thinking**: Build deliberately, not haphazardly
5. **Testable components**: Each level tested independently
6. **Design system foundation**: Natural fit for component libraries

## Anti-Patterns to Avoid

1. **Linear thinking**: Don't do atoms → molecules → organisms → templates → pages sequentially
2. **Wrong level**: Button that fetches data (too complex for atom)
3. **Over-nesting**: Molecule containing organisms (backward hierarchy)
4. **Skipping levels**: Page using atoms directly (should go through molecules/organisms)
5. **Generic names**: "Container", "Wrapper", "Box" (name by purpose)
6. **Logic in atoms**: Atoms should be pure presentation
7. **Tight coupling**: Organism that only works with one specific molecule

## Checklist

Before creating a component:

- [ ] What level is this? (Atom, Molecule, Organism, Template, Page)
- [ ] Does it follow SRP? (One responsibility)
- [ ] Is it reusable? (Or is it page-specific?)
- [ ] Does it fit the hierarchy? (Not mixing levels incorrectly)
- [ ] Is the name descriptive? (Reflects purpose, not generic)
- [ ] Are props well-defined? (Clear interface)
- [ ] Is it tested? (Unit tests for molecules+, integration for pages)
- [ ] Does it use existing atoms/molecules? (Build on foundation)

## See Also

- `referentiel/principes-architectures.md` - Architecture principles to apply
- Brad Frost - Atomic Design: https://atomicdesign.bradfrost.com/
- Pattern Lab: http://patternlab.io/

## Summary

Atomic design gives us a systematic way to build frontend interfaces:

1. **Atoms** - Basic building blocks (HTML elements)
2. **Molecules** - Simple combinations (search form = input + button)
3. **Organisms** - Complex sections (header = logo + nav + search + menu)
4. **Templates** - Page layouts with content structure
5. **Pages** - Final UI with real content

**Remember**: Not a waterfall, but a mental model. Work concurrently across all levels, with the parts informing the whole and vice versa.
