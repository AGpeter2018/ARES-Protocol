// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Interfaces/IDelayExecution.sol";

abstract contract DelayExecution is IDelayExecution {
    uint256 public constant TIMELOCK_DURATION = 1 hours; 

    mapping(uint256 => uint256) public executionTime;

    function setExecutionTime(uint256 proposalId) internal returns (uint256) {
        uint256 execTime = block.timestamp + TIMELOCK_DURATION;
        executionTime[proposalId] = execTime;
        return execTime;
    }

    function isReady(uint256 proposalId) public view returns (bool) {
        return executionTime[proposalId] != 0 && block.timestamp >= executionTime[proposalId];
    }
}