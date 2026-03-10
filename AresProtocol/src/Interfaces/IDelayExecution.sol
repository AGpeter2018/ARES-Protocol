// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDelayExecution {
    function TIMELOCK_DURATION() external view returns (uint256);
    function executionTime(uint256 proposalId) external view returns (uint256);
    function isReady(uint256 proposalId) external view returns (bool);
}
