# Solana Wallet Manager

A comprehensive bash script for managing Solana wallets, addresses, tokens, and transactions in development environments.

## Features

- **Wallet Management**: Create, list, and select wallets
- **Address Management**: Store and manage recipient addresses
- **Transaction Support**: Transfer SOL and custom tokens between wallets
- **Token Operations**: Create SPL tokens, mint tokens, and manage token accounts
- **Cluster Management**: Switch between Solana clusters and check cluster availability
- **Developer Friendly**: Designed to work with `solana-test-validator` for local development

## Prerequisites

- Solana CLI tools (`solana`, `solana-keygen`, `spl-token`)
- Bash shell environment
- For local development: Docker with `solana-test-validator`

## Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/yourusername/solana-wallet-manager/main/solana-wallet-manager.sh
```

2. Make it executable:

```bash
chmod +x solana-wallet-manager.sh
```

3. (Optional) For easier access, you can move it to a directory in your PATH:

```bash
sudo mv solana-wallet-manager.sh /usr/local/bin/solana-wallet-manager
```

## Usage

### Setting Up a Local Validator

Start a local Solana validator in Docker:

```bash
docker run -ti \
  --name solana-test-validator \
  -p 8899:8899 \
  -p 8900:8900 \
  -p 8001:8001 \
  -v ~/dev:/working-dir:rw \
  --rm \
  tchambard/solana-test-validator:latest \
  solana-test-validator
```

### Basic Commands

```bash
# Get help
./solana-wallet-manager.sh help

# Set to local cluster
./solana-wallet-manager.sh set-cluster local

# Check if cluster is available
./solana-wallet-manager.sh check-cluster

# Create a wallet
./solana-wallet-manager.sh create-wallet wallet1

# List all wallets
./solana-wallet-manager.sh list-wallets

# Select a wallet
./solana-wallet-manager.sh use-wallet wallet1

# Check wallet balance
./solana-wallet-manager.sh show-balance

# Airdrop SOL to wallet (only works on test networks)
./solana-wallet-manager.sh airdrop 1 wallet1
```

### Managing Recipients

```bash
# Add an address as a named recipient
./solana-wallet-manager.sh add-recipient exchange 9xDUcfd3uKKFkZfcFYM7UpREf8dYUBZ3Rh6GQKJyzuZU

# List all saved recipients
./solana-wallet-manager.sh list-recipients
```

### Transferring SOL

```bash
# Transfer SOL to another wallet
./solana-wallet-manager.sh transfer 0.5 wallet2

# Transfer SOL to a saved recipient
./solana-wallet-manager.sh transfer 0.5 exchange

# Transfer SOL to a direct address
./solana-wallet-manager.sh transfer 0.5 9xDUcfd3uKKFkZfcFYM7UpREf8dYUBZ3Rh6GQKJyzuZU
```

### SPL Token Operations

```bash
# Create a new SPL token
./solana-wallet-manager.sh create-token "My Token" MTK 9

# Mint tokens to your wallet
./solana-wallet-manager.sh mint-token MTK 1000

# Transfer tokens to another wallet
./solana-wallet-manager.sh transfer-token MTK 500 wallet2

# List all tokens in wallet
./solana-wallet-manager.sh list-tokens
```

## Example Workflow

Here's a complete workflow for creating wallets, tokens, and transferring between them:

```bash
# Start your validator in another terminal
docker run -ti --name solana-test-validator -p 8899:8899 -p 8900:8900 -p 8001:8001 -v ~/dev:/working-dir:rw --rm tchambard/solana-test-validator:latest solana-test-validator

# Set local cluster
./solana-wallet-manager.sh set-cluster local

# Verify cluster is running
./solana-wallet-manager.sh check-cluster

# Create wallets
./solana-wallet-manager.sh create-wallet wallet1
./solana-wallet-manager.sh create-wallet wallet2

# Airdrop SOL to wallets
./solana-wallet-manager.sh airdrop 2 wallet1
./solana-wallet-manager.sh airdrop 1 wallet2

# Transfer SOL between wallets
./solana-wallet-manager.sh use-wallet wallet1
./solana-wallet-manager.sh transfer 0.5 wallet2

# Create a token
./solana-wallet-manager.sh create-token "Example Token" EXTKN 6

# Mint and transfer tokens
./solana-wallet-manager.sh mint-token EXTKN 1000
./solana-wallet-manager.sh transfer-token EXTKN 500 wallet2

# Add an external recipient
./solana-wallet-manager.sh add-recipient friend H9jwtuKnD63iRQBPXdYbGjekfwzAoqWBcJaqdgx1QcV4

# Transfer to external recipient
./solana-wallet-manager.sh transfer 0.1 friend
```

## File Structure

The script creates the following directory structure:

```
~/solana-wallets/              # Base directory for all wallets
├── current_wallet             # File storing the name of the currently selected wallet
├── recipients/                # Directory for stored recipient addresses
│   ├── exchange               # Example recipient
│   └── friend                 # Example recipient
├── wallet1/                   # Directory for wallet1
│   ├── keypair.json           # Wallet keypair
│   └── tokens/                # Directory for tokens created by this wallet
│       └── MTK.json           # Information about created token
└── wallet2/                   # Directory for wallet2
    └── keypair.json           # Wallet keypair
```

## Cluster Options

Available clusters:

- `local` - Local test validator (http://localhost:8899)
- `devnet` - Solana Devnet (https://api.devnet.solana.com)
- `testnet` - Solana Testnet (https://api.testnet.solana.com)
- `mainnet` - Solana Mainnet (https://api.mainnet-beta.solana.com)
- Any custom URL

## Notes

- This script is designed for development and testing purposes.
- For production use cases, consider proper key management and security practices.
- The script stores keypairs in plain JSON files. For production, use hardware wallets or more secure storage methods.

## Troubleshooting

### Common Issues

1. **"No wallet selected"** error:
   - Use `use-wallet <wallet-name>` to select a wallet before operations.

2. **Transfer fails**:
   - Ensure you have sufficient balance with `show-balance`.
   - Check that the recipient address is correct.
   - Verify the cluster is available with `check-cluster`.

3. **Airdrop fails**:
   - Airdrops only work on test networks and localnet.
   - There are rate limits on devnet/testnet airdrops.

4. **Token creation fails**:
   - Ensure you have sufficient SOL for the transaction fees.
   - Check that the cluster is available.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.