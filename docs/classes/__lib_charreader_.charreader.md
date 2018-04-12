[poetry](../README.md) > ["_lib/CharReader"](../modules/__lib_charreader_.md) > [CharReader](../classes/__lib_charreader_.charreader.md)



# Class: CharReader


Character reader for reading strings one character at a time.

## Index

### Constructors

* [constructor](__lib_charreader_.charreader.md#constructor)


### Properties

* [column](__lib_charreader_.charreader.md#column)
* [line](__lib_charreader_.charreader.md#line)
* [pos](__lib_charreader_.charreader.md#pos)
* [src](__lib_charreader_.charreader.md#src)


### Methods

* [error](__lib_charreader_.charreader.md#error)
* [isEof](__lib_charreader_.charreader.md#iseof)
* [next](__lib_charreader_.charreader.md#next)
* [peek](__lib_charreader_.charreader.md#peek)



---
## Constructors
<a id="constructor"></a>


### ⊕ **new CharReader**(src: *`string`*): [CharReader](__lib_charreader_.charreader.md)


*Defined in [_lib/CharReader.ts:7](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L7)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| src | `string`   |  - |





**Returns:** [CharReader](__lib_charreader_.charreader.md)

---


## Properties
<a id="column"></a>

###  column

**●  column**:  *`number`*  = 0

*Defined in [_lib/CharReader.ts:7](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L7)*





___

<a id="line"></a>

###  line

**●  line**:  *`number`*  = 1

*Defined in [_lib/CharReader.ts:6](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L6)*





___

<a id="pos"></a>

###  pos

**●  pos**:  *`number`*  = 0

*Defined in [_lib/CharReader.ts:5](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L5)*





___

<a id="src"></a>

###  src

**●  src**:  *`string`* 

*Defined in [_lib/CharReader.ts:9](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L9)*





___


## Methods
<a id="error"></a>

###  error

► **error**(msg: *`string`*): `void`



*Defined in [_lib/CharReader.ts:32](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L32)*



**Parameters:**

| Param | Type | Description |
| ------ | ------ | ------ |
| msg | `string`   |  - |





**Returns:** `void`





___

<a id="iseof"></a>

###  isEof

► **isEof**(): `boolean`



*Defined in [_lib/CharReader.ts:28](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L28)*





**Returns:** `boolean`





___

<a id="next"></a>

###  next

► **next**(): `string`



*Defined in [_lib/CharReader.ts:13](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L13)*





**Returns:** `string`





___

<a id="peek"></a>

###  peek

► **peek**(): `string`



*Defined in [_lib/CharReader.ts:24](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/CharReader.ts#L24)*





**Returns:** `string`





___


