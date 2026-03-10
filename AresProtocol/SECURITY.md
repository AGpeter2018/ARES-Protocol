# ARES Protocol: Security & Threat Model Specification

The ARES Protocol is designed with a "Security-First" philosophy, recognizing that decentralization and flexibility must come with robust, multi-layered defensive mechanisms. In the high-stakes environment of decentralized finance (DeFi) and protocol governance, security is not a single feature but the result of a comprehensive threat model that anticipates and mitigates both common and advanced attack vectors.

This document provides an in-depth analysis of the protocol's attack surfaces, the specific mitigation strategies implemented to protect user funds and governance integrity, and a transparent assessment of residual risks.

## 1. Major Attack Surfaces & Threat Analysis

ARES identifies several primary vectors through which a malicious actor might attempt to compromise the system. Each of these surfaces is guarded by specific technical and economic barriers.

### I. Governance Manipulation (The Flash-Loan Vector)
In many governance systems, the ability to propose and approve an action within a short timeframe creates a vulnerability to flash-loan attacks. An attacker could borrow a significant amount of voting power (if the system were token-based) or manipulate market conditions to influence an automated decision. Even in an admin-governed system, a compromise of the admin key combined with an instantaneous execution path would be catastrophic.
- **Threat**: Rapid proposal-to-execution window allowing for unobserved malicious changes.

### II. Treasury Drains (The Payout Vector)
The ultimate goal of many attacks is the unauthorized withdrawal of protocol assets. A malicious proposal might aim to transfer the entire treasury to an attacker-controlled address.
- **Threat**: Monolithic withdrawal proposals that bypass oversight or exploit a single point of failure in the authorization chain.

### III. Proposal Griefing (The Service Vector)
A persistent attacker might spam the `ProposalSystem` with a high volume of low-quality or invalid proposals. While this may not directly lead to a loss of funds, it results in "Governance Fatigue" and can clog the pipeline for legitimate protocol upgrades.
- **Threat**: Flooding the system with noise to hide malicious actions or exhaust the admin's attention.

### IV. Signature Replay & Forgery (The Cryptographic Vector)
If signatures are not properly "domain-bound," a signed authorize for one action could potentially be reused (replayed) for another, or a signature from a different network (e.g., a testnet) could be used on the mainnet.
- **Threat**: Cross-chain or cross-contract replay of authorized actions.

### V. Double Claiming (The Distribution Vector)
In the `MerkleDistributor`, the primary risk is that a participant might attempt to claim their reward multiple times using the same valid proof.
- **Threat**: Exploiting the stateless nature of Merkle proofs to drain the distribution pool.

## 2. Multi-Layered Mitigation Strategies

ARES employs a "Defense in Depth" strategy, ensuring that the failure of any single component does not lead to a total system compromise.

### I. Temporal Defense: The Observability Window
Governance safety in ARES is rooted in **Time**. We have implemented two distinct temporal hurdles:
- **Mandatory Voting Delay (1 Day)**: Once a proposal is created, it is locked in the `Proposed` state for exactly 24 hours. During this time, the `approve()` function will revert. This mandatory delay ensures that even if an attacker manages to propose a malicious action, it is visible to all observers for a full day before it can even be considered for approval.
- **Queue & Timelock (1 Hour)**: After approval, the proposal is not executed immediately. Instead, it must be `queued()`, which initiates a secondary 1-hour timelock. This "Execution Delay" provides a final window for the community or a secondary security layer to cancel the proposal or pause the system if the approval itself was found to be malicious.

### II. Economic Barriers: Bonding and Slashing
ARES mitigates griefing and low-signal proposals by requiring "Skin in the Game."
- **Proposal Bond**: Creating a proposal requires a mandatory **0.1 ETH deposit**. This bond is held in escrow by the contract.
- **Admin Slashing**: If the governance body (the `Owner`) determines a proposal is malicious or a griefing attempt, they can `cancel()` it. Upon cancellation, the bond is **slashed** and moved to the protocol's treasury. Legitimate proposals only receive their bond back upon successful `execute()`. This creates a direct financial cost for attacking the governance pipeline.

### III. Capital Risk Management: Withdrawal Caps
To mitigate the impact of a compromised governance process, ARES implements **Treasury Withdrawal Caps**.
- **Max Total Value**: No single proposal can authorize a withdrawal exceeding **10 ETH**. This hard cap ensures that the "blast radius" of any individual proposal is limited. Even if an attacker compromises the admin and the signer, they cannot drain more than the cap in a single 25-hour cycle.

### IV. Cryptographic Rigor: EIP-712 & Nonces
ARES implements high-assurance signature verification using the EIP-712 standard:
- **Domain Separation**: Every execution requires a signature bound to a unique `DOMAIN_SEPARATOR`. This includes the contract's address, the chain ID, and a protocol-specific name. This makes it impossible to reuse a signature across different contracts or networks.
- **Action Typehashing**: The data itself is hashed using a structured `ACTION_TYPEHASH`, ensuring that the signer is explicitly authorizing a specific target, value, and data payload.
- **On-chain Nonces**: Each signer must use a monotonically increasing nonce. Reusing a signature results in a revert, preventing any form of replay attack.

### V. Non-Repudiation in Rewards: Bit-Packed Bitmaps
The `MerkleDistributor` uses a highly gas-efficient **Packed Bitmap** to track claims. By checking and setting bits in a `uint256` array, the system ensures that once a Merkle index is claimed, it is permanently marked in the contract state. The bitwise logic is robust and avoids the pitfalls of more complex state-tracking mechanisms.

## 3. Residual Risks & Operational Security

Despite these robust defenses, certain risks are inherent to any blockchain protocol.

- **Admin Centralization**: The `Owner` currently has the power to approve proposals (subject to the 1-day delay). If the `Owner`'s private key is compromised, an attacker can push through a malicious proposal. We mitigate this by requiring a secondary **Signer** for the final execution, creating a 2-of-2 requirement for any actual payout or upgrade.
- **Signer Availability**: The protocol requires an authorized off-chain signer to finalize executions. If the signer's key is lost or the off-chain signing infrastructure fails, the governance process will stall at the `Queued` state.
- **Human Error in Merkle Roots**: While the `MerkleDistributor` is technically secure, it trusts the Merkle root set by Governance. If an incorrect root is approved, it could lead to incorrect distributions. This is why root updates are subject to the same strict proposal-and-approval lifecycle as treasury withdrawals.
- **Emerging EVM Vulnerabilities**: As with all smart contracts, ARES is subject to the security of the underlying EVM and the Solidity compiler. We utilize the latest stable versions (0.8.20+) and avoid unsafe low-level patterns wherever possible.

By combining temporal delays, economic bonds, capital caps, and strict cryptographic verification, the ARES Protocol provides a resilient and secure framework for the future of decentralized coordination.
