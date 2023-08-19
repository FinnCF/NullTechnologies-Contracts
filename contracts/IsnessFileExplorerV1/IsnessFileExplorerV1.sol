// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/**
 * @title IsnessV1FileFactory
 * @dev This contract manages encrypted files and access controls for those files.
 */
contract IsnessFileExplorerV1 {

    // Events to log significant state changes and actions in the contract.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event BaseFeeChanged(uint256 indexed newBaseFee);
    event BytesFeeMultiplierChanged(uint256 indexed newBytesFeeMultiplier);
    event GrantingFeeChanged(uint256 indexed newGrantingFee);
    event FileAdded(address indexed user, uint256 indexed fileIndex);
    event FileAccessGranted(uint256 indexed fileIndex, address indexed grantee);
    event FeesCollected(address indexed owner, uint256 amount);
    event FeePaid(address indexed payer, uint256 amount, string action);

    // Structure to represent a file with its encrypted data and access controls.
    struct File {
        bytes encryptedData;
        bytes encryptedName;
        bytes encryptedFolder;
        bytes encryptedKind;
        bytes iv;
        uint256 creationTimestamp;
        uint256 creationBlockNumber;
        address[] withAccessKey; // Users who have access to this file.
    }

    // Structure to represent an access key for a file with its encrypted AES key.
    struct FileAccessKey {
        address grantor; // Address who granted access.
        uint256 fileIndex; // Index of the file in the array.
        bytes encryptedAesKey; // Encrypted AES key for this file.
    }

    // State variables.
    address public owner;
    uint256 public totalAccessCount;
    uint256 public grantingFee; // Fee for granting access to a file.
    uint256 public baseFee; // Base fee to add a file.
    uint256 public bytesFeeMultiplier; // Multiplier for file bytes to calculate fee.

    // Array to store all files.
    File[] public files; 
    // Mapping to store AES access keys for each user.
    mapping(address => FileAccessKey[]) public userFilesAccessAesKeys;

    /**
     * @dev Constructor that sets the initial bytes fee multiplier and the contract owner.
     * @param _initialBytesFeeMultiplier Initial multiplier value for byte-based fee.
     */
    constructor(uint256 _initialBytesFeeMultiplier) {
        owner = msg.sender;
        bytesFeeMultiplier = _initialBytesFeeMultiplier;
        emit OwnerChanged(address(0), msg.sender);
    }

    // Modifier to restrict function calls only by the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /**
     * @dev Function to add a new encrypted file.
     * @param encryptedData Encrypted file data.
     * @param encryptedName Encrypted file name.
     * @param encryptedFolder Encrypted folder name for the file.
     * @param encryptedKind Encrypted kind/type of the file.
     * @param iv Initialization vector used for encryption.
     * @param ownerEncryptedAesKey Encrypted AES key of the owner.
     * @return The index where the file was added in the array.
     */
    function addFile(
        bytes memory encryptedData,
        bytes memory encryptedName,
        bytes memory encryptedFolder,
        bytes memory encryptedKind,
        bytes memory iv,
        bytes memory ownerEncryptedAesKey
    ) external payable returns (uint256) {
        uint256 totalFee = baseFee + (bytesFeeMultiplier * (encryptedName.length + encryptedData.length + encryptedFolder.length + encryptedKind.length));
        require(msg.value == totalFee, "INVALID_FEE");

        File memory newFile = File({
            encryptedData: encryptedData,
            encryptedName: encryptedName,
            encryptedFolder: encryptedFolder,
            encryptedKind: encryptedKind,
            iv: iv,
            creationTimestamp: block.timestamp, 
            creationBlockNumber: block.number,  
            withAccessKey: new address[](0)
        });
        files.push(newFile);

        uint256 fileIndex = files.length - 1;
        files[fileIndex].withAccessKey.push(msg.sender);

        FileAccessKey memory newAccessKey = FileAccessKey({
            grantor: msg.sender,
            fileIndex: fileIndex,
            encryptedAesKey: ownerEncryptedAesKey
        });

        userFilesAccessAesKeys[msg.sender].push(newAccessKey);
        totalAccessCount += 1;

        emit FeePaid(msg.sender, totalFee, "addFile");
        emit FileAdded(msg.sender, fileIndex);
        emit FileAccessGranted(fileIndex, msg.sender);
        return fileIndex;
    }

    /**
     * @dev Grant access to a file for a user.
     * @param fileIndex Index of the file in the array.
     * @param grantee Address of the user to be granted access.
     * @param encryptedAesKey Encrypted AES key to be given to the grantee.
     */
    function grantFileAccessKey(uint256 fileIndex, address grantee, bytes memory encryptedAesKey) external payable {
        require(fileIndex < files.length, "INVALID_FILE_INDEX");
        require(msg.value == grantingFee, "INVALID_GRANTING_FEE"); 

        userFilesAccessAesKeys[grantee].push(FileAccessKey({
            grantor: msg.sender,
            fileIndex: fileIndex,
            encryptedAesKey: encryptedAesKey
        }));

        files[fileIndex].withAccessKey.push(grantee);
        totalAccessCount += 1;

        emit FeePaid(msg.sender, grantingFee, "grantFileAccess");
        emit FileAccessGranted(fileIndex, grantee);
    }

    /**
     * @dev Checks if a user has an access key for a given file.
     * @param fileIndex Index of the file in the files array.
     * @param user Address of the user to be checked.
     * @return True if the user has an access key for the specified file, otherwise false.
     */
    function hasAccessKey(uint256 fileIndex, address user) external view returns (bool) {
        FileAccessKey[] memory accessKeys = userFilesAccessAesKeys[user];
        for (uint i = 0; i < accessKeys.length; i++) {
            if (accessKeys[i].fileIndex == fileIndex) {
                return true; 
            }
        }
        return false; 
    }

    /**
     * @dev Get the total number of files added to the contract.
     * @return The total number of files.
     */
    function getTotalFilesCount() external view returns (uint256) {
        return files.length;
    }

    /**
     * @dev Get the number of accesses granted for a specific file.
     * @param fileIndex Index of the file in the files array.
     * @return The number of accesses granted for the specified file.
     */
    function getFileAccessCount(uint256 fileIndex) external view returns (uint256) {
        require(fileIndex < files.length, "INVALID_FILE_INDEX");
        return files[fileIndex].withAccessKey.length;
    }

    /**
     * @dev Set a new owner for the contract.
     * @param _owner Address of the new owner.
     */
    function setOwner(address _owner) external onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /**
     * @dev Set the base fee for adding files.
     * @param _baseFee New base fee value.
     */
    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
        emit BaseFeeChanged(_baseFee);
    }

    /**
     * @dev Set the bytes fee multiplier for file size.
     * @param _bytesFeeMultiplier New multiplier value.
     */
    function setBytesFeeMultiplier(uint256 _bytesFeeMultiplier) external onlyOwner {
        bytesFeeMultiplier = _bytesFeeMultiplier;
        emit BytesFeeMultiplierChanged(_bytesFeeMultiplier);
    }

    /**
     * @dev Set the fee for granting file access.
     * @param _grantingFee New granting fee value.
     */
    function setGrantingFee(uint256 _grantingFee) external onlyOwner {
        grantingFee = _grantingFee;
        emit GrantingFeeChanged(_grantingFee);  
    }

    /**
     * @dev Transfer all accumulated fees to the contract owner.
     */
    function collectFees() external onlyOwner {
        emit FeesCollected(owner, address(this).balance);
        payable(owner).transfer(address(this).balance);
    }
}
