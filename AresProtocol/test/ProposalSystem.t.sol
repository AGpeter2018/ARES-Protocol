// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Modules/Proposal.sol";
import "../src/Interfaces/IProposalSystem.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ProposalSystemTest is Test {
    ProposalSystem public proposalSystem;
    address public owner;
    address public proposer;
    address public signer;
    address public target;
    uint256 public signerPrivKey = 0xabc123;

    function setUp() public {
        owner = vm.addr(101);
        proposer = vm.addr(102);
        signer = vm.addr(signerPrivKey);
        target = vm.addr(103);
        
        vm.prank(owner);
        proposalSystem = new ProposalSystem();
    }

    function test_Propose() public {
        vm.prank(proposer);
        vm.deal(proposer, 1 ether);
        uint256 id = proposalSystem.propose{value: 0.1 ether}(target, 1 ether, "", IProposalSystem.ProposalType.Transfer);
        
        (address _proposer,,,,,,) = proposalSystem.proposals(id);
        assertEq(_proposer, proposer);
        assertEq(proposalSystem.proposalBonds(id), 0.1 ether);
    }

    function test_ApproveOnlyOwnerWithDelay() public {
        vm.prank(proposer);
        vm.deal(proposer, 1 ether);
        uint256 id = proposalSystem.propose{value: 0.1 ether}(target, 1 ether, "", IProposalSystem.ProposalType.Transfer);

        vm.prank(owner);
        vm.expectRevert("Voting delay not passed");
        proposalSystem.approve(id);

        vm.warp(block.timestamp + 1 days);

        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, proposer));
        proposalSystem.approve(id);

        vm.prank(owner);
        proposalSystem.approve(id);
    }

    function test_TimelockAfterApprove() public {
        vm.prank(proposer);
        vm.deal(proposer, 1 ether);
        uint256 id = proposalSystem.propose{value: 0.1 ether}(target, 1 ether, "", IProposalSystem.ProposalType.Transfer);

        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        proposalSystem.approve(id);

        assertFalse(proposalSystem.isReady(id));

        vm.warp(block.timestamp + 1 hours);
        assertTrue(proposalSystem.isReady(id));
    }

    function test_WithdrawalCap() public {
        vm.prank(proposer);
        vm.deal(proposer, 1 ether);
        vm.expectRevert("Withdrawal exceeds cap");
        proposalSystem.propose{value: 0.1 ether}(target, 20 ether, "", IProposalSystem.ProposalType.Transfer);
    }

    function test_FullLifecycle() public {
        vm.deal(proposer, 1 ether);
        vm.prank(proposer);
        uint256 id = proposalSystem.propose{value: 0.1 ether}(target, 1 ether, "", IProposalSystem.ProposalType.Transfer);

        // 1. Voting Delay
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        proposalSystem.approve(id);

        // 2. Timelock
        vm.warp(block.timestamp + 1 hours);
        vm.prank(address(0x999)); // Anyone can queue
        proposalSystem.queue(id);

        // 3. Execution (Simulating simple transfer execution)
        vm.deal(address(proposalSystem), 1.1 ether); // 1.0 for transfer + 0.1 for bond
        
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                proposalSystem.ACTION_TYPEHASH(),
                target,
                1 ether,
                keccak256(bytes("")),
                proposalSystem.nonces(signer),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", proposalSystem.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 balanceBefore = target.balance;
        uint256 proposerBalanceBefore = proposer.balance;
        
        proposalSystem.execute(id, signer, deadline, signature);
        
        assertEq(target.balance, balanceBefore + 1 ether);
        assertEq(proposer.balance, proposerBalanceBefore + 0.1 ether);
    }

    receive() external payable {}
}
