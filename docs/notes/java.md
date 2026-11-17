# Java

New concepts get added here as the service code first needs them (see the roadmap's "Java concepts, taught when needed").

## Static typing
Types are checked by the compiler **before** the code runs. A type mismatch is a build failure, not a production bug. This is what makes large refactors safe.
```java
long price = 999;
price = "free";   // ❌ compile error
var qty = 3;      // type inferred as int, and still fixed forever
```

## JavaScript → Java cheat sheet
| Idea | JavaScript | Java |
|---|---|---|
| Entry point | top of the file runs | `public static void main(String[] args)` |
| Data object | `{ sku, name }` | `record Product(String sku, String name) {}` |
| Contract | TS `interface` (erased at runtime) | `interface` + `implements` (enforced by the compiler) |
| Fixed set of values | string constants | `enum Category { BOOKS, ELECTRONICS }` |
| Typed list / map | `Product[]`, `Map` | `List<Product>`, `Map<String, Product>` |
| Maybe missing | `?.`, `??` | `Optional<T>` with `.map()`, `.orElse()` |
| map/filter/reduce | `arr.filter().map()` | `list.stream().filter().map().toList()` |
| Arrow function | `p => p.price` | `p -> p.price()` or `Product::price` |
| Equality | `===` | `.equals()` for objects; `==` only for primitives and enums |

## Records
Immutable data carriers. Java generates the constructor, accessors (`p.name()`, not `getName()`), `equals`, `hashCode` and `toString`. Validate in a **compact constructor**:
```java
record Product(String sku, long priceCents) {
    Product {
        if (sku == null || sku.isBlank()) throw new IllegalArgumentException("sku is required");
        if (priceCents < 0) throw new IllegalArgumentException("price must be >= 0");
    }
}
```
`Objects.requireNonNull(category, "category is required")` is a one-line null check.

**Why immutability matters:** an object that can't change can be shared between threads safely. That's why DTOs and Kafka events in this project will be records.

## Interfaces
They define *what* something does; implementations define *how*. Code that depends on the interface doesn't care which implementation it gets, which is the foundation of Spring's dependency injection.
```java
interface DiscountPolicy { long apply(long priceCents); }
record PercentageDiscount(int percent) implements DiscountPolicy {
    @Override public long apply(long cents) { return cents * (100 - percent) / 100; }
}
DiscountPolicy none = cents -> cents;   // one-method interface → can be a lambda
```

## Generics
`List<Product>` tells the compiler exactly what's inside the list, so `products.get(0).name()` is checked when you compile instead of failing at runtime.

## Optional
Says "this might be empty" in the return type, which forces the caller to handle it.
```java
String name = catalog.findBySku("X").map(Product::name).orElse("unknown");
```
Use it for **return types only**, never for fields or parameters.

## Streams
Like JavaScript array methods, but **lazy**: nothing runs until a terminal operation (`toList()`, `sum()`, `count()`, `findFirst()`, `collect(...)`).
```java
long value = products.stream().mapToLong(p -> p.priceCents() * p.stock()).sum();
Map<Category, List<Product>> byCat = products.stream().collect(Collectors.groupingBy(Product::category));
```

## `==` vs `.equals()`
```java
new String("hi") == new String("hi")        // false: two different objects
new String("hi").equals(new String("hi"))   // true: same value
```
`==` compares **references** (is it the same object in memory?). `.equals()` compares **values**. Records generate a value-based `equals`.

> 🎯 **Interview:** If you override `equals`, you must override `hashCode` too. A `HashMap` first uses `hashCode` to find the bucket, *then* `equals` to find the key inside it. Two "equal" objects with different hash codes land in different buckets, so lookups fail silently. (Revisited in Week 3 with JPA entities.)

## Static vs inner nested classes
- A nested `record`, `enum` or `interface` is **automatically static**: it doesn't need an instance of the outer class.
- A nested `class` is an **inner class** unless you mark it `static`. It's tied to an instance of the outer class, so `new Catalog(...)` inside `static main` fails with *"non-static variable this cannot be referenced from a static context"*.
- Fix: `static class Catalog`, or make it a top-level class.
- The same applies to fields: an instance field (like `DiscountPolicy noDiscount = …` at class level) can't be used from `static main`.

## `final` ≠ immutable (defensive copies)
`private final List<Product> products` only stops the **field** from being reassigned. The **list** itself can still be modified by whoever passed it in.
```java
this.products = List.copyOf(products);   // unmodifiable copy, so callers can't change it later
```
> 🎯 **Interview:** "Is a `final` field immutable?" No. `final` protects the reference, not the object it points to.

## Money: never use floating point
`priceCents / 100.0` gives `699.0` instead of `699.00`. Worse, binary floating point can't represent most decimal fractions exactly (`0.1 + 0.2 != 0.3`). Store money as **integer minor units** (`long` cents) and format with integer math:
```java
String.format("$%d.%02d", cents / 100, cents % 100)
```
Integer division truncates. In a real system, rounding rules (e.g. for discounts) are a business decision you make explicitly.
