[poetry](../README.md) > ["_lib/Tokenizer"](../modules/__lib_tokenizer_.md) > [Tokenizer](../classes/__lib_tokenizer_.tokenizer.md)



# Class: Tokenizer


Convert character stream into token stream.

## Index

### Constructors

* [constructor](__lib_tokenizer_.tokenizer.md#constructor)


### Properties

* [flowControl](__lib_tokenizer_.tokenizer.md#flowcontrol)
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


*Defined in [_lib/Tokenizer.ts:10](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L10)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| charReader | [CharReader](__lib_charreader_.charreader.md)   |  - |





**Returns:** [Tokenizer](__lib_tokenizer_.tokenizer.md)

---


## Properties
<a id="flowcontrol"></a>

###  flowControl

**●  flowControl**:  *`string`[]*  =  ["if", "else", "while", "for", "function", "class", "constructor"]

*Defined in [_lib/Tokenizer.ts:10](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L10)*





___

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



*Defined in [_lib/Tokenizer.ts:181](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L181)*





**Returns:** `number`





___

<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/Tokenizer.ts:146](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L146)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iscomment"></a>

###  isComment

► **isComment**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:177](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L177)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iscommentstart"></a>

###  isCommentStart

► **isCommentStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:174](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L174)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/Tokenizer.ts:142](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L142)*





**Returns:** `boolean`





___

<a id="isnumber"></a>

###  isNumber

► **isNumber**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:162](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L162)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isnumberstart"></a>

###  isNumberStart

► **isNumberStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:159](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L159)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isoperator"></a>

###  isOperator

► **isOperator**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:165](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L165)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="ispunctuation"></a>

###  isPunctuation

► **isPunctuation**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:168](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L168)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isquote"></a>

###  isQuote

► **isQuote**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:171](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L171)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswhitespace"></a>

###  isWhitespace

► **isWhitespace**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:150](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L150)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="isword"></a>

###  isWord

► **isWord**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:156](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L156)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="iswordstart"></a>

###  isWordStart

► **isWordStart**(str: *`string`*): `boolean`



*Defined in [_lib/Tokenizer.ts:153](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L153)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| str | `string`   |  - |





**Returns:** `boolean`





___

<a id="next"></a>

###  next

► **next**(): `any`



*Defined in [_lib/Tokenizer.ts:15](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L15)*





**Returns:** `any`





___

<a id="peek"></a>

###  peek

► **peek**(): `any`



*Defined in [_lib/Tokenizer.ts:136](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Tokenizer.ts#L136)*





**Returns:** `any`





___


