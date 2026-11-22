# Principes d'Architecture

Principes fondamentaux à appliquer lors de l'écriture et de la revue de code, sans sur-ingénierie.

## Single Responsibility Principle (SRP)

**Principe**: Une classe, une fonction ou un module doit avoir une seule raison de changer.

**En pratique**:
- Chaque unité de code doit avoir une responsabilité unique et bien définie
- Si vous avez du mal à nommer une fonction sans utiliser "et" ou "ou", elle fait probablement trop de choses
- Les fonctions doivent être courtes et faire exactement ce que leur nom indique
- Facilite les tests, la maintenance et la compréhension du code

**Exemple**:
```typescript
// ❌ Mauvais: responsabilités multiples
function processUserAndSendEmail(user: User) {
  validateUser(user);
  saveToDatabase(user);
  sendWelcomeEmail(user.email);
}

// ✅ Bon: responsabilités séparées
function processUser(user: User) {
  validateUser(user);
  saveToDatabase(user);
}

function sendWelcomeEmail(email: string) {
  // ...
}
```

## DRY (Don't Repeat Yourself)

**Principe**: Une connaissance, une représentation. Chaque élément de connaissance doit avoir une représentation unique et non ambiguë dans le système.

**En pratique**:
- Éviter la duplication de logique métier, pas seulement de code
- Si vous modifiez une règle métier, vous ne devriez le faire qu'à un seul endroit
- Attention: DRY concerne la duplication de **connaissance**, pas nécessairement de code similaire
- Ne pas abstraire prématurément: attendez de voir le pattern apparaître 2-3 fois

**Exemple**:
```typescript
// ❌ Mauvais: règle de validation dupliquée
function validateUserEmail(email: string) {
  return email.includes('@') && email.length > 5;
}

function validateAdminEmail(email: string) {
  return email.includes('@') && email.length > 5;
}

// ✅ Bon: règle centralisée
function isValidEmail(email: string): boolean {
  return email.includes('@') && email.length > 5;
}
```

**Attention**: Des codes similaires peuvent représenter des connaissances différentes. Ne pas abstraire si les raisons de changement sont différentes.

## YAGNI (You Aren't Gonna Need It)

**Principe**: N'implémentez pas quelque chose tant que ce n'est pas nécessaire.

**En pratique**:
- Résoudre le problème actuel, pas les problèmes hypothétiques futurs
- Pas de couches d'abstraction "au cas où"
- Pas de paramètres de configuration "pour plus tard"
- Pas de générateurs de code complexes pour gagner du temps "à l'avenir"
- Commencer simple, refactoriser quand le besoin se présente réellement

**Exemple**:
```typescript
// ❌ Mauvais: sur-ingénierie anticipée
interface DataSource {
  fetch(): Promise<Data>;
}

class DatabaseSource implements DataSource { /* ... */ }
class APISource implements DataSource { /* ... */ }
class CacheSource implements DataSource { /* ... */ }

// Alors qu'on n'utilise qu'une seule source de données

// ✅ Bon: solution simple pour le besoin actuel
async function fetchFromDatabase(): Promise<Data> {
  // ...
}

// On ajoutera l'abstraction quand un deuxième cas d'usage apparaîtra
```

## Placement de la Logique Métier

**Principe**: La logique métier vit dans le fichier de logique de l'app. Pas dans un modèle, pas dans une autre app.

**En pratique**:
- Chaque app/module possède son propre fichier de logique (ex: `logic.py`, `service.ts`)
- Les modèles ne contiennent que les données et validations simples
- Éviter le "feature envy": ne pas accéder aux données d'une autre app pour y appliquer de la logique
- Si vous devez manipuler les données d'une autre app, exposez une fonction dans la logique de cette app

**Exemple**:
```python
# ❌ Mauvais: logique métier dans le modèle
class Order(Model):
    total = DecimalField()

    def apply_discount(self, user):
        if user.is_premium:
            self.total *= 0.9
        return self.total

# ❌ Mauvais: feature envy - une app qui manipule les données d'une autre
# Dans orders/logic.py
def process_order(order):
    user = order.user
    if user.loyalty_points > 100:  # Accès à la logique de l'app users
        user.loyalty_points -= 100
        order.total *= 0.95

# ✅ Bon: logique dans le bon fichier
# Dans orders/logic.py
def process_order(order):
    discount = users_logic.calculate_discount(order.user)
    order.total *= (1 - discount)

# Dans users/logic.py
def calculate_discount(user):
    if user.loyalty_points > 100:
        return 0.05
    return 0
```

## Nommage des Fichiers

**Principe**: Les fichiers sont nommés d'après ce qu'ils font.

**En pratique**:
- `logic.py` / `service.ts`: contient la logique métier
- `validators.py`: contient les validations
- `serializers.py` / `schemas.ts`: contient les schémas de données
- `handlers.py` / `controllers.ts`: contient les gestionnaires de requêtes
- `utils.py` / `helpers.ts`: utilitaires génériques (à utiliser avec parcimonie)

Le nom du fichier doit immédiatement indiquer son rôle dans l'application.

## Code Smells

Signaux d'alerte qui indiquent un problème de conception:

### Duplicated Knowledge (Connaissance Dupliquée)

```python
# ❌ Mauvais: même règle métier à deux endroits
def can_user_edit_post(user, post):
    return user.id == post.author_id or user.is_admin

def can_user_delete_post(user, post):
    return user.id == post.author_id or user.is_admin

# ✅ Bon: une seule source de vérité
def can_user_manage_post(user, post):
    return user.id == post.author_id or user.is_admin
```

### Mystery Boolean (Booléen Mystérieux)

```python
# ❌ Mauvais: que signifie True?
process_payment(order, True)
send_email(user, False)

# ✅ Bon: intention claire
process_payment(order, include_tax=True)
send_email(user, is_welcome_email=False)
```

### None pour Choisir un Comportement

```python
# ❌ Mauvais: None change le comportement
def get_users(filter=None):
    if filter is None:
        return User.objects.all()
    else:
        return User.objects.filter(**filter)

# ✅ Bon: comportements explicites séparés
def get_all_users():
    return User.objects.all()

def get_filtered_users(filter):
    return User.objects.filter(**filter)
```

## Règle: Pas de Paramètres Booléens

**Principe**: Les paramètres booléens rendent le code difficile à lire au point d'appel. Utilisez des alternatives plus explicites.

### Alternatives:

#### 1. Deux fonctions séparées
```python
# ❌ Mauvais
def save_user(user, send_email):
    user.save()
    if send_email:
        send_welcome_email(user)

save_user(user, True)  # Que fait True?

# ✅ Bon
def save_user(user):
    user.save()

def save_user_and_notify(user):
    save_user(user)
    send_welcome_email(user)

save_user_and_notify(user)  # Intention claire
```

#### 2. Enum
```python
# ❌ Mauvais
def export_data(data, format_as_json):
    if format_as_json:
        return json.dumps(data)
    return csv_export(data)

# ✅ Bon
from enum import Enum

class ExportFormat(Enum):
    JSON = "json"
    CSV = "csv"

def export_data(data, format: ExportFormat):
    if format == ExportFormat.JSON:
        return json.dumps(data)
    return csv_export(data)

export_data(data, ExportFormat.JSON)  # Très clair
```

#### 3. Valeur Originale
```python
# ❌ Mauvais
def filter_products(include_archived):
    if include_archived:
        return Product.objects.all()
    return Product.objects.filter(archived=False)

# ✅ Bon
def filter_products(archived: Optional[bool] = None):
    qs = Product.objects.all()
    if archived is not None:
        qs = qs.filter(archived=archived)
    return qs

filter_products(archived=True)   # Clair
filter_products(archived=False)  # Clair
filter_products()                # Tous les produits
```

#### 4. Options Dataclass
```typescript
// ❌ Mauvais
function createReport(data, includeCharts, includeRawData, sendEmail) {
  // ...
}

createReport(data, true, false, true); // Incompréhensible

// ✅ Bon
interface ReportOptions {
  includeCharts: boolean;
  includeRawData: boolean;
  sendEmail: boolean;
}

function createReport(data: Data, options: ReportOptions) {
  // ...
}

createReport(data, {
  includeCharts: true,
  includeRawData: false,
  sendEmail: true
}); // Très clair au point d'appel
```

## Design Patterns: Solutions aux Problèmes Récurrents

**Références**:
- [I Replaced Every if in My Python Code with This Pattern](https://medium.com/@chrisburkeonline/i-replaced-every-if-in-my-python-code-with-this-pattern-mind-blown-9e6e0d9e3d7a) par chris
- [5 Design Patterns I Often See In Production Python Code](https://medium.com/@zlliu/5-design-patterns-i-often-see-in-production-python-code-a1b2c3d4e5f6) par Liu Zuo Lin
- [Stop Memorizing Design Patterns: Use This Decision Tree Instead](https://medium.com/@alina.kovtun/stop-memorizing-design-patterns-use-this-decision-tree-instead-1a2b3c4d5e6f) par Alina Kovtun

### Principe Général

**Les design patterns sont un remède, jamais un objectif.**

Ne recommandez un pattern que pour une friction réelle et nommable. Les patterns ne sont pas des solutions à mémoriser, mais des réponses à des **douleurs spécifiques**.

Utilisez-les uniquement quand:
- Vous avez un problème concret et récurrent que vous pouvez **nommer** ("routing de commandes", "construction complexe", "subsystème difficile à utiliser")
- La solution simple ne suffit plus
- Le pattern réduit la complexité au lieu de l'augmenter

**Ne pas** utiliser de patterns:
- Par anticipation ("ça pourrait servir un jour")
- Pour impressionner ou "bien faire"
- Quand 2-3 lignes de code simple suffisent
- Juste après avoir appris le pattern
- Si vous ne pouvez pas nommer précisément la douleur que vous résolvez

### Arbre de Décision: Où Est la Douleur?

Avant de choisir un pattern, identifiez le problème réel:

```
Quel est le problème?
│
├─ Création d'objets complexe ou répétitive
│  └─ Patterns: Factory, Builder
│
├─ Branching sur un type/statut/provider
│  └─ Patterns: Strategy, Dictionary Dispatch
│
├─ Subsystème complexe difficile à utiliser
│  └─ Pattern: Facade
│
├─ Comportement qui change selon le contexte
│  └─ Patterns: Strategy, State
│
└─ Conditionnels imbriqués (if/elif hell)
   └─ Solutions: Guard Clauses, Dictionary Dispatch, Strategy
```

### Patterns les Plus Utiles

#### 1. Dictionary Dispatch: Remplacer les if/elif Chains

**Quand**: Vous routez des commandes, gérez des types, ou mappez une valeur à une action.

**Signal**: Plus de 3 `elif` qui font du routing.

```python
# ❌ Avant: if/elif hell
def handle_command(command, data):
    if command == "create":
        return create_record(data)
    elif command == "update":
        return update_record(data)
    elif command == "delete":
        return delete_record(data)
    elif command == "archive":
        return archive_record(data)
    else:
        raise ValueError(f"Unknown: {command}")

# ✅ Après: Dictionary Dispatch
HANDLERS = {
    "create": create_record,
    "update": update_record,
    "delete": delete_record,
    "archive": archive_record,
}

def handle_command(command, data):
    handler = HANDLERS.get(command)
    if handler is None:
        raise ValueError(f"Unknown: {command}")
    return handler(data)
```

**Avantages**:
- Ajouter une commande = une ligne dans le dictionnaire
- Le dictionnaire est une donnée inspectable et testable
- Peut être construit dynamiquement au démarrage

#### 2. Guard Clauses: Éliminer les Niveaux d'Imbrication

**Quand**: Conditionnels imbriqués qui rendent la lecture difficile.

**Signal**: Plus de 2 niveaux d'imbrication.

```python
# ❌ Avant: imbrication profonde
def process_order(order):
    if order is not None:
        if order.is_valid():
            if order.in_stock():
                charge(order)
                ship(order)
                return "Success"
            else:
                return "Out of stock"
        else:
            return "Invalid"
    else:
        return "No order"

# ✅ Après: Guard clauses
def process_order(order):
    if order is None:
        return "No order"
    if not order.is_valid():
        return "Invalid"
    if not order.in_stock():
        return "Out of stock"

    charge(order)
    ship(order)
    return "Success"
```

**Principe**: Gérez les cas d'erreur en premier et sortez immédiatement. Le chemin heureux reste visible en bas.

#### 3. Strategy Pattern: Comportements Interchangeables

**Quand**: Même opération, multiples implémentations (providers de paiement, formats d'export, algorithmes de calcul).

**Signal**: `if provider == "X"` apparaît dans plusieurs endroits.

```python
# ❌ Avant: logique éparpillée
def calculate_shipping(order, method):
    if method == "standard":
        return order.weight * 2.0
    elif method == "express":
        return order.weight * 5.0 + 10
    elif method == "overnight":
        return order.weight * 10.0 + 25

# ✅ Après: Strategy pattern
class ShippingStrategy(ABC):
    @abstractmethod
    def calculate(self, order):
        pass

class StandardShipping(ShippingStrategy):
    def calculate(self, order):
        return order.weight * 2.0

class ExpressShipping(ShippingStrategy):
    def calculate(self, order):
        return order.weight * 5.0 + 10

STRATEGIES = {
    "standard": StandardShipping(),
    "express": ExpressShipping(),
    "overnight": OvernightShipping(),
}

def calculate_shipping(order, method):
    return STRATEGIES[method].calculate(order)
```

**Combinaison**: Strategy + Dictionary Dispatch = puissance maximale.

#### 4. Factory Pattern: Centraliser la Création d'Objets

**Quand**: Le choix de l'implémentation concrète est répété dans le code.

**Signal**: `if type == "X": return ConcreteX()` apparaît dans plusieurs fichiers.

```python
# ❌ Avant: création éparpillée
# Dans handler.py
if report_type == "pdf":
    generator = PDFGenerator()
# Dans service.py
if report_type == "pdf":
    generator = PDFGenerator()

# ✅ Après: Factory centralisée
class ReportFactory:
    _generators = {
        "pdf": PDFGenerator,
        "csv": CSVGenerator,
        "html": HTMLGenerator,
    }

    @classmethod
    def create(cls, report_type):
        generator_class = cls._generators.get(report_type)
        if generator_class is None:
            raise ValueError(f"Unknown type: {report_type}")
        return generator_class()

# Utilisation partout:
generator = ReportFactory.create(report_type)
```

#### 5. Builder Pattern: Construction Complexe

**Quand**: Un objet a beaucoup de paramètres optionnels et les combinaisons valides sont importantes.

**Signal**: Constructeur avec 5+ paramètres, ou validation à l'initialisation.

```typescript
// ❌ Avant: constructeur illisible
const request = new Request(
  url,
  "POST",
  headers,
  body,
  2000,
  3,
  true,
  authToken
);

// ✅ Après: Builder
const request = new RequestBuilder()
  .url("https://api.example.com")
  .method("POST")
  .headers(authHeaders)
  .timeout(2000)
  .retries(3)
  .build();
```

**Avantages**:
- Lisibilité au point d'appel
- Validation centralisée dans `.build()`
- Peut exposer des presets ("default retry strategy")

#### 6. Facade Pattern: Simplifier un Sous-Système Complexe

**Quand**: Une librairie ou un sous-système nécessite plusieurs étapes à orchestrer.

**Signal**: Le même enchaînement d'appels est répété ou les utilisateurs font des erreurs.

```python
# ❌ Avant: utilisation complexe répétée
# Dans handler1.py
probe_result = video_prober.probe(file_path)
transcoded = transcoder.transcode(file_path, probe_result.codec)
metadata = extractor.extract(transcoded)
storage.upload(transcoded, metadata)
cleanup.remove_temp(transcoded)

# Dans handler2.py
# ... même séquence répétée

# ✅ Après: Facade
class VideoProcessor:
    def process(self, file_path):
        probe_result = self._prober.probe(file_path)
        transcoded = self._transcoder.transcode(file_path, probe_result.codec)
        metadata = self._extractor.extract(transcoded)
        self._storage.upload(transcoded, metadata)
        self._cleanup.remove_temp(transcoded)
        return metadata

# Utilisation partout:
processor.process(file_path)
```

#### 7. Decorator Pattern: Ajouter des Comportements

**Quand**: Besoin de combiner des fonctionnalités optionnelles (logging, cache, retry, validation).

**Signal**: Combinaisons explosives avec l'héritage.

```python
# En Python: utilisez les décorateurs natifs
@retry(max_attempts=3)
@log_execution
@cache_result(ttl=300)
def fetch_user_data(user_id):
    return api.get(f"/users/{user_id}")

# Ou pour des classes, le pattern Decorator classique:
class LoggingDataSource:
    def __init__(self, wrapped):
        self._wrapped = wrapped

    def fetch(self):
        logger.info("Fetching data")
        result = self._wrapped.fetch()
        logger.info(f"Got {len(result)} items")
        return result

# source = CachedDataSource(LoggingDataSource(DatabaseSource()))
```

### Quand NE PAS Utiliser de Patterns

```python
# ❌ Overkill: 2 branches n'ont pas besoin de Strategy
if user.is_admin:
    return all_records()
return user_records(user)

# ❌ Overkill: Builder pour 2 paramètres
builder = UserBuilder().name("John").email("john@test.com").build()
# ✅ Simple suffit:
User(name="John", email="john@test.com")

# ❌ Overkill: Factory pour un seul type
factory = WidgetFactory()
widget = factory.create("button")  # On ne crée que des boutons
# ✅ Simple suffit:
widget = Button()
```

**Règle**: Si le pattern ajoute plus de lignes que le problème qu'il résout, c'est trop tôt.

### Checklist d'Application de Patterns

Avant d'introduire un pattern, vérifiez:

1. **Problème concret**: Y a-t-il une douleur réelle maintenant? (Pas "pourrait devenir")
2. **Simplicité d'abord**: Avez-vous essayé la solution la plus simple?
3. **Règle de trois**: Le problème apparaît-il au moins 2-3 fois?
4. **Réduction de complexité**: Le pattern rend-il le code plus simple à comprendre?
5. **Tests**: Le pattern facilite-t-il les tests au lieu de les compliquer?

Si la réponse à une de ces questions est "non", attendez.

## Application en Revue de Code

Lors de la revue de code, posez-vous ces questions:

1. **SRP**: Cette fonction/classe a-t-elle une seule responsabilité clairement identifiable?
2. **DRY**: Cette logique existe-t-elle déjà ailleurs? Si oui, peut-on la mutualiser?
3. **YAGNI**: Cette abstraction/configuration/feature est-elle nécessaire maintenant ou est-ce de l'anticipation?
4. **Logique métier**: La logique est-elle au bon endroit? Y a-t-il du feature envy?
5. **Fichiers**: Le nom du fichier reflète-t-il clairement son rôle?
6. **Code smells**: Y a-t-il de la connaissance dupliquée, des booléens mystérieux, ou des None qui changent le comportement?
7. **Paramètres booléens**: Y a-t-il des paramètres booléens qui pourraient être remplacés par des alternatives plus explicites?
8. **Design patterns**: Si un pattern est utilisé, résout-il une friction réelle et nommable? Ou est-ce de la sur-ingénierie?

## Équilibre

Ces principes doivent guider vos décisions, pas les contraindre absolument:
- Cherchez la simplicité avant tout
- Acceptez un peu de duplication si l'abstraction est complexe
- Privilégiez la lisibilité à la perfection architecturale
- Refactorisez quand la douleur est réelle, pas anticipée
