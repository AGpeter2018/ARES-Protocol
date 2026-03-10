// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMerkleDistributor {
    event Claimed(uint256 index, address account, uint256 amount);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    function merkleRoot() external view returns (bytes32);
    function isClaimed(uint256 index) external view returns (bool);
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
    function updateMerkleRoot(bytes32 newRoot) external;
}
