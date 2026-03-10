// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../Interfaces/ISignatureVerifier.sol";

abstract contract SignatureVerifier is ISignatureVerifier {

    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 public constant ACTION_TYPEHASH =
        keccak256(
            "TreasuryAction(address target,uint256 value,bytes data,uint256 nonce,uint256 deadline)"
        );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Treasury")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function verifySignature(
        address signer,
        address target,
        uint256 value,
        bytes memory data,
        uint256 deadline,
        bytes calldata signature
    ) internal {

        require(block.timestamp <= deadline, "Signature expired");

        uint256 nonce = nonces[signer];

        bytes32 structHash = keccak256(
            abi.encode(
                ACTION_TYPEHASH,
                target,
                value,
                keccak256(data),
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );

        address recovered = digest.recover(signature);

        require(recovered == signer, "Invalid signature");

        nonces[signer]++;
    }
}