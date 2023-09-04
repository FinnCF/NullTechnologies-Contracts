// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable} from "../@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "../@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20} from "../@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title EthKeysV1 by Null Technologies LTD
 * @dev The EthKeysV1 contract allows users to store their RSA keys, encrypted with their Ethereum private keys, on-chain.
 */
contract EthKeysV1 is ERC20, Ownable2Step {
    // -------------------- STATE VARIABLES -------------------- //

    // Encryption instructions
    string public encryptionInstructions =
        "ENCRYPTION PROCESS:"
        "1) Key Pair Generation: A public-private key pair is generated using the RSASSA-OAEP algorithm. A 3072-bit modulus and a public exponent of [1, 0, 1] are used. The hash algorithm is SHA-256."
        "2) Signature Creation: The Ethereum address owner signs the public RSA key using their private Ethereum key. This confirms the RSA key pair's ownership."
        "3) Signature Hashing: Hash the created signature with the Keccak-256 algorithm, resulting in a 256-bit hash value."
        "4) Encryption of Private Key: Use the hashed Ethereum signature as a secret to encrypt the private RSA key with AES-256 in CBC mode, ensuring unique encryption with a random initialization vector (IV)."
        "5) Decryption of Private Key: To retrieve the original private RSA key, the owner re-signs the public RSA key and hashes it with Keccak-256. Then, the AES decryption process uses this hash, the IV, and the stored encrypted private RSA key."
        "This encryption ensures only the owner with the correct Ethereum private key can access the RSA private key. It leverages standard algorithms for broader compatibility.";

    // Fee in wei for adding or deleting a key.
    uint256 public keyAdditionFee;
    uint256 public keyDeletionFee;

    // Total number of keys in the contract.
    uint256 public totalKeys;

    // Struct representing a cryptographic key.
    struct Key {
        bytes publicRSAKey;
        bytes encryptedPrivateRSAKey;
        bytes iv;
        uint256 blockNumber;
        uint256 timestamp;
        uint256 deprecated;
    }

    // Mapping of Ethereum addresses to their keys.
    mapping(address => Key[]) public keys;

    // -------------------- EVENTS -------------------- //

    event EncryptionInstructionsUpdated(string newInstructions);
    event AdditionFeeChanged(uint256 newFee);
    event DeletionFeeChanged(uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event KeyMade(address indexed user, uint totalKeys);
    event KeyDeleted(address indexed user, uint totalKeys);

    // -------------------- CONSTRUCTOR -------------------- //

    /**
     * @dev Contract constructor initializes the key addition and deletion fee.
     * @param _keyAdditionFee Initial addition fee.
     *  @param _keyDeletionFee Initial deletion fee.
     */
    constructor(
        uint256 _keyAdditionFee,
        uint256 _keyDeletionFee,
        uint256 initialSupply
    ) ERC20("EthKeysV1", "KEYS") {
        _mint(msg.sender, initialSupply);
        keyAdditionFee = _keyAdditionFee;
        keyDeletionFee = _keyDeletionFee;
        emit AdditionFeeChanged(_keyAdditionFee);
        emit DeletionFeeChanged(_keyDeletionFee);
    }

    // -------------------- OWNER-ONLY FUNCTIONS -------------------- //

    /**
     *  @notice Prevents the owner from renouncing ownership
     *    @dev onlyOwner
     */
    function renounceOwnership() public view override onlyOwner {
        revert();
    }

    /**
     * @dev Sets the Encryption instructions.
     * @param _instructions The new decryption instructions.
     */
    function setEncryptionInstructions(
        string memory _instructions
    ) external onlyOwner {
        encryptionInstructions = _instructions;
        emit EncryptionInstructionsUpdated(_instructions);
    }

    /**
     * @dev Allows the owner to set the fee for adding a key.
     * @param _fee New fee amount.
     */
    function setKeyAdditionFee(uint256 _fee) external onlyOwner {
        keyAdditionFee = _fee;
        emit AdditionFeeChanged(_fee);
    }

    /**
     * @dev Allows the owner to set the fee for deleting the latest key.
     * @param _fee New deletion fee amount.
     */
    function setKeyDeletionFee(uint256 _fee) external onlyOwner {
        keyDeletionFee = _fee;
        emit DeletionFeeChanged(_fee);
    }

    /**
     * @dev Allows the owner to mint new tokens for revenue.
     * @param account Address to which the minted tokens will be sent.
     * @param amount Amount of tokens to mint.
     */
    function ownerMint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @notice Allows a user to add a new RSA key to their collection of keys.
     * @dev The function first ensures that the correct fee is sent and then checks if the user
     * has previous keys. If so, the latest key is marked as deprecated. A new Key instance is
     * then created and appended to the user's key set. The function increments the `totalKeys`
     * counter and emits a `KeyMade` event.
     *
     * @param publicRSAKey - The public part of the RSA key.
     * @param encryptedPrivateRSAKey - The private RSA key, encrypted with the Ethereum private key.
     * @param iv - The initialization vector for encryption.
     */
    function addKey(
        bytes memory publicRSAKey,
        bytes memory encryptedPrivateRSAKey,
        bytes memory iv
    ) external {
        require(
            balanceOf(msg.sender) >= keyAdditionFee,
            "Insufficient KEYS tokens"
        );
        _burn(msg.sender, keyAdditionFee);

        // If the user already has keys, mark the latest one as deprecated
        uint256 userKeyCount = getUserKeysLength(msg.sender);
        if (userKeyCount > 0) {
            keys[msg.sender][userKeyCount - 1].deprecated = block.timestamp;
        }

        // Create the new key instance
        Key memory newKey = Key({
            publicRSAKey: publicRSAKey,
            encryptedPrivateRSAKey: encryptedPrivateRSAKey,
            iv: iv,
            blockNumber: block.number,
            timestamp: block.timestamp,
            deprecated: 0
        });

        // Append the new key to the user's collection and increment the totalKeys counter
        keys[msg.sender].push(newKey);
        totalKeys += 1;

        emit KeyMade(msg.sender, totalKeys);
    }

    /**
     * @notice Allows a user to delete their latest RSA key.
     * @dev The function first checks that the user has sent the correct fee.
     * Then, it checks if the user has at least one key. If the user has
     * more than one key, it undoes the deprecation of the penultimate key.
     * It then deletes the latest key, decrements the totalKeys counter,
     * and emits an event.
     */
    function deleteLatestKey() external {
        require(
            balanceOf(msg.sender) >= keyDeletionFee,
            "Insufficient KEYS tokens"
        );
        _burn(msg.sender, keyDeletionFee);

        uint256 userKeyCount = getUserKeysLength(msg.sender);
        require(userKeyCount > 0, "No keys found for the address");

        if (userKeyCount > 1) {
            keys[msg.sender][userKeyCount - 2].deprecated = 0;
        }

        keys[msg.sender].pop();
        totalKeys -= 1;

        emit KeyDeleted(msg.sender, totalKeys);
    }

    // -------------------- VIEW FUNCTIONS -------------------- //

    /**
     * @dev Retrieves the active key for a given address.
     * @param _address The address for which to return the key.
     * @return The latest key for the provided address.
     */
    function getActiveKey(address _address) public view returns (Key memory) {
        require(keys[_address].length > 0, "No keys found for the address");
        return keys[_address][keys[_address].length - 1];
    }

    /**
     * @dev Retrieves the number of keys for a given address.
     * @param _address The address for which to return the key count.
     * @return The number of keys for the provided address.
     */
    function getUserKeysLength(address _address) public view returns (uint256) {
        return keys[_address].length;
    }

    /**
     * @dev Retrieves all keys for a given address.
     * @param _address The address for which to return the keys.
     * @return Array of keys for the provided address.
     */
    function getKeys(address _address) public view returns (Key[] memory) {
        return keys[_address];
    }
}
