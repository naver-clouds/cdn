/**
 * Originally from https://github.com/QwantResearch/masq-common/
 * with improvements by Andrei Sambra
 */
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
(function (factory) {
    if (typeof module === "object" && typeof module.exports === "object") {
        var v = factory(require, exports);
        if (v !== undefined) module.exports = v;
    }
    else if (typeof define === "function" && define.amd) {
        define(["require", "exports", "buffer"], factory);
    }
})(function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports._genRandomBufferAsStr = exports._genRandomBuffer = exports.updatePassphraseKey = exports.decryptMasterKey = exports.genEncryptedMasterKey = exports.decryptBuffer = exports.encryptBuffer = exports.decrypt = exports.encrypt = exports.exportKey = exports.importKey = exports.genAESKey = exports.verify = exports.sign = exports.exportPrivateKey = exports.exportPublicKey = exports.importPrivateKey = exports.importPublicKey = exports.genKeyPair = exports.hash = exports.genId = void 0;
    var buffer_1 = require("buffer");
    var checkCryptokey = function (key) {
        if (!key.type || key.type !== 'secret') {
            throw new Error('Invalid key type');
        }
    };
    var genRandomBuffer = function (len) {
        if (len === void 0) { len = 16; }
        var values = globalThis.crypto.getRandomValues(new Uint8Array(len));
        return buffer_1.Buffer.from(values);
    };
    var genRandomBufferAsStr = function (len, encodingFormat) {
        if (len === void 0) { len = 16; }
        if (encodingFormat === void 0) { encodingFormat = 'hex'; }
        if (encodingFormat) {
            checkEncodingFormat(encodingFormat);
        }
        var buf = genRandomBuffer(len);
        return buf.toString(encodingFormat);
    };
    var checkPassphrase = function (str) {
        if (typeof str !== 'string' || str === '') {
            throw new Error("Not a valid value");
        }
    };
    var checkEncodingFormat = function (format) {
        if (format !== 'hex' && format !== 'base64')
            throw new Error('Invalid encoding');
    };
    /**
     * Generate a random hexadecimal ID of a given length
     *
     * @param {integer} [len] The string length of the new ID
     * @returns {string} The new ID
     */
    var genId = function (len) {
        if (len === void 0) { len = 32; }
        // 2 bytes for each char
        return genRandomBufferAsStr(Math.floor(len / 2));
    };
    exports.genId = genId;
    /**
     * Generate the hash of a string or ArrayBuffer
     *
     * @param {string | arrayBuffer} data The message
     * @param {string} [format] The encoding format ('hex' by default, can also be 'base64')
     * @param {string} [name] The hashing algorithm (SHA-256 by default)
     * @returns {Promise<String>}  A promise that contains the hash as a String encoded with encodingFormat
     */
    var hash = function (data, format, name) {
        if (format === void 0) { format = 'hex'; }
        if (name === void 0) { name = 'SHA-256'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var digest;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, globalThis.crypto.subtle.digest({
                            name: name
                        }, (typeof data === 'string') ? buffer_1.Buffer.from(data) : data)];
                    case 1:
                        digest = _a.sent();
                        return [2 /*return*/, buffer_1.Buffer.from(digest).toString(format)];
                }
            });
        });
    };
    exports.hash = hash;
    /**
       * Generate an ECDA key pair based on the provided curve name
       *
       * @param {boolean} extractable - Specify if the generated key is extractable
       * @param {namedCurve} namedCurve - The curve name to use
       * @returns {Promise<CryptoKey>} - A promise containing the key pair
       */
    var genKeyPair = function (extractable, namedCurve) {
        if (extractable === void 0) { extractable = true; }
        if (namedCurve === void 0) { namedCurve = 'P-256'; }
        return globalThis.crypto.subtle.generateKey({
            name: 'ECDSA',
            namedCurve: namedCurve // can be "P-256", "P-384", or "P-521"
        }, extractable, ['sign', 'verify']);
    };
    exports.genKeyPair = genKeyPair;
    function importPublicKey(key, namedCurve, format) {
        if (namedCurve === void 0) { namedCurve = 'P-256'; }
        if (format === void 0) { format = 'base64'; }
        return globalThis.crypto.subtle.importKey('spki', typeof key === 'string' ? buffer_1.Buffer.from(key, format) : key, {
            name: 'ECDSA',
            namedCurve: namedCurve // can be "P-256", "P-384", or "P-521"
        }, true, ['verify']);
    }
    exports.importPublicKey = importPublicKey;
    function importPrivateKey(key, namedCurve, format) {
        if (namedCurve === void 0) { namedCurve = 'P-256'; }
        if (format === void 0) { format = 'base64'; }
        return globalThis.crypto.subtle.importKey('pkcs8', typeof key === 'string' ? buffer_1.Buffer.from(key, format) : key, {
            name: 'ECDSA',
            namedCurve: namedCurve // can be "P-256", "P-384", or "P-521"
        }, true, ['sign']);
    }
    exports.importPrivateKey = importPrivateKey;
    function exportPublicKey(key, format) {
        if (format === void 0) { format = 'base64'; }
        return __awaiter(this, void 0, void 0, function () {
            var exported;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, globalThis.crypto.subtle.exportKey('spki', key)];
                    case 1:
                        exported = _a.sent();
                        return [2 /*return*/, (format === 'raw') ? new Uint8Array(exported) : buffer_1.Buffer.from(exported).toString(format)];
                }
            });
        });
    }
    exports.exportPublicKey = exportPublicKey;
    function exportPrivateKey(key, format) {
        if (format === void 0) { format = 'base64'; }
        return __awaiter(this, void 0, void 0, function () {
            var exported;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, globalThis.crypto.subtle.exportKey('pkcs8', key)];
                    case 1:
                        exported = _a.sent();
                        return [2 /*return*/, (format === 'raw') ? new Uint8Array(exported) : buffer_1.Buffer.from(exported).toString(format)];
                }
            });
        });
    }
    exports.exportPrivateKey = exportPrivateKey;
    /**
     * Sign data using the private key
     *
     * @param {CryptoKey} key - The private key
     * @param {*} data - Data to sign
     * @param {*} hash - The hashing algorithm
     * @returns {Promise<arrayBuffer>} - The raw signature
     */
    var sign = function (key, data, format, hash) {
        if (format === void 0) { format = 'base64'; }
        if (hash === void 0) { hash = 'SHA-256'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var signature;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, globalThis.crypto.subtle.sign({
                            name: 'ECDSA',
                            hash: { name: hash } // can be "SHA-1", "SHA-256", "SHA-384", or "SHA-512"
                        }, key, buffer_1.Buffer.from(typeof data === "string" ? data : JSON.stringify(data)))];
                    case 1:
                        signature = _a.sent();
                        return [2 /*return*/, (format === 'raw') ? new Uint8Array(signature) : buffer_1.Buffer.from(signature).toString(format)];
                }
            });
        });
    };
    exports.sign = sign;
    /**
     * Verify data using the public key
     *
     * @param {CryptoKey} key - The public key
     * @param {*} data - Data to verify
     * @param {*} hash - The hashing algorithm
     * @returns {Promise<boolean>} - The verification outcome
     */
    var verify = function (key, data, signature, format, hash) {
        if (format === void 0) { format = 'base64'; }
        if (hash === void 0) { hash = 'SHA-256'; }
        return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                return [2 /*return*/, globalThis.crypto.subtle.verify({
                        name: 'ECDSA',
                        hash: { name: hash } // can be "SHA-1", "SHA-256", "SHA-384", or "SHA-512"
                    }, key, buffer_1.Buffer.from(signature, format), buffer_1.Buffer.from(typeof data === "string" ? data : JSON.stringify(data)))];
            });
        });
    };
    exports.verify = verify;
    /**
       * Generate an AES key based on the cipher mode and keysize
       *
       * @param {boolean} [extractable] - Specify if the generated key is extractable
       * @param {string} [mode] - The aes mode of the generated key
       * @param {Number} [keySize] - Specify if the generated key is extractable
       * @returns {Promise<CryptoKey>} - The generated AES key.
       */
    var genAESKey = function (extractable, mode, keySize) {
        if (extractable === void 0) { extractable = true; }
        if (mode === void 0) { mode = 'AES-GCM'; }
        if (keySize === void 0) { keySize = 128; }
        return globalThis.crypto.subtle.generateKey({
            name: mode,
            length: keySize
        }, extractable, ['decrypt', 'encrypt']);
    };
    exports.genAESKey = genAESKey;
    /**
        * Import a raw|jwk as a CryptoKey
        *
        * @param {arrayBuffer|Object} key - The key
        * @param {string} [type] - The type of the key to import ('raw', 'jwk')
        * @param {string} [mode] - The mode of the key to import (default 'AES-GCM')
        * @returns {Promise<arrayBuffer>} - The cryptoKey
        */
    var importKey = function (key, type, mode) {
        if (type === void 0) { type = 'raw'; }
        if (mode === void 0) { mode = 'AES-GCM'; }
        var parsedKey = (type === 'raw') ? buffer_1.Buffer.from(key, 'base64') : key;
        return globalThis.crypto.subtle.importKey(type, parsedKey, { name: mode }, true, ['encrypt', 'decrypt']);
    };
    exports.importKey = importKey;
    /**
      * Export a CryptoKey into a raw|jwk key
      *
      * @param {CryptoKey} key - The CryptoKey
      * @param {string} [type] - The type of the exported key: raw|jwk
      * @returns {Promise<arrayBuffer>} - The raw key or the key as a jwk format
      */
    var exportKey = function (key, type) {
        if (type === void 0) { type = 'raw'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var exportedKey;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, globalThis.crypto.subtle.exportKey(type, key)];
                    case 1:
                        exportedKey = _a.sent();
                        return [2 /*return*/, (type === 'raw') ? new Uint8Array(exportedKey) : exportedKey];
                }
            });
        });
    };
    exports.exportKey = exportKey;
    /**
       * Encrypt buffer
       *
       * @param {ArrayBuffer} key - The AES CryptoKey
       * @param {ArrayBuffer} data - Data to encrypt
       * @param {Object} cipherContext - The AES cipher parameters
       * @returns {ArrayBuffer} - The encrypted buffer
       */
    var encryptBuffer = function (key, data, cipherContext) { return __awaiter(void 0, void 0, void 0, function () {
        var encrypted;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, globalThis.crypto.subtle.encrypt(cipherContext, key, data)];
                case 1:
                    encrypted = _a.sent();
                    return [2 /*return*/, new Uint8Array(encrypted)];
            }
        });
    }); };
    exports.encryptBuffer = encryptBuffer;
    /**
     * Decrypt buffer
     * @param {ArrayBuffer} key - The AES CryptoKey
     * @param {ArrayBuffer} data - Data to decrypt
     * @param {Object} cipherContext - The AES cipher parameters
     * @returns {Promise<ArrayBuffer>} - The decrypted buffer
     */
    var decryptBuffer = function (key, data, cipherContext) { return __awaiter(void 0, void 0, void 0, function () {
        var decrypted, e_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, globalThis.crypto.subtle.decrypt(cipherContext, key, data)];
                case 1:
                    decrypted = _a.sent();
                    return [2 /*return*/, new Uint8Array(decrypted)];
                case 2:
                    e_1 = _a.sent();
                    if (e_1 instanceof Error && e_1.message === 'Unsupported state or unable to authenticate data') {
                        throw new Error('Unable to decrypt data');
                    }
                    else if (typeof e_1 === 'string') {
                        throw new Error(e_1);
                    }
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    }); };
    exports.decryptBuffer = decryptBuffer;
    /**
     * Encrypt data
     *
     * @param {CryptoKey} key - The AES CryptoKey
     * @param {string | Object} - The data to encrypt
     * @param {string} [format] - The ciphertext and iv encoding format
     * @returns {Object} - The stringified ciphertext object (ciphertext and iv)
     */
    var encrypt = function (key, data, format) {
        if (format === void 0) { format = 'hex'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var context, cipherContext, encrypted;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        checkCryptokey(key);
                        context = {
                            iv: genRandomBuffer(key.algorithm.name === 'AES-GCM' ? 12 : 16),
                            plaintext: buffer_1.Buffer.from(JSON.stringify(data))
                        };
                        cipherContext = {
                            name: key.algorithm.name,
                            iv: context.iv
                        };
                        return [4 /*yield*/, encryptBuffer(key, context.plaintext, cipherContext)];
                    case 1:
                        encrypted = _a.sent();
                        return [2 /*return*/, {
                                ciphertext: buffer_1.Buffer.from(encrypted).toString(format),
                                iv: buffer_1.Buffer.from(context.iv).toString(format)
                            }];
                }
            });
        });
    };
    exports.encrypt = encrypt;
    /**
       * Decrypt data
       *
       * @param {CryptoKey} key - The AES CryptoKey
       * @param {string | Object} - The data to decrypt
       * @param {string} [format] - The ciphertext and iv encoding format
       */
    var decrypt = function (key, ciphertext, format) {
        if (format === void 0) { format = 'hex'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var context, cipherContext, decrypted, error_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        checkCryptokey(key);
                        context = {
                            ciphertext: buffer_1.Buffer.from(Object.prototype.hasOwnProperty.call(ciphertext, 'ciphertext') ? ciphertext.ciphertext : '', (format)),
                            // IV is 128 bits long === 16 bytes
                            iv: Object.prototype.hasOwnProperty.call(ciphertext, 'iv') ? buffer_1.Buffer.from(ciphertext.iv, (format)) : ''
                        };
                        cipherContext = {
                            name: key.algorithm.name,
                            iv: context.iv
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, decryptBuffer(key, context.ciphertext, cipherContext)];
                    case 2:
                        decrypted = _a.sent();
                        if (decrypted === undefined) {
                            throw new Error();
                        }
                        return [2 /*return*/, JSON.parse(buffer_1.Buffer.from(decrypted).toString())];
                    case 3:
                        error_1 = _a.sent();
                        throw new Error('Unable to decrypt data');
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    exports.decrypt = decrypt;
    /**
     * Generate a PBKDF2 derived key (bits) based on user given passPhrase
     *
     * @param {string | arrayBuffer} passPhrase The passphrase that is used to derive the key
     * @param {arrayBuffer} [salt] The salt
     * @param {Number} [iterations] The iterations number
     * @param {string} [hashAlgo] The hash function used for derivation
     * @returns {Promise<Uint8Array>} A promise that contains the derived key
     */
    var deriveBits = function (passPhrase, salt, iterations, hashAlgo) { return __awaiter(void 0, void 0, void 0, function () {
        var baseKey, derivedKey;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    // Always specify a strong salt
                    if (iterations < 10000) {
                        console.warn('Less than 10000 :(');
                    }
                    return [4 /*yield*/, globalThis.crypto.subtle.importKey('raw', (typeof passPhrase === 'string') ? buffer_1.Buffer.from(passPhrase) : passPhrase, 'PBKDF2', false, ['deriveBits', 'deriveKey'])];
                case 1:
                    baseKey = _a.sent();
                    return [4 /*yield*/, globalThis.crypto.subtle.deriveBits({
                            name: 'PBKDF2',
                            salt: salt || new Uint8Array([]),
                            iterations: iterations || 100000,
                            hash: hashAlgo || 'SHA-256'
                        }, baseKey, 128)];
                case 2:
                    derivedKey = _a.sent();
                    return [2 /*return*/, new Uint8Array(derivedKey)];
            }
        });
    }); };
    /**
     * Derive a key based on a given passphrase
     *
     * @param {string} passPhrase The passphrase that is used to derive the key
     * @param {arrayBuffer} [salt] The salt
     * @param {Number} [iterations] The iterations number
     * @param {string} [hashAlgo] The hash function used for derivation and final hash computing
     * @returns {Promise<keyEncryptionKey>} A promise that contains the derived key and derivation
     * parameters
     */
    var deriveKeyFromPassphrase = function (passPhrase, salt, iterations, hashAlgo) {
        if (salt === void 0) { salt = genRandomBuffer(16); }
        if (iterations === void 0) { iterations = 100000; }
        if (hashAlgo === void 0) { hashAlgo = 'SHA-256'; }
        return __awaiter(void 0, void 0, void 0, function () {
            var derivedKey, key;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        checkPassphrase(passPhrase);
                        return [4 /*yield*/, deriveBits(passPhrase, salt, iterations, hashAlgo)];
                    case 1:
                        derivedKey = _a.sent();
                        return [4 /*yield*/, importKey(derivedKey)];
                    case 2:
                        key = _a.sent();
                        return [2 /*return*/, {
                                derivationParams: {
                                    salt: buffer_1.Buffer.from(salt).toString('hex'),
                                    iterations: iterations,
                                    hashAlgo: hashAlgo
                                },
                                key: key
                            }];
                }
            });
        });
    };
    /**
     * Derive the passphrase with PBKDF2 to obtain a KEK
     * Generate a AES key (masterKey)
     * Encrypt the masterKey with the KEK
     *
     * @param {string} passPhrase The passphrase that is used to derive the key
     * @param {arrayBuffer} [salt] The salt
     * @param {Number} [iterations] The iterations number
     * @param {string} [hashAlgo] The hash function used for derivation and final hash computing
     * @returns {Promise<protectedMasterKey>} A promise that contains the encrypted derived key
     */
    var genEncryptedMasterKey = function (passPhrase, salt, iterations, hashAlgo) { return __awaiter(void 0, void 0, void 0, function () {
        var keyEncryptionKey, masterKey, encryptedMasterKey;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, deriveKeyFromPassphrase(passPhrase, salt, iterations, hashAlgo)
                    // Generate the masterKey
                ];
                case 1:
                    keyEncryptionKey = _a.sent();
                    masterKey = genRandomBufferAsStr(32, 'hex');
                    return [4 /*yield*/, encrypt(keyEncryptionKey.key, masterKey)];
                case 2:
                    encryptedMasterKey = _a.sent();
                    return [2 /*return*/, {
                            derivationParams: keyEncryptionKey.derivationParams,
                            encryptedMasterKey: encryptedMasterKey
                        }];
            }
        });
    }); };
    exports.genEncryptedMasterKey = genEncryptedMasterKey;
    /**
     * Update the derived encryption key (KEK) based on the new passphrase from user, while retaining
     * the symmetric key that encrypts data at rest
     *
     * @param {string} currentPassPhrase The current (old) passphrase that is used to derive the key
     * @param {string} newPassPhrase The new passphrase that will be used to derive the key
     * @param {oldMasterKey} oldMasterKey - The old object returned by genEncryptedMasterKey for the old passphrase
     * @param {arrayBuffer} [salt] The salt
     * @param {Number} [iterations] The iterations number
     * @param {string} [hashAlgo] The hash function used for derivation and final hash computing
     * @returns {Promise<protectedMasterKey>}
     */
    var updatePassphraseKey = function (currentPassPhrase, newPassPhrase, oldMasterKey, salt, iterations, hashAlgo) { return __awaiter(void 0, void 0, void 0, function () {
        var masterKey, keyEncryptionKey, toBeEncryptedMasterKey, _a, _b, encryptedMasterKey;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0: return [4 /*yield*/, decryptMasterKey(currentPassPhrase, oldMasterKey)
                    // derive a new key encryption key from newPassPhrase
                ];
                case 1:
                    masterKey = _c.sent();
                    return [4 /*yield*/, deriveKeyFromPassphrase(newPassPhrase, salt, iterations, hashAlgo)
                        // enconde existing masterKey as a hex string since it's a buffer
                    ];
                case 2:
                    keyEncryptionKey = _c.sent();
                    _b = (_a = buffer_1.Buffer).from;
                    return [4 /*yield*/, exportKey(masterKey)];
                case 3:
                    toBeEncryptedMasterKey = _b.apply(_a, [_c.sent()]).toString('hex');
                    return [4 /*yield*/, encrypt(keyEncryptionKey.key, toBeEncryptedMasterKey)];
                case 4:
                    encryptedMasterKey = _c.sent();
                    return [2 /*return*/, {
                            derivationParams: keyEncryptionKey.derivationParams,
                            encryptedMasterKey: encryptedMasterKey
                        }];
            }
        });
    }); };
    exports.updatePassphraseKey = updatePassphraseKey;
    /**
     * Decrypt a master key by deriving the encryption key from the
     * provided passphrase and encrypted master key.
     *
     * @param {string | arrayBuffer} passPhrase The passphrase that is used to derive the key
     * @param {protectedMasterKey} protectedMasterKey - The same object returned
     * by genEncryptedMasterKey
     * @returns {Promise<masterKey>} A promise that contains the masterKey
     */
    var decryptMasterKey = function (passPhrase, protectedMasterKey) { return __awaiter(void 0, void 0, void 0, function () {
        var derivationParams, encryptedMasterKey, salt, iterations, hashAlgo, _salt, derivedKey, keyEncryptionKey, decryptedMasterKeyHex, parsedKey, error_2;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (!protectedMasterKey.encryptedMasterKey ||
                        !protectedMasterKey.derivationParams) {
                        throw new Error('Missing properties from master key');
                    }
                    derivationParams = protectedMasterKey.derivationParams, encryptedMasterKey = protectedMasterKey.encryptedMasterKey;
                    salt = derivationParams.salt, iterations = derivationParams.iterations, hashAlgo = derivationParams.hashAlgo;
                    _salt = typeof (salt) === 'string' ? buffer_1.Buffer.from(salt, ('hex')) : salt;
                    return [4 /*yield*/, deriveBits(passPhrase, _salt, iterations, hashAlgo)];
                case 1:
                    derivedKey = _a.sent();
                    return [4 /*yield*/, importKey(derivedKey)];
                case 2:
                    keyEncryptionKey = _a.sent();
                    _a.label = 3;
                case 3:
                    _a.trys.push([3, 5, , 6]);
                    return [4 /*yield*/, decrypt(keyEncryptionKey, encryptedMasterKey)
                        // return decryptedMasterKeyHex
                    ];
                case 4:
                    decryptedMasterKeyHex = _a.sent();
                    parsedKey = buffer_1.Buffer.from(decryptedMasterKeyHex, 'hex');
                    return [2 /*return*/, globalThis.crypto.subtle.importKey('raw', parsedKey, { name: 'AES-GCM' }, true, ['encrypt', 'decrypt'])];
                case 5:
                    error_2 = _a.sent();
                    throw new Error('Wrong passphrase');
                case 6: return [2 /*return*/];
            }
        });
    }); };
    exports.decryptMasterKey = decryptMasterKey;
    var _genRandomBuffer = genRandomBuffer;
    exports._genRandomBuffer = _genRandomBuffer;
    var _genRandomBufferAsStr = genRandomBufferAsStr;
    exports._genRandomBufferAsStr = _genRandomBufferAsStr;
});
