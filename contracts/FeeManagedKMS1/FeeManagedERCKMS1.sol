// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERCKMS1/ERCKMS1.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";

contract FeeManagedERCKMS1 is Ownable, ERCKMS1 {

    uint256 public fee; // Fee required to add a new key

    constructor(uint256 _initialFee) {
        fee = _initialFee;
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function collectFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to collect");
        payable(owner()).transfer(balance);
    }

    function addKeyWithFee(
        string memory publicKeyBase64,
        string memory encryptedPrivateKeyBase64,
        string memory ivBase64
    ) public payable {
        require(msg.value == fee, "Exact fee not met");
        addKey(publicKeyBase64, encryptedPrivateKeyBase64, ivBase64);
    } 
}
