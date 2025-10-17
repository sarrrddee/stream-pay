# StreamPay Smart Contract

A decentralized payment streaming protocol built on Stacks blockchain that enables continuous, time-based STX token payments.

## Overview

StreamPay allows users to create payment streams where funds are continuously streamed from a sender to a recipient over a specified duration. The recipient can withdraw the accrued funds at any time.

## Features

- 🌊 **Continuous Streaming**: Real-time token streaming based on block height
- 🔒 **Secure**: Built-in authorization checks and state management
- ⚡ **Efficient**: Optimized calculations for token distribution
- 🔄 **Flexible Withdrawals**: Recipients can withdraw accrued funds anytime

## Functions

### Core Functions

- `create-stream`: Create a new payment stream
- `withdraw`: Withdraw available funds from a stream
- `get-stream`: Get stream details

### Error Codes

```clarity
err-not-found (404)     // Stream not found
err-unauthorized (401)   // Unauthorized access
err-insufficient (402)   // Insufficient funds/invalid amount
err-stream-ended (403)   // Stream has ended
```

## Usage Example

```clarity
;; Create a stream
(contract-call? .stream-pay create-stream 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; recipient
    u1000000                                      ;; amount (in uSTX)
    u144)                                         ;; duration (in blocks)

;; Withdraw from stream
(contract-call? .stream-pay withdraw u1)          ;; stream ID
```

## Installation

1. Clone the repository
2. Deploy using Clarinet or your preferred Stacks deployment tool

## Testing

Run the test suite using Clarinet:

```bash
clarinet test
```

Built with ❤️ for the Stacks ecosystem
