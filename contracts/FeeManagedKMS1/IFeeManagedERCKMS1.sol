// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../ERCKMS1/IERCKMS1.sol';

interface IFeeManagedERCKMS1 is IERCKMS1 {
    function addKeyWithFee(
        string memory publicKeyBase64,
        string memory encryptedPrivateKeyBase64,
        string memory ivBase64
    ) external payable;
}