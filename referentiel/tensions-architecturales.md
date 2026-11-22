# Tensions Architecturales et Résolutions

Guide pour résoudre les conflits entre principes d'architecture.

## Vue d'ensemble

Les principes d'architecture créent parfois des **tensions** - situations où deux principes semblent suggérer des solutions opposées. Ce n'est pas un bug, c'est une fonctionnalité : ces tensions nous forcent à réfléchir au contexte.

**Principe méta**: Il n'y a pas de règle absolue. Les principes sont des guides, pas des lois. Le contexte décide.

## 1. DRY vs YAGNI

### Le Conflit

**DRY dit**: "Ne vous répétez pas - créez une abstraction"
**YAGNI dit**: "Vous n'en aurez pas besoin - n'ajoutez pas d'abstraction prématurément"

### Exemple du Conflit

```typescript
// Situation: Code similaire dans deux endroits

// Component A
function UserProfile() {
  const [user, setUser] = useState(null)
  useEffect(() => {
    fetch('/api/user').then(r => r.json()).then(setUser)
  }, [])

  if (!user) return <Spinner />
  return <div>{user.name}</div>
}

// Component B
function AdminProfile() {
  const [admin, setAdmin] = useState(null)
  useEffect(() => {
    fetch('/api/admin').then(r => r.json()).then(setAdmin)
  }, [])

  if (!admin) return <Spinner />
  return <div>{admin.name}</div>
}
```

**DRY dit**: Créez `useProfile(url)` maintenant
**YAGNI dit**: Attendez d'avoir 3+ cas similaires

### Règle de Résolution

**Rule of Three**: Dupliquez la première fois, notez-le la deuxième fois, refactorisez la troisième fois.

```typescript
// ✅ Après 3 répétitions, créez l'abstraction
function useProfile(url: string) {
  const [data, setData] = useState(null)
  useEffect(() => {
    fetch(url).then(r => r.json()).then(setData)
  }, [url])
  return data
}
```

### Quand Privilégier DRY

- ✅ Duplication de **logique métier** (calculs, validations)
- ✅ Duplication de **règles business** (prix, taxes, permissions)
- ✅ Duplication de **configurations** (constantes, enums)
- ✅ 3+ occurrences identiques

### Quand Privilégier YAGNI

- ✅ Seulement 2 occurrences
- ✅ Code similaire mais **contextes différents**
- ✅ Abstraction complexe pour gain minimal
- ✅ Incertitude sur la stabilité du pattern

### Checklist de Décision

```
Dois-je créer une abstraction maintenant?

Combien de fois est-ce répété?
├─ 2 fois → Attendre (YAGNI)
└─ 3+ fois → Considérer DRY
   ├─ Les contextes sont-ils identiques?
   │  ├─ Oui → Créer abstraction (DRY)
   │  └─ Non → Dupliquer (YAGNI)
   └─ L'abstraction est-elle simple?
      ├─ Oui → Créer (DRY)
      └─ Non → Attendre plus de cas (YAGNI)
```

## 2. DRY vs Couplage

### Le Conflit

**DRY encourage**: Réutilisation maximale du code
**Mais crée**: Couplage entre composants qui partagent l'abstraction

### Exemple du Conflit

```typescript
// ❌ DRY excessif - couplage fort
function useFormValidation(config: ValidationConfig) {
  // 50 options pour supporter tous les formulaires
  // Changer une option peut casser 10 formulaires
}

// Utilisé par: LoginForm, RegisterForm, ProfileForm,
// CheckoutForm, AdminForm, etc.

// Un changement pour LoginForm affecte tous les autres
```

### Règle de Résolution

**Préférez la duplication au mauvais couplage** (Sandi Metz)

> "Duplication is far cheaper than the wrong abstraction"

### Signaux de Mauvaise Abstraction

- ⚠️ Nombreux paramètres optionnels (`if (config.option1) ...`)
- ⚠️ Paramètres booléens multiples
- ⚠️ Nommé "util" ou "helper" (trop générique)
- ⚠️ Changer l'abstraction casse plusieurs usages
- ⚠️ Besoin de documentation extensive

### Solution: Abstractions Spécialisées

```typescript
// ✅ Bon - plusieurs abstractions spécialisées, moins de couplage
function useLoginValidation() {
  // Simple, spécialisé pour login
}

function useRegistrationValidation() {
  // Simple, spécialisé pour registration
}

// Peut avoir duplication, mais pas de couplage
```

**Heuristic**: Si deux usages divergent, préférez dupliquer que forcer une abstraction commune.

## 3. SRP vs Performance

### Le Conflit

**SRP dit**: "Une responsabilité par composant" → Plus de petits composants
**Performance dit**: "Réduisez les re-renders" → Moins de composants

### Exemple du Conflit

```typescript
// SRP pousse vers ceci:
function ProductPage() {
  return (
    <>
      <ProductImage />      {/* Composant séparé */}
      <ProductTitle />      {/* Composant séparé */}
      <ProductPrice />      {/* Composant séparé */}
      <ProductDescription />{/* Composant séparé */}
    </>
  )
}
// Mais chaque composant peut causer des re-renders

// Performance pousse vers ceci:
function ProductPage() {
  return (
    <div>
      <img src={product.image} />      {/* Tout inline */}
      <h1>{product.title}</h1>
      <span>{product.price}</span>
      <p>{product.description}</p>
    </div>
  )
}
// Mais tout mélangé dans un composant
```

### Règle de Résolution

**Privilégiez SRP d'abord, optimisez si nécessaire**

1. **Écrivez pour la lisibilité** (SRP)
2. **Mesurez les performances** (Profiler)
3. **Optimisez seulement si problème réel**

### Techniques de Résolution

**Memoization**:
```typescript
// ✅ SRP + Performance
const ProductImage = React.memo(function ProductImage({ src }: { src: string }) {
  return <img src={src} />
})

const ProductTitle = React.memo(function ProductTitle({ title }: { title: string }) {
  return <h1>{title}</h1>
})

// Pas de re-render si props ne changent pas
```

**Composition intelligente**:
```typescript
// ✅ Séparez les parties qui changent souvent
function ProductPage() {
  return (
    <>
      <StaticProductInfo product={product} />  {/* Ne change jamais */}
      <ProductStock stock={stock} />           {/* Change souvent */}
    </>
  )
}
```

### Quand Privilégier Performance

- ✅ Profiler montre un problème réel (>100ms)
- ✅ Listes longues (1000+ items)
- ✅ Animations 60fps critiques
- ✅ Composant mis à jour très fréquemment (chaque keystroke)

### Quand Privilégier SRP

- ✅ Pas de problème de performance mesuré
- ✅ Lisibilité et maintenabilité importantes
- ✅ Équipe doit comprendre le code facilement

## 4. Atomic Design vs Feature-Based Structure

### Le Conflit

**Atomic Design dit**: Organisez par niveau technique (atoms/molecules/organisms)
**Feature-Based dit**: Organisez par domaine métier (auth/products/checkout)

### Exemple du Conflit

```
Où mettre le composant LoginForm?

Atomic Design dit:
components/
└── organisms/
    └── LoginForm/

Feature-Based dit:
features/
└── auth/
    └── components/
        └── LoginForm/
```

### Règle de Résolution

**Hybride: Feature-based avec atomic à l'intérieur**

```
src/
├── components/              # Atomic design - composants GLOBAUX
│   ├── atoms/
│   │   ├── Button/         # Utilisé partout
│   │   └── Input/          # Utilisé partout
│   ├── molecules/
│   │   └── FormField/      # Utilisé partout
│   └── organisms/
│       └── Header/         # Header global
│
└── features/               # Feature-based - composants SPECIFIQUES
    ├── auth/
    │   └── components/     # Atomic design LOCAL
    │       ├── LoginForm/  # Organism spécifique à auth
    │       └── OAuthButtons/ # Molecule spécifique à auth
    └── products/
        └── components/
            └── ProductCard/ # Organism spécifique à products
```

### Règle de Décision

```
Où mettre ce composant?

Est-il utilisé par 3+ features?
├─ Oui → components/ (global, atomic design)
└─ Non → Est-il spécifique à une feature?
   ├─ Oui → features/{feature}/components/ (local)
   └─ Non sûr → Commencer local, déplacer si réutilisé 3+ fois
```

### Quand Privilégier Atomic (Global)

- ✅ Design system components (Button, Input, Card)
- ✅ Utilisé dans 3+ features
- ✅ Défini par les designers
- ✅ Style cohérent critique

### Quand Privilégier Feature-Based (Local)

- ✅ Logique métier spécifique
- ✅ Utilisé dans 1-2 features seulement
- ✅ Évolution indépendante souhaitée
- ✅ Contexte métier important

## 5. Server Components vs Interactivité (Next.js)

### Le Conflit

**Next.js 14+ dit**: "Server Components par défaut" (zéro JS)
**UX moderne dit**: "Interfaces riches et interactives" (beaucoup de JS)

### Exemple du Conflit

```typescript
// Server Component = no interactivity
async function ProductPage() {
  const product = await getProduct()
  return <div>{product.name}</div> // Static, no onClick
}

// Client Component = interactivity
'use client'
function ProductPage() {
  const [expanded, setExpanded] = useState(false)
  return <div onClick={() => setExpanded(!expanded)}>...</div>
}
```

### Règle de Résolution

**Server par défaut, Client par nécessité, Hybride par intelligence**

### Pattern: Server Wrapper + Client Island

```typescript
// ✅ Server Component (parent)
async function ProductPage({ id }: { id: string }) {
  const product = await getProduct(id)
  const reviews = await getReviews(id)

  return (
    <>
      {/* Static content - Server Component (no JS) */}
      <ProductHeader product={product} />
      <ProductDescription description={product.description} />

      {/* Interactive content - Client Component (JS only here) */}
      <AddToCartButton productId={product.id} />
      <ReviewForm productId={product.id} />

      {/* Static list - Server Component */}
      <ReviewList reviews={reviews} />
    </>
  )
}

// Server Component - no JS sent
function ProductHeader({ product }: { product: Product }) {
  return (
    <header>
      <h1>{product.name}</h1>
      <span>{product.price}</span>
    </header>
  )
}

// Client Component - JS only for button
'use client'
function AddToCartButton({ productId }: { productId: string }) {
  const [loading, setLoading] = useState(false)

  return (
    <button onClick={async () => {
      setLoading(true)
      await addToCart(productId)
      setLoading(false)
    }}>
      {loading ? 'Adding...' : 'Add to Cart'}
    </button>
  )
}
```

### Checklist de Décision

```
Ce composant doit-il être Client Component?

A-t-il besoin de useState, useEffect, ou autre hook?
├─ Oui → Client Component
└─ Non → A-t-il besoin d'event handlers (onClick, onChange)?
   ├─ Oui → Client Component
   └─ Non → A-t-il besoin de browser APIs (localStorage, window)?
      ├─ Oui → Client Component
      └─ Non → Server Component (default) ✅
```

### Quand Privilégier Server

- ✅ Contenu statique
- ✅ Pas d'interactivité
- ✅ Accès direct à la DB/API
- ✅ SEO important
- ✅ Performance critique

### Quand Privilégier Client

- ✅ Interactions utilisateur (clicks, hover)
- ✅ Formulaires avec validation temps réel
- ✅ Animations complexes
- ✅ State local (useState)
- ✅ Browser APIs nécessaires

## 6. No Boolean Parameters vs Lisibilité

### Le Conflit

**Principe dit**: "Pas de paramètres booléens, utilisez des enums"
**Pragmatisme dit**: "Parfois un booléen est plus clair"

### Exemple du Conflit

```typescript
// Principe dit éviter:
<Modal isOpen={true} />

// Et préférer:
<Modal state="open" />

// Mais est-ce vraiment mieux?
```

### Règle de Résolution

**Évitez les booléens pour COMPORTEMENT, acceptez-les pour ÉTAT**

### Booléens Acceptables (État)

```typescript
// ✅ Acceptables - représentent un état binaire naturel
<Checkbox checked={true} />
<Modal open={true} />
<Spinner visible={true} />
<Button disabled={true} />
<Input required={true} />

// État UI naturellement binaire
const [isLoading, setIsLoading] = useState(false)
const [isOpen, setIsOpen] = useState(false)
const [isValid, setIsValid] = useState(true)
```

**Pourquoi acceptable**: Le domaine métier est naturellement binaire.

### Booléens à Éviter (Comportement)

```typescript
// ❌ Mauvais - change le comportement
function fetchUser(id: string, useCache: boolean) {
  if (useCache) {
    // comportement A
  } else {
    // comportement B
  }
}

// ✅ Bon - deux fonctions distinctes
function fetchUser(id: string) { /* toujours avec cache */ }
function fetchUserFresh(id: string) { /* toujours sans cache */ }

// Ou enum si vraiment une option
enum CacheStrategy {
  UseCache = 'use-cache',
  FreshData = 'fresh-data',
  Revalidate = 'revalidate'
}
function fetchUser(id: string, strategy: CacheStrategy) { ... }
```

### Règle de Décision

```
Ce booléen est-il acceptable?

Représente-t-il un état naturellement binaire? (open/closed, on/off)
├─ Oui → Acceptable (isOpen, checked, disabled)
└─ Non → Change-t-il le comportement de la fonction?
   ├─ Oui → Éviter (useCache, recursive, force)
   │  └─ Utiliser: deux fonctions, enum, ou valeur originale
   └─ Non → Quelle est la sémantique?
      ├─ Ambiguë → Éviter (flag, option, mode)
      └─ Claire → Acceptable avec nom explicite
```

## 7. Static Typing vs Flexibilité

### Le Conflit

**TypeScript strict dit**: "Tout doit être typé, zéro `any`"
**Pragmatisme dit**: "Parfois `any` est plus rapide"

### Règle de Résolution

**Strict par défaut, `unknown` si nécessaire, `any` en dernier recours**

```typescript
// ❌ Mauvais - `any` cache les erreurs
function processData(data: any) {
  return data.map(item => item.value) // Erreur cachée si data pas array
}

// ⚠️ Acceptable temporairement - `unknown` force vérification
function processData(data: unknown) {
  if (Array.isArray(data)) {
    return data.map(item => item.value)
  }
  throw new Error('Data must be array')
}

// ✅ Bon - type précis
function processData(data: Array<{ value: string }>) {
  return data.map(item => item.value)
}
```

### Quand `any` est Acceptable

- ✅ Migration progressive d'un projet JS
- ✅ Prototypage rapide (à typer plus tard)
- ✅ Interop avec bibliothèque non typée (ajouter `@ts-expect-error`)
- ✅ Type impossible à exprimer (extrêmement rare)

**Important**: Toujours accompagner `any` d'un commentaire expliquant pourquoi.

## 8. Normalize vs Denormalize (State)

### Le Conflit

**Normalization dit**: "Une source de vérité, pas de duplication"
**Performance dit**: "Dupliquez pour éviter les calculs répétés"

### Exemple du Conflit

```typescript
// Normalized - pas de duplication
interface State {
  users: Record<string, User>
  posts: Record<string, Post>  // Post contient authorId
}

// Pour afficher un post avec auteur:
const post = state.posts[postId]
const author = state.users[post.authorId] // Lookup supplémentaire

// Denormalized - duplication
interface State {
  posts: Array<{
    post: Post
    author: User  // Dupliqué - aussi dans users[]
  }>
}

// Affichage direct:
const { post, author } = state.posts[index] // Pas de lookup
```

### Règle de Résolution

**Normalisez les mutations, dénormalisez la lecture**

```typescript
// ✅ Store normalized
interface NormalizedState {
  users: Record<string, User>
  posts: Record<string, Post>
}

// ✅ Selector denormalized
const selectPostWithAuthor = (state: State, postId: string) => {
  const post = state.posts[postId]
  const author = state.users[post.authorId]
  return { post, author } // Calculé, pas stocké
}

// Avec memoization
import { createSelector } from 'reselect'

const selectPostWithAuthor = createSelector(
  [(state, postId) => state.posts[postId], (state, postId) => state.users[state.posts[postId].authorId]],
  (post, author) => ({ post, author })
) // Calculé une fois, puis cached
```

### Quand Normaliser

- ✅ Données venant du backend
- ✅ Mutations fréquentes
- ✅ Relations complexes
- ✅ Besoin de cohérence

### Quand Dénormaliser

- ✅ Read-only data
- ✅ Performance critique
- ✅ Données indépendantes
- ✅ UI state local

## Tableau Récapitulatif

| Tension | Privilégier | Quand | Privilégier | Quand |
|---------|------------|-------|-------------|-------|
| **DRY vs YAGNI** | DRY | 3+ répétitions, logique métier | YAGNI | 2 répétitions, contextes différents |
| **DRY vs Couplage** | DRY | Abstractions simples, stable | Duplication | Couplage complexe, évolutions divergentes |
| **SRP vs Performance** | SRP | Par défaut, maintenabilité | Performance | Problème mesuré, profiler confirme |
| **Atomic vs Feature** | Atomic (global) | 3+ features, design system | Feature (local) | Spécifique, 1-2 features |
| **Server vs Client** | Server | Par défaut, no interactivité | Client | Hooks, events, browser APIs |
| **No Boolean vs Lisibilité** | Enum/Fonctions | Comportement | Boolean | État binaire naturel |
| **Strict Types vs Flexibilité** | Strict | Production, APIs | `unknown`/`any` | Migration, prototype |
| **Normalize vs Denormalize** | Normalize | Mutations, store | Denormalize | Lecture, selectors |

## Principe Méta: Le Contexte Décide

**Il n'y a pas de règle absolue.** Les principes sont des **guides**, pas des **lois**.

### Questions à Se Poser

Avant de trancher un conflit:

1. **Quel est l'impact réel?** (Mesurez, ne devinez pas)
2. **Qui va maintenir ce code?** (Lisibilité vs performance)
3. **Quelle est la fréquence de changement?** (Flexibilité vs optimisation)
4. **Quel est le coût de se tromper?** (Réversibilité)
5. **Qu'est-ce qui est le plus facile à changer plus tard?**

### Règle d'Or

> **Optimisez pour la facilité de changement, pas pour la perfection du moment.**

Code qui peut facilement évoluer > Code parfaitement optimisé mais figé

## Voir Aussi

- `referentiel/principes-architectures.md` - Principes de base
- `referentiel/QUICKREF.md` - Référence rapide
- Kent Beck - "Extreme Programming Explained"
- Sandi Metz - "The Wrong Abstraction"

## Résumé

Les tensions architecturales sont **normales et saines**. Elles nous forcent à:

1. **Réfléchir au contexte** plutôt qu'appliquer mécaniquement
2. **Mesurer l'impact** plutôt que deviner
3. **Prioriser la facilité de changement** plutôt que la perfection immédiate

**Heuristique finale**: Quand dans le doute, choisissez la solution qui sera la plus facile à changer plus tard.
