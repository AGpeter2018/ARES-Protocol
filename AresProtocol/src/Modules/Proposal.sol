// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./DelayExecution.sol";
import "./SignatureVerifier.sol";
import "../Interfaces/IProposalSystem.sol";

contract ProposalSystem is IProposalSystem, DelayExecution, ReentrancyGuard, SignatureVerifier, Ownable {

    constructor() Ownable(msg.sender) {}

    uint256 public constant MIN_PROPOSAL_BOND = 0.1 ether;
    uint256 public constant MAX_WITHDRAWAL_PER_PROPOSAL = 10 ether;

    uint256 public constant VOTING_DELAY = 1 days;

    struct ProposalExtended {
        uint256 proposeTime;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => uint256) public proposalBonds;
    mapping(uint256 => ProposalExtended) public proposalsExtended;

    function propose(address target, uint256 value, bytes memory data, ProposalType pType) external payable returns (uint256 proposalId) {
        require(msg.value >= MIN_PROPOSAL_BOND, "Bond too low");
        require(value <= MAX_WITHDRAWAL_PER_PROPOSAL, "Withdrawal exceeds cap");

        proposalId = proposalCount++;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            pType: pType,
            state: ProposalState.Proposed,
            commitTime: 0
        });

        proposalBonds[proposalId] = msg.value;
        proposalsExtended[proposalId] = ProposalExtended({proposeTime: block.timestamp});

        emit ProposalProposed(proposalId, msg.sender, target, value, data, pType);
    }

    function approve(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Proposed, "Proposal not in proposed state");
        require(block.timestamp >= proposalsExtended[proposalId].proposeTime + VOTING_DELAY, "Voting delay not passed");

        proposal.state = ProposalState.Approval;

        proposal.commitTime = setExecutionTime(proposalId);

        emit ProposalApproved(proposalId, msg.sender);
    }

    function queue(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Approval, "Proposal not approved");
        require(block.timestamp >= proposal.commitTime, "Commit delay not passed");

        proposal.state = ProposalState.Queueing;
        emit ProposalQueued(proposalId, proposal.commitTime);
    }

    function execute(uint256 proposalId, address signer, uint256 deadline, bytes calldata signature) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Queueing, "Proposal not queueing");
        require(isReady(proposalId), "Timelock not passed");
        verifySignature(signer, proposal.target, proposal.value, proposal.data, deadline, signature);

        if (proposal.pType == ProposalType.Transfer) {
            if (proposal.value > 0) {
                (bool success, ) = payable(proposal.target).call{value: proposal.value}("");
                require(success, "ETH transfer failed");
            } else {
                (address token, address recipient, uint256 amount) = abi.decode(proposal.data, (address, address, uint256));
                IERC20(token).transfer(recipient, amount);
            }
        } else if (proposal.pType == ProposalType.Call) {
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
            require(success, "Call failed");
        } else if (proposal.pType == ProposalType.Upgrade) {
            address newImpl = abi.decode(proposal.data, (address));
            (bool success, ) = proposal.target.call(
                abi.encodeWithSignature("upgradeTo(address)", newImpl)
            );
            require(success, "Upgrade failed");
        }

        proposal.state = ProposalState.Execution;
        
        uint256 bond = proposalBonds[proposalId];
        if (bond > 0) {
            proposalBonds[proposalId] = 0;
            (bool success, ) = payable(proposal.proposer).call{value: bond}("");
            require(success, "Bond refund failed");
        }

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.state == ProposalState.Proposed || proposal.state == ProposalState.Approval,
            "Cannot cancel at this stage"
        );
        proposal.state = ProposalState.Cancelled;

        emit ProposalGriefingDefended(proposalId, proposal.proposer, proposalBonds[proposalId]);
        proposalBonds[proposalId] = 0;

        emit ProposalCancelled(proposalId);
    }

    receive() external payable {}
}