# Known Compatibility Issues

ProvToolbox v2.2.4 vs PROV-JSON W3C Spec — 19 issues identified.

All claims cross-checked against the [PROV-JSON W3C Member Submission](https://www.w3.org/Submission/2013/SUBM-prov-json-20130424/) (May 2014).

## Critical (5)

| ID | Summary | Spec Reference |
|---|---|---|
| D2.2-2 | Native JSON values silently dropped as sole attribute values | Spec §2.2: "xsd:decimal, xsd:string, and xsd:boolean values **MAY** be represented using the JSON native data types number, string, and boolean" — explicit MAY keyword. Valid input, data silently lost |
| D2.2-3 | Native number/boolean in mixed arrays crash serializer | Spec §2.2 Example 3 explicitly shows a mixed array containing typed objects and a plain integer `2` — the spec's own example causes a crash |
| D2.2-5 | `prov:value` loses its data content on round-trip | `prov:value` is a defined PROV-DM attribute; data read in successfully but not written back out |
| D2.2-6 | JSON `null` as attribute value crashes parser (NPE) | `null` is not a defined PROV-JSON value type, so rejection is correct, but the parser crashes with an unhandled NullPointerException rather than a clean parse error |
| D3.3-1 | Bundle deserialization completely broken — NPE crash on all bundle inputs | Spec §3.3 defines bundles with multiple examples (Examples 40–41); every bundle test crashes with NullPointerException |

## High (8)

| ID | Summary | Spec Reference |
|---|---|---|
| D2.1-7 | User `_` prefix silently overridden by internal blank node mapping | Spec §2.1 defines `_:` for blank node identifiers per Turtle nodeID production; a user-defined `_` namespace prefix is silently overwritten without warning |
| D2.2-1 | Typed values serialized as 2-element arrays instead of `{"$":..., "type":...}` | Spec §2.2: "The value of a literal is stored in the object's special property `$`... the data type in the `type` property" — spec defines an object format; ProvToolbox outputs `[value, type]` arrays instead |
| D2.2-7 | Native strings behave differently depending on context — dropped when alone, kept in arrays | Spec §2.2 allows native types equally in both contexts; inconsistent handling |
| D2.2-8 | 2-element array output has non-deterministic element order | The `[value, type]` arrays from D2.2-1 have unpredictable element order depending on Java hash codes, making the already-incorrect format additionally unreliable |
| D3.1.2-1 | `prov:value` completely dropped on Agent elements | `prov:value` is a defined PROV-DM attribute for elements; read in but not written back out on agents specifically |
| D3.1.2-2 | Multi-value `xsd:string` attributes lose type annotation | When an agent has ≥2 `xsd:string` typed values, the type information is stripped from the output; values survive but lose their type |
| D3.1.3-1 | Timestamps silently modified — timezone injected, milliseconds added, sub-ms truncated | Spec §3.1.3: timestamps "**MUST** conform to xsd:dateTime" — the spec does not explicitly require preserving the exact lexical form. However, injecting `+00:00` changes semantic meaning: a timezone-unspecified value becomes explicitly UTC. Spec Example 9 shows timestamps without timezone or milliseconds |
| D-DICT-1 | PROV-Dictionary extensions not recognized in JSON format | Spec Appendix B defines `hadDictionaryMember`, `derivedByInsertionFrom`, `derivedByRemovalFrom` with Examples 46–52; all dictionary data silently discarded on round-trip |

## Medium (2)

| ID | Summary | Spec Reference |
|---|---|---|
| D2.2-4 | Multi-value array order not preserved | Spec §2.2: multiple values "**MUST** be... collated in to a JSON array." Array order is semantically significant in JSON, but the spec does not explicitly require preserving it |
| D3.1.1-4 | Element order within sections not preserved | JSON object key order is not guaranteed by the JSON specification; however many systems depend on it in practice |

## Low / Info (4)

| ID | Summary | Spec Reference |
|---|---|---|
| D3.1.1-5 | Duplicate JSON keys — last wins silently | Standard JSON parser behaviour per RFC 8259; not specific to ProvToolbox |
| D3.1.1-7 | `prov:role` silently dropped on elements | PROV-DM defines `prov:role` for relations, not elements. Elements can have arbitrary additional attributes, so `prov:role` should be preserved as a generic attribute, but it is not a standard element attribute |
| D3.1.1-8 | Empty statement sections dropped from output | Spec shows sections containing data; it does not explicitly require preserving empty sections. No data loss |
| D3.2.2-1 | Property order within relation objects changed from input | JSON object key order is not guaranteed; data intact but structure differs |

## Removed from Previous Report

The following were previously listed as issues but have been removed after cross-checking with the spec:

| Former ID | Reason for Removal |
|---|---|
| D2.1-1 | "Missing prefix crashes parser" — The spec does not explicitly mark the `prefix` section as optional. Whether its omission is valid is ambiguous. Removed as not clearly a spec violation |
| D2.1-2 | "Blank node IDs on elements crash serialization" — Spec §2.1 blank node section addresses **relations**, not elements. Blank node IDs on entities/agents/activities are not defined in the spec |
| D2.1-3 | "Same-IRI entries silently merged" — Spec §2.1 NOTE: "It is the responsibility of the application consuming PROV-JSON to deal with such cases properly." Merging is within spec allowance |
| D2.1-4 | "Full URIs as identifiers not supported" — Spec §2.1: "An identifier in PROV-JSON, as in prov-dm, is a qualified name." Full URIs are not qualified names. ProvToolbox correctly rejects them |
| D2.1-5 | "`default` not usable as prefix name" — Spec §2: "There is a special prefix called `default`." The spec defines `default` as reserved. ProvToolbox correctly treats it as special |
| D2.1-6 | "Null prefix value crashes parser" — `null` is not a valid namespace IRI. Rejection is correct; the crash-vs-clean-error distinction is a robustness concern, not a spec violation |

## Positive Finding

| ID | Summary |
|---|---|
| D3.2.1-2 | `prov:role` PRESERVED on relations (unlike elements) — output format is incorrect (array instead of object) but the data survives |
