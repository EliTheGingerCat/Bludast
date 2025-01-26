"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[6178],{57439:e=>{e.exports=JSON.parse('{"functions":[{"name":"destroy","desc":"Useful for when there are multiple return statements in the same function.","params":[{"name":"vectors","desc":"","lua_type":"{TempVector<any>}"}],"returns":[],"function_type":"static","tags":["local"],"since":"v0.1.0","private":true,"source":{"line":348,"path":"src/Ast/Parser.luau"}},{"name":"shouldParseTypePack","desc":"","params":[{"name":"lexer","desc":"","lua_type":"Lexer"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"static","tags":["local"],"since":"v0.1.0","private":true,"source":{"line":363,"path":"src/Ast/Parser.luau"}},{"name":"parse","desc":"The primary function of this module which creates a parser and returns its results in a nice table for you.","params":[{"name":"buffer","desc":"","lua_type":"string"},{"name":"bufferSize","desc":"","lua_type":"number"},{"name":"names","desc":"","lua_type":"AstNameTable"},{"name":"options","desc":"","lua_type":"ParseOptions"}],"returns":[{"desc":"","lua_type":"ParseResult\\r\\n"}],"function_type":"static","since":"v0.1.0","source":{"line":379,"path":"src/Ast/Parser.luau"}},{"name":"new","desc":"","params":[{"name":"buffer","desc":"","lua_type":"string"},{"name":"bufferSize","desc":"","lua_type":"number"},{"name":"names","desc":"","lua_type":"AstNameTable"},{"name":"options","desc":"","lua_type":"ParseOptions"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":413,"path":"src/Ast/Parser.luau"}},{"name":"blockFollow","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"l","desc":"","lua_type":"Lexeme.Lexeme"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":500,"path":"src/Ast/Parser.luau"}},{"name":"parseChunk","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStatBlock\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":514,"path":"src/Ast/Parser.luau"}},{"name":"parseBlock","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStatBlock\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":531,"path":"src/Ast/Parser.luau"}},{"name":"isStatLast","desc":"","params":[{"name":"stat","desc":"","lua_type":"AstStat"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","tags":["local"],"since":"v0.1.0","private":true,"source":{"line":547,"path":"src/Ast/Parser.luau"}},{"name":"parseBlockNoScope","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStatBlock\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":556,"path":"src/Ast/Parser.luau"}},{"name":"parseStat","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":611,"path":"src/Ast/Parser.luau"}},{"name":"parseIf","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":694,"path":"src/Ast/Parser.luau"}},{"name":"parseWhile","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":757,"path":"src/Ast/Parser.luau"}},{"name":"parseRepeat","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":787,"path":"src/Ast/Parser.luau"}},{"name":"parseDo","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":817,"path":"src/Ast/Parser.luau"}},{"name":"parseBreak","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":838,"path":"src/Ast/Parser.luau"}},{"name":"parseContinue","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"start","desc":"","lua_type":"Location"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":856,"path":"src/Ast/Parser.luau"}},{"name":"parseFor","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":873,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionName","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"start","desc":"","lua_type":"Location"}],"returns":[{"desc":"","lua_type":"{hasself: boolean, debugname: AstName, expr: AstExpr}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":974,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionStat","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1032,"path":"src/Ast/Parser.luau"}},{"name":"validateAttribute","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"attributeName","desc":"","lua_type":"string"},{"name":"attributes","desc":"","lua_type":"TempVector<AstAttr>"}],"returns":[{"desc":"","lua_type":"Pair<boolean, number>\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1057,"path":"src/Ast/Parser.luau"}},{"name":"parseAttribute","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"attributes","desc":"","lua_type":"TempVector<AstAttr>"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1103,"path":"src/Ast/Parser.luau"}},{"name":"parseAttributes","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"{AstAttr}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1130,"path":"src/Ast/Parser.luau"}},{"name":"parseAttributeStat","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1159,"path":"src/Ast/Parser.luau"}},{"name":"parseLocal","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1187,"path":"src/Ast/Parser.luau"}},{"name":"parseReturn","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1263,"path":"src/Ast/Parser.luau"}},{"name":"parseTypeAlias","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"start","desc":"","lua_type":"Location.Location"},{"name":"exported","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1289,"path":"src/Ast/Parser.luau"}},{"name":"parseDeclaredClassMethod","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstDeclaredClassProp\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1315,"path":"src/Ast/Parser.luau"}},{"name":"parseDeclaration","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"start","desc":"","lua_type":"Location.Location"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1382,"path":"src/Ast/Parser.luau"}},{"name":"parseAssignment","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"initial","desc":"","lua_type":"AstExpr"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1530,"path":"src/Ast/Parser.luau"}},{"name":"parseCompoundAssignment","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"initial","desc":"","lua_type":"AstExpr"},{"name":"op","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"AstStat\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1569,"path":"src/Ast/Parser.luau"}},{"name":"prepareFunctionArguments","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"start","desc":"","lua_type":"Location"},{"name":"hasself","desc":"","lua_type":"boolean"},{"name":"args","desc":"","lua_type":"TempVector<Binding>"}],"returns":[{"desc":"","lua_type":"Pair<AstLocal, {AstLocal}>\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1586,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionBody","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"hasself","desc":"","lua_type":"boolean"},{"name":"matchFunction","desc":"","lua_type":"Lexeme.Lexeme"},{"name":"debugname","desc":"","lua_type":"AstName"},{"name":"localName","desc":"","lua_type":"Name?"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"}],"returns":[{"desc":"","lua_type":"Pair<AstExprFunction, AstLocal>\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1613,"path":"src/Ast/Parser.luau"}},{"name":"parseExprList","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"result","desc":"","lua_type":"TempVector<AstExpr>"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1691,"path":"src/Ast/Parser.luau"}},{"name":"parseBinding","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"Binding\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1711,"path":"src/Ast/Parser.luau"}},{"name":"parseBindingList","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"result","desc":"","lua_type":"TempVector<Binding>"},{"name":"allowDot3","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"{\\r\\n\\tvararg: boolean,\\r\\n\\tvarargLocation: Location,\\r\\n\\tvarargAnnotation: AstTypePack?\\r\\n}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1730,"path":"src/Ast/Parser.luau"}},{"name":"parseOptionalType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstType?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1773,"path":"src/Ast/Parser.luau"}},{"name":"parseTypeList","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"result","desc":"","lua_type":"TempVector<AstType>"},{"name":"resultNames","desc":"","lua_type":"TempVector<AstArgumentName?>"}],"returns":[{"desc":"","lua_type":"AstType?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1788,"path":"src/Ast/Parser.luau"}},{"name":"parseOptionalReturnType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstTypeList?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1830,"path":"src/Ast/Parser.luau"}},{"name":"parseReturnType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"Pair<Location, AstTypeList>\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1866,"path":"src/Ast/Parser.luau"}},{"name":"parseTableIndexer","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"access","desc":"","lua_type":"number"},{"name":"accessLocation","desc":"","lua_type":"Location?"}],"returns":[{"desc":"","lua_type":"AstTableIndexer\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1951,"path":"src/Ast/Parser.luau"}},{"name":"parseTableType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"inDeclarationContext","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"AstType\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":1975,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"allowPack","desc":"","lua_type":"boolean"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"}],"returns":[{"desc":"","lua_type":"AstTypeOrPack\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2082,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionTypeTail","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"begin","desc":"","lua_type":"Lexeme"},{"name":"attributes","desc":"","lua_type":"{AstAttr}"},{"name":"generics","desc":"","lua_type":"{AstGenericType}"},{"name":"genericPacks","desc":"","lua_type":"{AstGenericTypePack}"},{"name":"params","desc":"","lua_type":"{AstType}"},{"name":"paramNames","desc":"","lua_type":"{AstArgumentName?}"},{"name":"varargAnnotation","desc":"","lua_type":"AstTypePack"}],"returns":[{"desc":"","lua_type":"AstType\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2156,"path":"src/Ast/Parser.luau"}},{"name":"parseTypeSuffix","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"typeAst","desc":"","lua_type":"AstType"},{"name":"begin","desc":"","lua_type":"Location.Location"}],"returns":[{"desc":"","lua_type":"AstType\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2190,"path":"src/Ast/Parser.luau"}},{"name":"parseTypeOrPack","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstTypeOrPack\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2284,"path":"src/Ast/Parser.luau"}},{"name":"parseType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"inDeclarationContext","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"AstType\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2309,"path":"src/Ast/Parser.luau"}},{"name":"parseSimpleType","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"allowPack","desc":"","lua_type":"boolean"},{"name":"inDeclarationContext","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"AstTypeOrPack\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2344,"path":"src/Ast/Parser.luau"}},{"name":"parseVariadicArgumentTypePack","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstTypePack\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2442,"path":"src/Ast/Parser.luau"}},{"name":"parseTypePack","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstTypePack\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2463,"path":"src/Ast/Parser.luau"}},{"name":"parseUnaryOp","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"l","desc":"","lua_type":"Lexeme"}],"returns":[{"desc":"","lua_type":"number?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2489,"path":"src/Ast/Parser.luau"}},{"name":"parseBinaryOp","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"l","desc":"","lua_type":"Lexeme"}],"returns":[{"desc":"","lua_type":"number?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2506,"path":"src/Ast/Parser.luau"}},{"name":"parseCompoundOp","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"l","desc":"","lua_type":"Lexeme"}],"returns":[{"desc":"","lua_type":"number?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2549,"path":"src/Ast/Parser.luau"}},{"name":"checkUnaryConfusables","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"number?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2576,"path":"src/Ast/Parser.luau"}},{"name":"checkBinaryConfusables","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"binaryPriority","desc":"","lua_type":"{BinaryOpPriority}"},{"name":"limit","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"number?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2600,"path":"src/Ast/Parser.luau"}},{"name":"parseExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"limit","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2644,"path":"src/Ast/Parser.luau"}},{"name":"parseNameExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2714,"path":"src/Ast/Parser.luau"}},{"name":"parsePrefixExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2738,"path":"src/Ast/Parser.luau"}},{"name":"parsePrimaryExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"asStatement","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2771,"path":"src/Ast/Parser.luau"}},{"name":"parseAssertionExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2834,"path":"src/Ast/Parser.luau"}},{"name":"parseInteger","desc":"Due to Luau limitations, this function is less accurate. It *is* possible to make it fully accurate with some sort of `BigNumber`, but I doubt this is necessary.","params":[{"name":"data","desc":"","lua_type":"string"},{"name":"base","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"{\\r\\n\\toutcome: number,\\r\\n\\tresult: number?\\r\\n}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2854,"path":"src/Ast/Parser.luau"}},{"name":"parseSimpleExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2917,"path":"src/Ast/Parser.luau"}},{"name":"parseFunctionArgs","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"func","desc":"","lua_type":"AstExpr"},{"name":"isSelf","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":2984,"path":"src/Ast/Parser.luau"}},{"name":"reportFunctionArgsError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"func","desc":"","lua_type":"AstExpr"},{"name":"isSelf","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3031,"path":"src/Ast/Parser.luau"}},{"name":"reportAmbiguousCallError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3044,"path":"src/Ast/Parser.luau"}},{"name":"parseTableConstructor","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3057,"path":"src/Ast/Parser.luau"}},{"name":"parseIfElseExpr","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3130,"path":"src/Ast/Parser.luau"}},{"name":"parseNameOpt","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string?"}],"returns":[{"desc":"","lua_type":"Name?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3165,"path":"src/Ast/Parser.luau"}},{"name":"parseName","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string?"}],"returns":[{"desc":"","lua_type":"Name\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3184,"path":"src/Ast/Parser.luau"}},{"name":"parseIndexName","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string?"},{"name":"previous","desc":"","lua_type":"Position"}],"returns":[{"desc":"","lua_type":"Name\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3200,"path":"src/Ast/Parser.luau"}},{"name":"parseGenericTypeList","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"withDefaultValues","desc":"","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"Pair<{AstGenericType}, {AstGenericTypePack}>\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3225,"path":"src/Ast/Parser.luau"}},{"name":"parseTypeParams","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"{AstTypeOrPack}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3320,"path":"src/Ast/Parser.luau"}},{"name":"parseCharArray","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"string?\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3370,"path":"src/Ast/Parser.luau"}},{"name":"parseString","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3397,"path":"src/Ast/Parser.luau"}},{"name":"parseInterpString","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3411,"path":"src/Ast/Parser.luau"}},{"name":"parseNumber","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"AstExpr\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3495,"path":"src/Ast/Parser.luau"}},{"name":"pushLocal","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"binding","desc":"","lua_type":"Binding"}],"returns":[{"desc":"","lua_type":"AstLocal\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3522,"path":"src/Ast/Parser.luau"}},{"name":"saveLocals","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[{"desc":"","lua_type":"number\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3538,"path":"src/Ast/Parser.luau"}},{"name":"restoreLocals","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"offset","desc":"","lua_type":"number"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3547,"path":"src/Ast/Parser.luau"}},{"name":"expectAndConsume","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"value","desc":"","lua_type":"string | number"},{"name":"context","desc":"","lua_type":"string?"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3562,"path":"src/Ast/Parser.luau"}},{"name":"expectAndConsumeFail","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"typeLex","desc":"","lua_type":"number"},{"name":"context","desc":"","lua_type":"string?"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3592,"path":"src/Ast/Parser.luau"}},{"name":"expectMatchAndConsume","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"value","desc":"","lua_type":"string"},{"name":"begin","desc":"","lua_type":"Lexeme"},{"name":"searchForMissing","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3608,"path":"src/Ast/Parser.luau"}},{"name":"expectMatchAndConsumeRecover","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"value","desc":"","lua_type":"string"},{"name":"begin","desc":"","lua_type":"MatchLexeme"},{"name":"searchForMissing","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3629,"path":"src/Ast/Parser.luau"}},{"name":"expectMatchAndConsumeFail","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"typeLex","desc":"","lua_type":"number"},{"name":"begin","desc":"","lua_type":"MatchLexeme"},{"name":"extra","desc":"","lua_type":"string?"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3669,"path":"src/Ast/Parser.luau"}},{"name":"expectMatchEndAndConsume","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"typeLex","desc":"","lua_type":"number"},{"name":"begin","desc":"","lua_type":"Lexeme"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3685,"path":"src/Ast/Parser.luau"}},{"name":"expectMatchEndAndConsumeFail","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"typeLex","desc":"","lua_type":"number"},{"name":"begin","desc":"","lua_type":"MatchLexeme"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3719,"path":"src/Ast/Parser.luau"}},{"name":"copy","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"data","desc":"","lua_type":"TempVector<T>"}],"returns":[{"desc":"","lua_type":"{T}\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3735,"path":"src/Ast/Parser.luau"}},{"name":"incrementRecursionCounter","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3744,"path":"src/Ast/Parser.luau"}},{"name":"report","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"location","desc":"","lua_type":"Location"},{"name":"format","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3757,"path":"src/Ast/Parser.luau"}},{"name":"reportNameError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"context","desc":"","lua_type":"string?"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3783,"path":"src/Ast/Parser.luau"}},{"name":"reportStatError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"location","desc":"","lua_type":"Location"},{"name":"expressions","desc":"","lua_type":"{AstExpr}"},{"name":"statements","desc":"","lua_type":"{AstStat}"},{"name":"format","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"AstStatError\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3796,"path":"src/Ast/Parser.luau"}},{"name":"reportExprError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"location","desc":"","lua_type":"Location"},{"name":"expressions","desc":"","lua_type":"{AstExpr}"},{"name":"format","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"AstExprError\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3807,"path":"src/Ast/Parser.luau"}},{"name":"reportTypeError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"location","desc":"","lua_type":"Location"},{"name":"types","desc":"","lua_type":"{AstType}"},{"name":"format","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"AstTypeError\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3818,"path":"src/Ast/Parser.luau"}},{"name":"reportMissingTypeError","desc":"","params":[{"name":"self","desc":"","lua_type":"Parser"},{"name":"parseErrorLocation","desc":"","lua_type":"Location"},{"name":"astErrorLocation","desc":"","lua_type":"Location"},{"name":"format","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"AstTypeError\\r\\n"}],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3829,"path":"src/Ast/Parser.luau"}},{"name":"nextLexeme","desc":"Computes the next lexeme. If specified, the parser will collect [comments](Comment) and [hot comments](HotComment).","params":[{"name":"self","desc":"","lua_type":"Parser"}],"returns":[],"function_type":"static","since":"v0.1.0","private":true,"source":{"line":3842,"path":"src/Ast/Parser.luau"}}],"properties":[],"types":[],"name":"Parser","desc":"Class from [`/Ast/src/Parser.cpp`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Parser.cpp#L155-L3337) and [`/Ast/include/Luau/Parser.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Parser.h#L54-L429).\\n\\nConverts lexemes to an abstract syntax tree.","source":{"line":131,"path":"src/Ast/Parser.luau"}}')}}]);