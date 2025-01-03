# Bludast

A manual translation of https://github.com/luau-lang/luau/ into Luau. That is, writing Luau in Luau.

## Table of Contents

- [Title](#bludast)
- [Table of Contents](#table-of-contents)
- [Name](#name)
- [Deviations](#deviations)
- [Progress](#progress)
- [Contributions](#contributions)

## Name

I knew "Luau" has to be in the name somehow. The first part I worked on was AST folder. Thus, I thought of "Luauast", but that looks terrible. I had to have some sort of consonant in the middle. One class that really confused me was the DenseHashMap (which I later realised I did not need since Luau tables already use hashing), so I inserted a D in the middle. Thus, "Ludast". However, my mother told me that "Bludast" sounds better.

## Deviations

Rather than putting most of the AST classes in one file, they each get their own file. Might change this in the future.

`AstArray` is not used in favour of regular Luau arrays.

C++ has enum support, so function parameters and returns can specify what enum they belong to. For Luau, all enum values are `number`. There are hacky workarounds to this, and I might change it sometime, but for now I think it is not a huge type safety risk.

## Progress

Current version (commit hash): [7d4033071abebe09971b410d362c00ffb3084afb](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb)

`/Ast` is sort of done (needs testing), working on `/Compiler`.

## Contributions

Contributions are only really necessary for maintenance or performance, though I am also open to adding other stuff to the repository that relates to the Luau language itself. For example, I think it might be interesting to add a Luau By Example similar to Rust By Example.

**Dependencies**

Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install`.

Install [Node.js and Node Package Manager](https://nodejs.org/en/download), then run `npm install`.

**Moonwave**

Use `moonwave dev` to view the site.

See: https://github.com/evaera/moonwave/issues/163