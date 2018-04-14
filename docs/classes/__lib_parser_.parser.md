[poetry](../README.md) > ["_lib/Parser"](../modules/__lib_parser_.md) > [Parser](../classes/__lib_parser_.parser.md)



# Class: Parser


Converting token stream into syntax tree.

## Index

### Constructors

* [constructor](__lib_parser_.parser.md#constructor)


### Methods

* [error](__lib_parser_.parser.md#error)
* [isEof](__lib_parser_.parser.md#iseof)
* [isStatementEnd](__lib_parser_.parser.md#isstatementend)
* [nextBlock](__lib_parser_.parser.md#nextblock)
* [nextStatement](__lib_parser_.parser.md#nextstatement)



---
## Constructors
<a id="constructor"></a>


### ⊕ **new Parser**(tokenizer: *[Tokenizer](__lib_tokenizer_.tokenizer.md)*): [Parser](__lib_parser_.parser.md)


*Defined in [_lib/Parser.ts:6](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L6)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| tokenizer | [Tokenizer](__lib_tokenizer_.tokenizer.md)   |  - |





**Returns:** [Parser](__lib_parser_.parser.md)

---


## Methods
<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/Parser.ts:98](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L98)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/Parser.ts:94](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L94)*





**Returns:** `boolean`





___

<a id="isstatementend"></a>

###  isStatementEnd

► **isStatementEnd**(token: *`any`*): `undefined`⎮`true`⎮`false`



*Defined in [_lib/Parser.ts:103](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L103)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| token | `any`   |  - |





**Returns:** `undefined`⎮`true`⎮`false`





___

<a id="nextblock"></a>

###  nextBlock

► **nextBlock**(): `any`



*Defined in [_lib/Parser.ts:64](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L64)*





**Returns:** `any`





___

<a id="nextstatement"></a>

###  nextStatement

► **nextStatement**(): `any`



*Defined in [_lib/Parser.ts:11](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Parser.ts#L11)*





**Returns:** `any`





___


