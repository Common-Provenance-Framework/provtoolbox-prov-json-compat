# Known Compatibility Issues

ProvToolbox v2.2.4 vs PROV-JSON W3C Spec — 22 distinct issues discovered.

## Critical (8)

| ID | Summary | Root Cause |
|---|---|---|
| D2.1-1 | Missing `prefix` key crashes parser (NPE) | `ProvDeserialiser` assumes `prefix` key always present |
| D2.1-2 | Blank node IDs on elements crash serialization | `SortedBundle.reassignId()` calls `id.getPrefix()` on blank `_:` names |
| D2.2-2 | Native JSON values silently dropped as sole attribute values | Jackson maps native types to Java primitives that the model discards |
| D2.2-3 | Native number/boolean in mixed arrays crash serializer | `ProvSerialiser` can't handle mixed `TypedValue` + native in arrays |
| D2.2-5 | `prov:value` loses its data content | Model stores value reference but serializer doesn't emit the content |
| D2.2-6 | JSON `null` crashes parser | `NullPointerException` on null attribute values |
| D3.1.3-1 | Time format normalization — tz injected, ms added, sub-ms truncated | `XMLGregorianCalendar` normalizes all timestamps on parse |
| D3.3-1 | Bundle deserialization completely broken — NPE crash | `CustomBundleDeserializer` never calls `setId()` before `toBundle()` |

## High (8)

| ID | Summary | Root Cause |
|---|---|---|
| D2.1-3 | Same-IRI entries silently merged | HashMap key collision when two prefixed names resolve to same IRI |
| D2.1-4 | Full URIs as identifiers not supported | Qualified name parser rejects names without `prefix:local` format |
| D2.1-6 | Null prefix value crashes | `NullPointerException` when prefix maps to JSON `null` |
| D2.1-7 | User `_` prefix silently overridden | ProvToolbox reserves `_` for blank nodes; user mappings lost |
| D2.2-1 | Typed values serialized as 2-element arrays instead of `{"$":..., "type":...}` | Serializer uses `[value, type]` format instead of spec's object format |
| D2.2-7 | Native strings behave differently in sole vs array context | Inconsistent: sole native string dropped, array native strings kept |
| D2.2-8 | 2-element array format ambiguity | Element order in `[value, type]` output depends on hash codes |
| D3.1.2-1 | `prov:value` COMPLETELY dropped on Agent | Agent model drops `prov:value` entirely during serialization |
| D3.1.2-2 | Multi-value `xsd:string` drops type annotation | When ≥2 `xsd:string` values, type info stripped on output |
| D-DICT-1 | PROV-Dictionary extensions not recognized in JSON | `SortedDocument` has no fields for `hadDictionaryMember`, `derivedByInsertionFrom`, `derivedByRemovalFrom` |

## Medium (3)

| ID | Summary | Root Cause |
|---|---|---|
| D2.1-5 | `"default"` not usable as explicit prefix name | Reserved word conflict in qualified name resolution |
| D2.2-4 | Multi-value array order not preserved | Attributes stored in `HashSet`, not ordered collection |
| D3.1.1-4 | Entity/section order not preserved | `SortedDocument` uses `HashMap` for all element collections |

## Low / Info (3)

| ID | Summary | Root Cause |
|---|---|---|
| D3.1.1-5 | Duplicate JSON keys — last wins silently | Jackson's default duplicate-key handling |
| D3.1.1-7 | `prov:role` silently dropped on elements | Model's element mixin doesn't include role field |
| D3.1.1-8 | Empty statement sections dropped from output | Serializer omits empty collections |
| D3.2.2-1 | Property order within relation objects changed | `@JsonPropertyOrder` mixin defines different order from spec |

## Positive Finding

| ID | Summary |
|---|---|
| D3.2.1-2 | `prov:role` PRESERVED on relations (unlike elements) — format broken but data survives |
