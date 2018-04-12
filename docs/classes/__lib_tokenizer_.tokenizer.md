[poetry](../README.md) > ["_lib/Tokenizer"](../modules/__lib_tokenizer_.md) > [Tokenizer](../classes/__lib_tokenizer_.tokenizer.md)



# Class: Tokenizer


Convert character stream into token stream.

## Index

### Constructors

* [constructor](__lib_tokenizer_.tokenizer.md#constructor)


### Properties

* [keywords](__lib_tokenizer_.tokenizer.md#keywords)


### Methods

* [error](__lib_tokenizer_.tokenizer.md#error)
* [isComment](__lib_tokenizer_.tokenizer.md#iscomment)
* [isCommentStart](__lib_tokenizer_.tokenizer.md#iscommentstart)
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


*Defined in [_lib/Tokenizer.ts:9](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L9)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| charReader | [CharReader](__lib_charreader_.charreader.md)   |  - |





**Returns:** [Tokenizer](__lib_tokenizer_.tokenizer.md)

---


## Properties
<a id="keywords"></a>

###  keywords

**●  keywords**:  *`string`[]*  =  ["if", "else", "function", "let", "while", "for", "in",
    "is", "isnt", "be", "return", "true", "false", "null", "class",
    "constructor", "integer", "float", "boolean", "string"]

*Defined in [_lib/Tokenizer.ts:7](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L7)*





___


## Methods
<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/Tokenizer.ts:107](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L107)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iscomment"></a>

###  isComment

► **isComment**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:138](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L138)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iscommentstart"></a>

###  isCommentStart

► **isCommentStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:135](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L135)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/Tokenizer.ts:103](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L103)*





**Returns:** `boolean`





___

<a id="isnumber"></a>

###  isNumber

► **isNumber**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:123](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L123)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isnumberstart"></a>

###  isNumberStart

► **isNumberStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:120](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L120)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isoperator"></a>

###  isOperator

► **isOperator**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:126](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L126)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="ispunctuation"></a>

###  isPunctuation

► **isPunctuation**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:129](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L129)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isquote"></a>

###  isQuote

► **isQuote**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:132](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L132)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswhitespace"></a>

###  isWhitespace

► **isWhitespace**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:111](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L111)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isword"></a>

###  isWord

► **isWord**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:117](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L117)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswordstart"></a>

###  isWordStart

► **isWordStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:114](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L114)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="next"></a>

###  next

► **next**(): `any`



*Defined in [_lib/Tokenizer.ts:14](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L14)*





**Returns:** `any`





___


