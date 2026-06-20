# Part-Separation vs Merged-Whole CAD Methodology

**For: parallel-agent CAD design, enforced by naming rigor**
**Date:** 2026-06-19
**Status:** Methodology reference (informs the feature-first CAD spec)

## Thesis

A 3D-printed part is one physical object, but the *process* that designs it does
not have to be one undifferentiated blob of geometry. The dominant scripting
approach today — fuse every addition and subtraction into a single solid (one
`union()`/`difference()` tree, one output solid) — is a **merged-whole**
methodology. It is simple for one author and fatal for many.

This document argues for a **part-separation** methodology: author each feature
as a named, independently-built solid with a stable identity, then *compose*
those features deterministically into both (a) the single fused printable part
and (b) a colored "feature view" for inspection. Separation is what makes
**parallel-agent design** safe, and **naming rigor** is the discipline that keeps
separation from collapsing back into a blob.

## The merged-whole methodology

**Definition.** One source artifact builds one solid. Features exist only as
transient expressions inside a boolean tree:

```scad
module mount() {
  difference() {
    union() { backplate(); standoff(); frame(); side_hooks(); join_walls(); }
    port_cuts(); screw_holes(); standoff_bore(); pb_cut(); air_holes();
  }
}
```

After evaluation there is no "standoff" and no "port cuts" — only a mesh. The
feature names live in comments and module definitions, not in the output.

**Where it shines.** Single author, single context, small parts, fast first
draft. Nothing to coordinate; the CSG engine does the work.

**Why it blocks scale.** Three structural problems, all caused by the same root
— *features are not addressable after composition*:

1. **No parallel ownership.** You cannot hand "the standoff" to one agent and
   "the port cuts" to another and recombine their work, because both are
   entangled in one boolean tree and collapse into one output solid. Merges are
   line-based text merges of a monolith — conflict-prone and semantically blind.
2. **No per-feature verification.** You cannot snapshot, measure, or diff a
   single feature in isolation; the viewer sees one anonymous mesh. "Is the
   power-button hole right?" requires reasoning about the whole.
3. **No stable identity across iterations.** When the model regenerates, there
   is nothing to key on — no id to preserve a color, a camera focus, or a
   reviewer's annotation against. Every iteration is a fresh blob.

## The part-separation methodology

**Definition.** Each feature is declared as a first-class object with a stable
`id`, a display `name`, a `kind` (`add` or `cut`), a deterministic `color`, and
a builder that returns one solid. A part is an *ordered list* of features.

Two deterministic reductions run from that one list:

- **Fused part** (`part.step`): union all `add` solids, subtract all `cut`
  solids → the single printable solid. This remains the manufacturing source of
  truth; nothing about separation changes what gets printed.
- **Feature view** (`part.features.step` + sidecar): an assembly compound where
  each `add` is an opaque colored labeled solid and each `cut` is its cutter
  solid rendered translucent (the "ghost"). The STEP part **label equals the
  feature id**, and a manifest sidecar carries `{id, name, kind, colorHex}`.

Separation is a *viz-and-process layer over one part*, not a multi-body part.
The fused output keeps it printable; the feature view makes it addressable.

## Why separation enables parallel-agent design

Separation turns geometry composition into a problem with **merge keys and
contracts** instead of text conflicts:

- **Features compose at datums, not at text lines.** Each agent builds its
  feature against a shared coordinate/datum contract and returns a solid. The
  reducer composes by union/subtract at well-defined positions — so two agents
  editing two features never collide in a shared monolith.
- **Stable ids are merge keys.** A feature id uniquely identifies a unit of work
  end-to-end: source builder → STEP label → legend row → reviewer annotation.
  Agents claim ids; the validator rejects collisions before geometry is built.
- **Per-feature isolation is verifiable.** Each agent's output is a single named
  solid that can be snapshotted, measured, and diffed independently, then
  composed. Review is per-feature, not per-blob.
- **Deterministic color = stable visual identity.** Color assigned by id (not by
  declaration order) means adding or reordering features never recolors existing
  ones, so a reviewer's mental map and a legend's swatches survive iteration.

In short: merged-whole scales to one author; part-separation scales to a fleet,
because the unit of work (a named feature) is the unit of ownership, the unit of
review, and the unit of recomposition.

## Naming rigor is the enabling discipline

Separation only holds if names are trustworthy. The moment ids drift, duplicate,
or go missing, the merge keys break and the methodology degrades back toward a
blob. Naming rigor is therefore not cosmetic — it is the load-bearing invariant.
The enforcement skill guarantees:

- **Presence:** every feature has a non-empty `id` and `name`.
- **Uniqueness:** ids are unique within a part (no silent overwrite on merge).
- **Slug form:** ids are lowercase kebab/snake slugs — safe as STEP labels, file
  keys, and URL/query fragments.
- **Traceability:** STEP part label == feature id == manifest id == source
  builder name. One identity, four places, no aliasing.
- **Kind validity:** `kind ∈ {add, cut}`; cutters must be solids (a removal is a
  positive solid used negatively, never an open surface).
- **Deterministic color binding:** color is a pure function of id (or an explicit
  pin), checked stable across regenerations.

Enforcement is an automated gate in the generator: violations **fail
generation** rather than producing a quietly-wrong blob. That gate is what lets
multiple agents work in parallel without a human refereeing every recombination.

## Trade-offs / costs

- **More structure up front.** You declare features and datums instead of
  free-handing one boolean tree. Pays off the first time two people/agents touch
  the part or you need to review one feature.
- **Double output.** Two reductions (fused + feature view) cost extra generation
  time and disk. Mitigated by sharing the same feature list and builders.
- **Overlap discipline.** Additive features may overlap at mating faces; that is
  fine for the fused part (boolean handles it) but means the feature view shows
  doubled material — acceptable as a viz layer, called out in the legend.

## Recommendation

Adopt part-separation as the default for any part that will be (a) designed by
more than one agent/author, (b) reviewed feature-by-feature, or (c) iterated
repeatedly by text. Keep merged-whole only for throwaway single-author sketches.
Make naming rigor a generation-time gate, not a guideline — it is the difference
between separation that scales and separation that rots.

See the implementation spec:
[`docs/superpowers/specs/2026-06-19-feature-first-cad-design.md`](../superpowers/specs/2026-06-19-feature-first-cad-design.md).
