// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISignatureVerifier {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function ACTION_TYPEHASH() external view returns (bytes32);
    function nonces(address signer) external view returns (uint256);
}
