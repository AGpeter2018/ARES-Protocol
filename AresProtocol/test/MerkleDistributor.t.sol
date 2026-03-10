// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Modules/MerkleDistributor.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {
        _mint(msg.sender, 1000000 ether);
    }
}

contract MerkleDistributorTest is Test {
    MerkleDistributor public distributor;
    MockToken public token;
    
    bytes32 public root;
    bytes32[] public proof;

    uint256 index = 0;
    address account = address(0x1);
    uint256 amount = 100;

    function setUp() public {
        token = new MockToken();
        
        // Compute leaf 0
        bytes32 leaf0 = keccak256(abi.encodePacked(uint256(0), address(0x1), uint256(100)));
        // Compute leaf 1 (dummy)
        bytes32 leaf1 = keccak256(abi.encodePacked(uint256(1), address(0x2), uint256(200)));
        
        // Compute root: MerkleProof in OZ sorts leaves
        if (leaf0 < leaf1) {
            root = keccak256(abi.encodePacked(leaf0, leaf1));
        } else {
            root = keccak256(abi.encodePacked(leaf1, leaf0));
        }
        
        proof = new bytes32[](1);
        proof[0] = leaf1;

        distributor = new MerkleDistributor(address(token), root);
        token.transfer(address(distributor), 1000 ether);
    }

    function test_Claim() public {
        assertFalse(distributor.isClaimed(index));
        distributor.claim(index, account, amount, proof);
        assertTrue(distributor.isClaimed(index));
        assertEq(token.balanceOf(account), amount);
    }

    function test_DoubleClaimFails() public {
        distributor.claim(index, account, amount, proof);
        
        vm.expectRevert("MerkleDistributor: Drop already claimed.");
        distributor.claim(index, account, amount, proof);
    }

    function test_InvalidProofFails() public {
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = keccak256(abi.encodePacked("wrong"));

        vm.expectRevert("MerkleDistributor: Invalid proof.");
        distributor.claim(index, account, amount, invalidProof);
    }
}
