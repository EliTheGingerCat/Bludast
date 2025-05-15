# Bludast

A manual translation of https://github.com/luau-lang/luau/ into Luau. That is, writing Luau in Luau.

## Table of Contents

- [Title](#bludast)
- [Table of Contents](#table-of-contents)
- [Name](#name)
- [Notation](#notation)
- [Deviations](#deviations)
- [Progress](#progress)
- [Contributions](#contributions)
- [License](#license)

## Name

I knew "Luau" has to be in the name somehow. The first part I worked on was `/Ast`. Thus, I thought of "Luauast", but that looks terrible. I had to have some sort of consonant in the middle. One class that really confused me was the DenseHashMap (which I later realised I did not need since Luau tables already use hashing), so I inserted a D in the middle. Thus, "Ludast". However, my mother told me that "Bludast" sounds better.

## Notation

`original/` denotes a path in the original Luau repository. `Bludast/` refers to this repository. If the path begins with `/`, try to figure out the source based on context.

## Deviations

Rather than putting most of the AST classes in one file, they each get their own file. Might change this in the future.

`AstArray` is not used in favour of regular Luau arrays (which is just a table).

DenseHash classes are not used in favour of regular hash maps (which is just a table).

C++ has enum support, so function parameters and returns can specify what enum they belong to. For Luau, all enum values are `number`. It could be fixed by lying to the type checker or using string values for enums, but for now I think it is not a huge type safety risk.

The enums from `original/Common/Bytecode.h` are split up into separate files in `Bludast/Common/Bytecode`.

`/C++_Polyfill` was created to house classes that natively exist in C++ but not in Luau.

Some files from `/Ast` were moved to `/Shared` since they are used in more than one root folder.

Fast flags and fast integers are stored in a separate file, `/Shared/FastVariables.luau`.

Instead of 64-bit numbers, either vectors (with [int64-luau](https://github.com/Dekkonot/int64-luau)) or pairs of 32-bit numbers are used.

## Progress

Current version (commit hash): [7d4033071abebe09971b410d362c00ffb3084afb](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb)

`/Ast` and `/Compiler` are fully translated, though there are still many bugs, so current development is going towards testing and fixing.

## Contributions

Contributions are only necessary for maintenance or performance.

**Dependencies**

Install [Luau](https://github.com/luau-lang/luau/releases) or any compatible Luau runtime.

Install [Node.js and Node Package Manager](https://nodejs.org/en/download), then run `npm install`.

**Moonwave**

Use `moonwave dev` to preview the site.

**Testing**

Run `luau test.luau` (or the appropriate command for your runtime) and ensure there are no errors before making a pull request.

## License

This repository has both the Lua and Luau licenses because although this project is written in a different language and has some creative choices, it is still very similar to the original Luau repository, so all licenses from there were added here.