[poetry](../README.md) > ["_lib/Reader"](../modules/__lib_reader_.md) > [Reader](../classes/__lib_reader_.reader.md)

# Class: Reader

Character reader for reading strings one character at a time.

## Hierarchy

**Reader**

## Index

### Constructors

* [constructor](__lib_reader_.reader.md#constructor)

### Properties

* [column](__lib_reader_.reader.md#column)
* [line](__lib_reader_.reader.md#line)
* [pos](__lib_reader_.reader.md#pos)
* [src](__lib_reader_.reader.md#src)

### Methods

* [error](__lib_reader_.reader.md#error)
* [isEof](__lib_reader_.reader.md#iseof)
* [next](__lib_reader_.reader.md#next)
* [peek](__lib_reader_.reader.md#peek)

---

## Constructors

<a id="constructor"></a>

###  constructor

⊕ **new Reader**(src: *`string`*): [Reader](__lib_reader_.reader.md)

*Defined in [_lib/Reader.ts:7](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L7)*

**Parameters:**

| Param | Type |
| ------ | ------ |
| src | `string` |

**Returns:** [Reader](__lib_reader_.reader.md)

___

## Properties

<a id="column"></a>

###  column

**● column**: *`number`* = 0

*Defined in [_lib/Reader.ts:7](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L7)*

___
<a id="line"></a>

###  line

**● line**: *`number`* = 1

*Defined in [_lib/Reader.ts:6](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L6)*

___
<a id="pos"></a>

###  pos

**● pos**: *`number`* = 0

*Defined in [_lib/Reader.ts:5](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L5)*

___
<a id="src"></a>

###  src

**● src**: *`string`*

*Defined in [_lib/Reader.ts:9](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L9)*

___

## Methods

<a id="error"></a>

###  error

▸ **error**(msg: *`string`*): `void`

*Defined in [_lib/Reader.ts:32](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L32)*

**Parameters:**

| Param | Type |
| ------ | ------ |
| msg | `string` |

**Returns:** `void`

___
<a id="iseof"></a>

###  isEof

▸ **isEof**(): `boolean`

*Defined in [_lib/Reader.ts:28](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L28)*

**Returns:** `boolean`

___
<a id="next"></a>

###  next

▸ **next**(): `string`

*Defined in [_lib/Reader.ts:13](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L13)*

**Returns:** `string`

___
<a id="peek"></a>

###  peek

▸ **peek**(): `string`

*Defined in [_lib/Reader.ts:24](https://github.com/FantasyInternet/poetry/blob/HEAD/src/script/_lib/Reader.ts#L24)*

**Returns:** `string`

___
