# BlueBera Smart Contracts

A comprehensive DeFi ecosystem built on Berachain, featuring token distribution, linear vesting, and staking rewards.

## **SECURITY WARNING**

**NEVER commit private keys or sensitive configuration files to public repositories!**

- Always use test wallets for testnet deployments
- Use hardware wallets for mainnet deployments
- Keep your private keys secure and never share them

## Project Structure

```
beraroot/
├── contracts/                 # Smart contract source code
│   ├── BlueBeraToken.sol     # Main ERC20 token contract
│   ├── AirdropDistributor.sol # Token airdrop distribution
│   ├── LinearVesting.sol     # Linear vesting mechanism
│   └── StakingRewards.sol    # Staking rewards system
├── scripts/                   # Deployment and utility scripts
├── hardhat.config.js          # Mainnet configuration
├── hardhat.config.testnet.js  # Testnet configuration
└── README.md                  # This file
```

## Quick Start

### Prerequisites

- Node.js 16+ 
- npm or yarn
- Berachain testnet tokens (for testing)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd beraroot

# Install dependencies
npm install

# Create environment configuration
cp env.template .env  # Create from template
# Edit .env with your actual values
```

### Configuration

1. **Create environment file:**
   ```bash
   # Copy template and edit
   cp env.template .env
   ```

2. **Edit configuration:**
   - Replace `YOUR_PRIVATE_KEY_HERE` with your actual private key
   - Replace `YOUR_*_ADDRESS_HERE` with your actual addresses
   - Add your Etherscan API key for mainnet

3. **Verify configuration:**
   - Ensure `.env` file is in `.gitignore`
   - Never commit this file to public repositories

### Deployment

#### Testnet Deployment
```bash
npm run deploy:testnet
```
**Note**: Uses the same deployment script as mainnet but with testnet configuration

#### Mainnet Deployment
```bash
npm run deploy:mainnet
```

## Available Scripts

- `npm run deploy:testnet` - Deploy to Berachain Bepolia testnet
- `npm run deploy:mainnet` - Deploy to Berachain mainnet

## Security Features

- Role-based access control (RBAC)
- Pausable functionality
- Ownership management
- Secure deployment process with confirmation

## Networks

- **Testnet**: Berachain Bepolia (Chain ID: 80069)
- **Mainnet**: Berachain (Chain ID: 80094)

## Token Allocation

### Total Supply: 100,000,000 BLUEBERA

| Category | Percentage | Amount | Address |
|----------|------------|---------|---------|
| Presale | 30% | 30,000,000 | `0x63b1a2b72cb2cc619f909955088370b0c7cc9e02` |
| DEX Liquidity | 3% | 3,000,000 | `0xcb57817b88ba3b02456b73652418f6de79aa15b8` |
| Holder Airdrop | 5% | 5,000,000 | `0xc15dced1f1bf2b75b23054e3de10df690c11d259` |
| Community Airdrop | 3% | 3,000,000 | `0xfb6f3a02dfbc1885e39cbb49bcf4b0cc7b1079a7` |
| Team Incentives | 4% | 4,000,000 | `0x45e7de707ce28df6b1757f76ed1a7e5379ec1982` |
| Staking Incentives | 55% | 55,000,000 | `0xaebb2a6f394f18bac3924a46cd2005b1ac24a134` |

## Mainnet Deployment Status

### Contract Addresses (Chain ID: 80094)
- **BlueBeraToken**: `0xe1bE98C81A84FfE320f1C89Cf75e3047D11529C7`
- **AirdropDistributor**: `0x4b0DE94565F2b05a7D5b6a9c3599Ac2717f04b2e`
- **LinearVesting**: `0xE43992B7D9309652D16cc0462235f0A344BCC330`
- **StakingRewards**: `0x03555Cfb7747E07902AAD192dF7047E84C234013`

### Deployment Information
- **Deployer**: `0x4F6A3E14C57fB9A5851918373d8bAC1C1a3A7a9A`
- **Network**: Berachain Mainnet
- **Status**: All contracts deployed and verified
- **Initial Minting**: Completed (100,000,000 BLUEBERA)

## Contract Features

### BlueBeraToken
- Standard ERC20 token with no transfer tax
- Supports ERC20Permit (gasless approve)
- Minter role management for minting permissions
- Optional burn functionality

### AirdropDistributor
- Batch airdrop distributor
- Supports batch processing to avoid gas limits
- Can recover unused balances

### LinearVesting
- Linear token vesting release
- Supports cliff period settings
- Beneficiary self-claim mechanism

### StakingRewards
- Single token staking (Synthetix style)
- Stake BLUEBERA to earn BLUEBERA rewards
- Configurable reward periods

## Important Notes

1. **Private Keys**: Never commit private keys to public repositories
2. **Configuration**: Use template files as templates, keep actual configs private
3. **Testing**: Always test on testnet before mainnet deployment
4. **Security**: Use hardware wallets for mainnet deployments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure no sensitive data is included
5. Submit a pull request

## License

[Add your license here]