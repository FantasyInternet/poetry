[poetry](../README.md) > ["_lib/Tokenizer"](../modules/__lib_tokenizer_.md) > [Tokenizer](../classes/__lib_tokenizer_.tokenizer.md)



# Class: Tokenizer


Convert character stream into token stream.

## Index

### Constructors

* [constructor](__lib_tokenizer_.tokenizer.md#constructor)


### Methods

* [error](__lib_tokenizer_.tokenizer.md#error)
* [isEof](__lib_tokenizer_.tokenizer.md#iseof)
* [isNumber](__lib_tokenizer_.tokenizer.md#isnumber)
* [isNumberStart](__lib_tokenizer_.tokenizer.md#isnumberstart)
* [isOperator](__lib_tokenizer_.tokenizer.md#isoperator)
* [isPunctuation](__lib_tokenizer_.tokenizer.md#ispunctuation)
* [isQuote](__lib_tokenizer_.tokenizer.md#isquote)
* [isWhitespace](__lib_tokenizer_.tokenizer.md#iswhitespace)
* [isWord](__lib_tokenizer_.tokenizer.md#isword)
* [isWordStart](__lib_tokenizer_.tokenizer.md#iswordstart)
* [next](__lib_tokenizer_.tokenizer.md#next)



---
## Constructors
<a id="constructor"></a>


### ⊕ **new Tokenizer**(charReader: *[CharReader](__lib_charreader_.charreader.md)*): [Tokenizer](__lib_tokenizer_.tokenizer.md)


*Defined in [_lib/Tokenizer.ts:6](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L6)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| charReader | [CharReader](__lib_charreader_.charreader.md)   |  - |





**Returns:** [Tokenizer](__lib_tokenizer_.tokenizer.md)

---


## Methods
<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/Tokenizer.ts:95](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L95)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/Tokenizer.ts:91](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L91)*





**Returns:** `boolean`





___

<a id="isnumber"></a>

###  isNumber

► **isNumber**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:111](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L111)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isnumberstart"></a>

###  isNumberStart

► **isNumberStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:108](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L108)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isoperator"></a>

###  isOperator

► **isOperator**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:114](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L114)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="ispunctuation"></a>

###  isPunctuation

► **isPunctuation**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:117](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L117)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isquote"></a>

###  isQuote

► **isQuote**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:120](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L120)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswhitespace"></a>

###  isWhitespace

► **isWhitespace**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:99](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L99)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isword"></a>

###  isWord

► **isWord**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:105](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L105)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswordstart"></a>

###  isWordStart

► **isWordStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:102](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L102)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="next"></a>

###  next

► **next**(): `any`



*Defined in [_lib/Tokenizer.ts:10](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L10)*





**Returns:** `any`





___


