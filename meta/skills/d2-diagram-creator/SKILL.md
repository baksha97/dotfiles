---
name: d2-diagram-creator
description: >
  Create, edit, and validate D2 (Declarative Diagramming) diagrams. Covers all D2 syntax including
  shapes, connections, containers, styling, sequence diagrams, grid diagrams, SQL tables, UML classes,
  icons, variables, imports, globs, themes, layers/scenarios/steps, and layout engines. Use when the
  user says "d2 diagram", "create diagram", "architecture diagram", "sequence diagram", "d2lang",
  "d2 file", "network diagram", "flow diagram", "declarative diagram", or wants to generate .d2 files.
  Also use when visualizing infrastructure, CI/CD pipelines, database schemas, API flows, or any
  system that benefits from a diagram — even if the user doesn't explicitly mention D2.
metadata:
  author: baksha97
  version: "2.0"
---

# D2 Diagram Creator

D2 is a declarative diagramming language that compiles text to diagrams. This skill covers both the syntax and the craft of making clear, useful diagrams.

## Workflow

Every diagram follows this loop:

1. **Understand the request** — what system/flow is being diagrammed? What's the audience?
2. **Choose the right diagram type** — architecture, sequence, grid, ER, or class
3. **Write the .d2 file** — start with structure, then layer in style
4. **Compile and validate** — run `d2 input.d2 output.svg` to catch syntax errors
5. **Iterate** — refine layout, labels, and styling based on the rendered output

Always compile after writing. A .d2 file that doesn't compile is useless. If the user wants live preview, use watch mode: `d2 --watch input.d2 output.svg`.

## CLI Reference

```bash
d2 input.d2 output.svg          # compile (also: png, pdf)
d2 --watch input.d2 output.svg  # live reload on save
d2 --layout=elk input.d2 out.svg  # choose layout engine
d2 --theme=200 input.d2 out.svg   # apply theme
d2 themes                        # list available themes
```

## Choosing a Layout Engine

The layout engine controls how nodes are positioned. Pick based on the diagram type:

| Engine | Best for | Notes |
|---|---|---|
| **dagre** (default) | Hierarchical flows, pipelines | Fast, good for top-down or left-right flows |
| **elk** | Complex architectures with many containers | Handles nested containers well, more compact |
| **tala** | Software architecture, presentation diagrams | Supports `near` positioning and per-container direction (proprietary) |

When a diagram has deeply nested containers or many cross-container connections, try `elk`. For simple flows, `dagre` is fine.

## Design Principles

**Make diagrams visually rich.** Every node should have intentional color and shape. Color-code by tier, role, or component type — orange for load balancers, green for app servers, blue for databases, grey for external services. A diagram with only default styling looks unfinished. Use `classes` to define palettes per tier, then apply them consistently.

**Color-code connections too.** Different connection types should be visually distinct. Use colored strokes to match source tiers (e.g., orange for LB routes, blue for DB writes). Use `style.stroke-dash` to distinguish read paths from write paths, or replication from live traffic. This makes traffic flow scannable at a glance.

**Use distinct shapes for each component type.** `cylinder` for databases, `hexagon` for load balancers/routers, `queue` for message queues, `person` for users, `cloud` for external/internet, `package` for deployable units, `step` for pipeline stages, `diamond` for decision gates. Shape communicates role before anyone reads the label.

**Label everything that isn't obvious.** Connections without labels force the reader to guess the relationship. Labels like "HTTPS/443", "Round Robin", "Writes", "Reads", or "Streaming Replication" communicate intent instantly.

**Use containers to show boundaries.** Group related components into containers that represent real boundaries — network zones, tiers, cloud regions, deployment targets. Give containers a tinted fill that matches their tier color (lighter shade). This is what makes architecture diagrams useful rather than just boxes-and-arrows.

**Add a title.** Use a `near: top-center` text node with `style.font-size: 28` and `style.bold: true` to label the diagram. Readers need to know what they're looking at.

**Prefer `direction: right` for most diagrams.** Horizontal layouts read more naturally for architectures (left=entry, right=data) and pipelines (left=start, right=end). Use default `down` only for strict dependency trees or org charts.

## Syntax Reference

### Shapes

```d2
# Basic declaration
server
database: PostgreSQL

# Shape types (set via shape property)
db: Database {shape: cylinder}
user: {shape: person}
mq: Events {shape: queue}
ext: Third Party {shape: cloud}
pkg: API v2 {shape: package}

# Image shape
logo: {
  shape: image
  icon: https://icons.terrastruct.com/aws/compute/ec2.svg
}
```

**All shape types:** `rectangle` (default), `square`, `page`, `parallelogram`, `document`, `cylinder`, `queue`, `package`, `step`, `callout`, `stored_data`, `person`, `diamond`, `oval`, `circle`, `hexagon`, `cloud`, `c4-person`

**Special shapes:** `image`, `sql_table`, `class`, `sequence_diagram`, `grid-diagram`

### Connections

```d2
a -> b          # directional
a <- b          # reverse
a <-> b         # bidirectional
a -- b          # line (no arrowheads)
a -> b: label   # labeled connection
a -> b -> c     # chained
a -> a: self    # self-referential
```

**Arrowhead customization:**
```d2
a -> b: {
  source-arrowhead: {
    shape: diamond  # triangle|arrow|diamond|circle|box|cf-one|cf-one-required|cf-many|cf-many-required|cross
    style.filled: true
  }
  target-arrowhead: {
    shape: arrow
    label: "1"
  }
}
```

**Reference by index** (multiple connections between same nodes):
```d2
a -> b
a -> b
(a -> b)[0].style.stroke: red
(a -> b)[1].style.stroke: blue
```

### Containers

```d2
# Block form — the primary way to show system boundaries
cloud: {
  aws: {
    load_balancer
    api
  }
}

# Dot notation (flat alternative)
cloud.aws.load_balancer

# Cross-container connections
cloud.aws.api -> gcloud.api

# Label keyword (when container needs a display name different from its key)
apartment: {
  label: "My Apartment"
  bedroom
}

# Parent reference with underscore
child: {
  inner -> _.sibling   # _ refers to parent scope
}
```

### Style Properties

```d2
myshape: {
  style: {
    fill: "#f4a261"
    stroke: red
    stroke-width: 3
    opacity: 0.5
  }
}
# or flat: myshape.style.fill: "#f4a261"
```

| Property | Values | Applies To |
|---|---|---|
| `opacity` | 0.0 - 1.0 | shapes, connections |
| `stroke` | CSS color/hex | shapes, connections |
| `fill` | CSS color/hex | shapes only |
| `fill-pattern` | `dots`, `lines`, `grain`, `paper` | shapes only |
| `stroke-width` | integer (px) | shapes, connections |
| `stroke-dash` | integer (dash length) | shapes, connections |
| `border-radius` | integer (px) | shapes only |
| `shadow` | true/false | shapes only |
| `3d` | true/false | rectangle, square |
| `multiple` | true/false | shapes only |
| `double-border` | true/false | rectangles, ovals |
| `font` | font family string | shapes, connections |
| `font-size` | integer (px) | shapes, connections |
| `font-color` | CSS color/hex | shapes, connections |
| `animated` | true/false | connections only |
| `bold` | true/false | text |
| `italic` | true/false | text |
| `underline` | true/false | text |
| `text-transform` | `uppercase`, `lowercase`, `capitalize`, `none` | text |

### Icons

```d2
myshape: {
  icon: https://icons.terrastruct.com/aws/compute/ec2.svg
  icon.near: top-right
}
```

Icon library: https://icons.terrastruct.com

### Classes (Reusable Styles)

Define classes to keep styling consistent and DRY. Use bold, saturated fills for nodes:

```d2
classes: {
  db: {
    shape: cylinder
    style.fill: "#336791"
    style.font-color: "#ffffff"
  }
  web: {
    style.fill: "#4caf50"
    style.font-color: "#ffffff"
  }
  error: {
    style.fill: "#d32f2f"
    style.font-color: "#ffffff"
  }
}

postgres.class: db
redis.class: db
broken_service.class: error
a -> b: { class: error }   # works on connections too
```

Object attributes override class attributes. Multiple classes: `node.class: [db, error]` (left-to-right precedence).

### Variables

```d2
vars: {
  primary: "#4a90d9"
  server-name: Production
}

myshape: ${server-name} {
  style.fill: ${primary}
}
```

Inner scopes inherit outer variables; closest definition wins. Prevent substitution with single quotes: `'${literal}'`.

**Config variables (set theme/layout in the file itself):**
```d2
vars: {
  d2-config: {
    theme-id: 200
    dark-theme-id: 200
    pad: 20
    layout-engine: elk
  }
}
```

### Direction

```d2
direction: right   # up | down (default) | left | right
```

Use `right` for most diagrams — architectures, pipelines, timelines. Use `down` only for strict dependency trees or org charts.

### Dimensions & Positioning

```d2
myshape: {
  width: 300
  height: 200
}
```

Cannot set width/height on containers (they auto-resize).

**`near` constants:** `top-left`, `top-center`, `top-right`, `center-left`, `center-right`, `bottom-left`, `bottom-center`, `bottom-right`

```d2
title: My Diagram {
  near: top-center
  style.font-size: 28
}
```

### Text & Markdown

```d2
explanation: |md
  # Header
  - bullet 1
  - bullet 2
  **bold** text
|

snippet: |go
  func main() {
    fmt.Println("hello")
  }
|

formula: |latex
  \frac{a}{b} = c
|
```

### Sequence Diagrams

Sequence diagram actors support the same style properties as regular shapes — give each actor a distinct fill color so the lifeline columns are visually distinct and the diagram isn't a wall of white boxes.

```d2
auth_flow: {
  shape: sequence_diagram

  browser: Browser {
    style.fill: "#1565c0"
    style.font-color: "#ffffff"
    style.bold: true
  }
  auth_server: Auth Server {
    style.fill: "#7b1fa2"
    style.font-color: "#ffffff"
    style.bold: true
  }
  api: Resource API {
    style.fill: "#2e7d32"
    style.font-color: "#ffffff"
    style.bold: true
  }

  browser -> auth_server: GET /authorize {
    style.stroke: "#1565c0"
    style.stroke-width: 2
  }
  auth_server -> browser: 302 Redirect (code) {
    style.stroke: "#2e7d32"
    style.stroke-width: 2
  }
  browser -> api: POST /token (code) {
    style.stroke: "#ff9800"
    style.stroke-width: 2
  }
  api -> auth_server: Validate code {
    style.stroke: "#e91e63"
    style.stroke-dash: 3
  }
  auth_server -> api: access_token {
    style.stroke: "#2e7d32"
  }
  api -> browser: 200 OK + token {
    style.stroke: "#2e7d32"
    style.stroke-width: 2
  }

  # Groups (fragments)
  "Token Refresh": {
    browser -> api: POST /refresh {style.stroke: "#ff9800"}
    api -> browser: new token {style.stroke: "#2e7d32"}
  }
}
```

### Grid Diagrams

```d2
mygrid: {
  grid-rows: 3        # or grid-columns: 4, or both
  grid-gap: 10         # or vertical-gap / horizontal-gap

  cell1
  cell2
  cell3
}
```

### SQL Tables

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  name: varchar(255)
  email: varchar(255) {constraint: unique}
  org_id: int {constraint: foreign_key}
}

orgs: {
  shape: sql_table
  id: int {constraint: primary_key}
  name: varchar(255)
}

users.org_id -> orgs.id
```

### UML Classes

```d2
MyClass: {
  shape: class
  +publicField: string
  -privateField: int
  #protectedField: bool
  +publicMethod(a uint64): (x, y int)
}
```

Visibility: `+` public, `-` private, `#` protected. Keys with `(` are methods.

### Tooltips & Links

```d2
myshape: {
  tooltip: "Hover info"
  link: "https://example.com"   # always quote URLs (# is comment char)
}
```

### Globs

```d2
*.style.fill: "#f0f0f0"      # all shapes in scope
* -> *                        # connect everything

container: {
  *.style.fill: red           # scoped to container
}
```

Globs apply both backward and forward.

### Imports

```d2
a: @x              # import x.d2 as value of a
...@x              # spread import (inline)
a: @x.managers     # partial import (subtree)
```

`.d2` extension auto-appended. Use quotes for dots in filenames: `@"schema-v0.1.2"`.

### Layers, Scenarios & Steps

```d2
a -> b -> c

layers: {
  detail: {
    x -> y   # independent board, no inheritance
  }
}

scenarios: {
  error: {
    b.style.fill: red   # inherits base, applies overrides
  }
}

steps: {
  step1: {
    a.style.fill: green   # inherits from base
  }
  step2: {
    b.style.fill: green   # inherits from step1
  }
}
```

| Keyword | Inheritance |
|---|---|
| `layers` | None — independent board |
| `scenarios` | Inherits from base layer |
| `steps` | Inherits from previous step |

### Themes

```bash
d2 --theme=200 input.d2 output.svg
d2 --dark-theme=200 input.d2 output.svg
d2 themes   # list all available themes
```

Or via vars: `d2-config.theme-id` (see Variables section).

### Overrides & Deletion

Redeclaring a key merges attributes; latest value wins. Delete with null: `x: null` removes shape and its connections. `x.style.fill: null` removes just fill.

### Syntax Notes

- **Comments:** `#` line comment, `""" block comment """`
- **Semicolons:** Multiple declarations on one line: `a; b; c`
- **Keys are case-insensitive**
- **Connections must use shape keys, not labels**

## Common Patterns

### Infrastructure / Architecture Diagram

```d2
direction: right

title: Network Architecture {
  near: top-center
  style.font-size: 28
  style.bold: true
}

classes: {
  web: {
    style.fill: "#4caf50"
    style.font-color: "#ffffff"
  }
  db: {
    shape: cylinder
    style.fill: "#336791"
    style.font-color: "#ffffff"
  }
}

internet: Internet {
  shape: cloud
  style.fill: "#e8f4fd"
}

lb: Load Balancer {
  shape: hexagon
  style.fill: "#ff9800"
  style.font-color: "#ffffff"
  style.bold: true
}

app: Web Servers {
  style.fill: "#e8f5e9"
  style.stroke: "#4caf50"
  web1: Web Server 1 {class: web}
  web2: Web Server 2 {class: web}
  web3: Web Server 3 {class: web}
}

data: Databases {
  style.fill: "#fce4ec"
  style.stroke: "#e91e63"
  primary: Primary PostgreSQL {class: db}
  replica: Read Replica {class: db; style.fill: "#5b8db8"}
  primary -> replica: Streaming\nReplication {
    style.stroke: "#e91e63"
    style.stroke-dash: 3
  }
}

internet -> lb: HTTPS Traffic {style.stroke: "#1565c0"; style.stroke-width: 3}
lb -> app.web1: Round Robin {style.stroke: "#ff9800"}
lb -> app.web2: Round Robin {style.stroke: "#ff9800"}
lb -> app.web3: Round Robin {style.stroke: "#ff9800"}

app.web1 -> data.primary: Writes {style.stroke: "#336791"}
app.web2 -> data.primary: Writes {style.stroke: "#336791"}
app.web3 -> data.primary: Writes {style.stroke: "#336791"}
app.web1 -> data.replica: Reads {style.stroke: "#5b8db8"; style.stroke-dash: 3}
app.web2 -> data.replica: Reads {style.stroke: "#5b8db8"; style.stroke-dash: 3}
app.web3 -> data.replica: Reads {style.stroke: "#5b8db8"; style.stroke-dash: 3}
```

### CI/CD Pipeline

```d2
direction: right

title: CI/CD Pipeline {
  near: top-center
  style.font-size: 28
  style.bold: true
}

classes: {
  stage: {
    shape: step
    style.fill: "#1565c0"
    style.font-color: "#ffffff"
  }
  test: {
    style.fill: "#7b1fa2"
    style.font-color: "#ffffff"
  }
  deploy: {
    shape: step
    style.fill: "#2e7d32"
    style.font-color: "#ffffff"
  }
}

push: Code Push {class: stage}
build: Build {class: stage}

tests: Tests {
  style.fill: "#f3e5f5"
  style.stroke: "#7b1fa2"
  unit: Unit {class: test}
  integration: Integration {class: test}
  e2e: E2E {class: test}
}

staging: Deploy Staging {class: deploy}
approval: Manual Approval {
  shape: diamond
  style.fill: "#ff9800"
  style.font-color: "#ffffff"
  style.bold: true
}
prod: Deploy Production {class: deploy; style.fill: "#1b5e20"}

push -> build -> tests
tests.unit -> staging
tests.integration -> staging
tests.e2e -> staging
staging -> approval -> prod

approval -> staging: rejected {style.stroke: "#d32f2f"; style.stroke-dash: 5}
```

### Database ER Diagram

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: varchar {constraint: unique}
  org_id: int {constraint: foreign_key}
}

orgs: {
  shape: sql_table
  id: int {constraint: primary_key}
  name: varchar
  plan: enum
}

posts: {
  shape: sql_table
  id: int {constraint: primary_key}
  author_id: int {constraint: foreign_key}
  title: varchar
  body: text
  created_at: timestamp
}

users.org_id -> orgs.id
posts.author_id -> users.id
```
