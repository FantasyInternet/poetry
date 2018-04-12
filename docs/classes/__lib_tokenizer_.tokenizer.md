[poetry](../README.md) > ["_lib/Tokenizer"](../modules/__lib_tokenizer_.md) > [Tokenizer](../classes/__lib_tokenizer_.tokenizer.md)



# Class: Tokenizer


Convert character stream into token stream.

## Index

### Constructors

* [constructor](__lib_tokenizer_.tokenizer.md#constructor)


### Properties

* [keywords](__lib_tokenizer_.tokenizer.md#keywords)


### Methods

* [currentIndent](__lib_tokenizer_.tokenizer.md#currentindent)
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
* [peek](__lib_tokenizer_.tokenizer.md#peek)



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
<a id="currentindent"></a>

###  currentIndent

► **currentIndent**(): `number`



*Defined in [_lib/Tokenizer.ts:149](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L149)*





**Returns:** `number`





___

<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/Tokenizer.ts:114](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L114)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iscomment"></a>

###  isComment

► **isComment**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:145](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L145)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iscommentstart"></a>

###  isCommentStart

► **isCommentStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:142](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L142)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/Tokenizer.ts:110](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L110)*





**Returns:** `boolean`





___

<a id="isnumber"></a>

###  isNumber

► **isNumber**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:130](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L130)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isnumberstart"></a>

###  isNumberStart

► **isNumberStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:127](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L127)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isoperator"></a>

###  isOperator

► **isOperator**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:133](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L133)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="ispunctuation"></a>

###  isPunctuation

► **isPunctuation**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:136](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L136)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isquote"></a>

###  isQuote

► **isQuote**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:139](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L139)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswhitespace"></a>

###  isWhitespace

► **isWhitespace**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:118](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L118)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isword"></a>

###  isWord

► **isWord**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:124](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L124)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswordstart"></a>

###  isWordStart

► **isWordStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:121](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L121)*



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

<a id="peek"></a>

###  peek

► **peek**(): `any`



*Defined in [_lib/Tokenizer.ts:105](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L105)*





**Returns:** `any`





___


