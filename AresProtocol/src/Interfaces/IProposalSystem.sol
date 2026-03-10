// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProposalSystem {
    enum ProposalType { Transfer, Call, Upgrade }
    enum ProposalState { Proposed, Approval, Queueing, Execution, Cancelled }

    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes data;
        ProposalType pType;
        ProposalState state;
        uint256 commitTime;
    }

    event ProposalProposed(uint256 indexed proposalId, address proposer, address target, uint256 value, bytes data, ProposalType pType);
    event ProposalApproved(uint256 indexed proposalId, address approver);
    event ProposalQueued(uint256 indexed proposalId, uint256 commitTime);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalGriefingDefended(uint256 indexed proposalId, address proposer, uint256 bondSlashed);
    event WithdrawalCapped(uint256 amountRequested, uint256 amountCapped);

    function MIN_PROPOSAL_BOND() external view returns (uint256);
    function propose(address target, uint256 value, bytes calldata data, ProposalType pType) external payable returns (uint256 proposalId);
    function approve(uint256 proposalId) external;
    function queue(uint256 proposalId) external;
    function execute(uint256 proposalId, address signer, uint256 deadline, bytes calldata signature) external;
    function cancel(uint256 proposalId) external;
}
