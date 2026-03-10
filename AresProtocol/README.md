# ARES Protocol

A modular, secure governance and reward distribution protocol.

## Protocol Lifecycle

The ARES Protocol follows a strict state machine to ensure safety and transparency:

1.  **Proposal Creation**: Any user can create a proposal by calling `propose()`. This requires a **0.1 ETH bond** and is subject to treasury withdrawal caps. The proposal starts in the `Proposed` state.
2.  **Approval**: The authorized `Owner` (Governance) reviews the proposal. After a mandatory **1-day voting delay**, the owner can call `approve()`, moving the proposal to the `Approval` state.
3.  **Queueing**: Once approved, the proposal must wait for a **1-hour timelock** period. After this, anyone can call `queue()` to move it to the `Queued` state.
4.  **Execution**: To finalize an action, a valid **EIP-712 signature** from the authorized protocol signer must be provided to the `execute()` function. Successful execution triggers the intended transaction and **refunds the 0.1 ETH bond** to the proposer.
5.  **Cancellation**: The `Owner` can call `cancel()` at any time before queueing if a proposal is deemed malicious or unnecessary. In this case, the **bond is slashed** (retained by the protocol) to discourage griefing.

## Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md): Detailed system design, module separation, and trust assumptions.
- [SECURITY.md](./SECURITY.md): Analysis of attack surfaces and mitigation strategies.

---

## Foundry

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
