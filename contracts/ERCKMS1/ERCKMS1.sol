// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERCKMS1 - Ethereum RSA Cryptographic Key Management System
 * @dev A contract for managing cryptographic keys using RSA encryption. It allows for the addition, retrieval, and management of RSA keys tied to Ethereum addresses. It also enables the contract owner to set a fee for adding keys and collect accumulated fees.
 */
contract ERCKMS1 is Ownable {
    uint256 public _fee; // Fee required to add a new key

    /**
     * @dev Initializes the contract with an initial fee and transfers ownership to the provided address.
     * @param _initialFee The initial fee required to add a new key.
     * @param _owner The address to which ownership of the contract will be transferred.
     */
    constructor(uint256 _initialFee, address _owner) {
        _fee = _initialFee;
        transferOwnership(_owner);
    }

    /**
     * @dev Allows the owner to set a new fee for adding keys.
     * @param newFee The new fee amount.
     */
    function setFee(uint256 newFee) public onlyOwner {
        _fee = newFee;
    }

    /**
     * @dev Allows the owner to withdraw the balance accumulated from the fees.
     */
    function collectFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to collect");
        payable(owner()).transfer(balance);
    }

    // Struct representing a cryptographic key.
    struct Key {
        address owner;
        string publicKeyBase64;
        string encryptedPrivateKeyBase64;
        string ivBase64;
        uint256 blockNumber;
    }

    event KeyMade(address indexed user); // Event emitted when a new key is made.

    mapping(address => Key[]) public keys; // Mapping of Ethereum addresses to their keys.
    Key[] public allKeys; // Array of all keys.

    /**
     * @dev Allows users to add a new key by paying the required fee.
     * @param publicKeyBase64 The public key in Base64.
     * @param encryptedPrivateKeyBase64 The encrypted private key in Base64.
     * @param ivBase64 The initialization vector in Base64.
     */
    function addKey(
        string memory publicKeyBase64,
        string memory encryptedPrivateKeyBase64,
        string memory ivBase64
    ) public payable {
        require(msg.value == _fee, "Exact fee not met");
        Key memory newKey = Key(
            msg.sender,
            publicKeyBase64,
            encryptedPrivateKeyBase64,
            ivBase64,
            block.number
        );
        keys[msg.sender].push(newKey);
        allKeys.push(newKey);
        emit KeyMade(msg.sender);
    }

    /**
     * @dev Returns the latest key for a given address.
     * @param _address The address for which to return the key.
     * @return The latest key for the given address.
     */
    function getCurrentKey(address _address) public view returns (Key memory) {
        require(keys[_address].length > 0, "No keys found for the address");
        return keys[_address][keys[_address].length - 1];
    }

    /**
     * @dev Returns the number of keys for a given user.
     * @param _address The address for which to return the key count.
     * @return The number of keys for the given address.
     */
    function getUserKeysLength(address _address) public view returns (uint256) {
        return keys[_address].length;
    }

    /**
     * @dev Returns all keys for a given address.
     * @param _address The address for which to return the keys.
     * @return An array of keys for the given address.
     */
    function getKeys(address _address) public view returns (Key[] memory) {
        return keys[_address];
    }

    /**
     * @dev Returns all keys managed by the contract.
     * @return An array of all keys.
     */
    function getAllKeys() public view returns (Key[] memory) {
        return allKeys;
    }

    /**
     * @dev Returns the total number of keys managed by the contract.
     * @return The total number of keys.
     */
    function getAllKeysLength() public view returns (uint256) {
        return allKeys.length;
    }

    /**
     * @dev Provides instructions for encrypting and decrypting the encryptedPrivateKey.
     * @return Explanation of the encryption and decryption process.
     */    
    function getDecryptionInstructions() public pure returns (string memory) {
        return (
            "ENCRYPTION PROCESS:\n"
            "1) Key Pair Generation: A public-private key pair is generated using the RSASSA-PKCS1-v1_5 algorithm. A 4096-bit modulus and a public exponent of [1, 0, 1] are used, and the hash algorithm is SHA-256. Keys are then encoded.\n"
            "2) Signature Creation: The owner of the key creates a signature by signing the public RSA key with their private Ethereum key.\n"
            "3) Signature Hashing: The signature is hashed with the SHA-256 algorithm, resulting in a fixed-size hash value of 256bits.\n"
            "4) Encryption of Private Key: Using the hashed signature as a secret key, the private RSA key is encrypted with AES-256. AES in Cipher Block Chaining (CBC) mode is used, and a random initialization vector (IV) is generated to ensure unique encryption.\n"
            "5) Decryption of Private Key: To decrypt the encrypted private key, the owner recreates the hash by signing the public RSA key and hashing it with SHA-256 again. The encrypted private key is then decrypted using the hashed signature, IV and AES-CBC.\n"
            "This process ensures that only the owner, with the correct private Ethereum key, can derive the secret key needed for decryption. Standardized algorithms are used, enabling compatibility with various implementations. It is an extension of an ethereum private key to allow for the storage of RSA keys."
        );
    }
}
