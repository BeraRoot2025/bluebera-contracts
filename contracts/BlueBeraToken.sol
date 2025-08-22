// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title BlueBera Token - Main Token Contract
 * @author BlueBera Team
 * @notice This is the main token contract for the BlueBera ecosystem with complete ERC20 functionality
 * 
 * @dev Contract Features:
 * - Standard ERC20 token implementation, no transfer fees, no transfer hooks
 * - ERC20Permit (EIP-2612) support for gasless approval operations
 * - Dual permission management: Ownable + AccessControl system
 * - Burnable tokens: Users can actively burn their own tokens
 * - Mintable tokens: Owner or authorized Minter role can mint new tokens
 * 
 * Security Considerations:
 * - Owner has highest permissions, recommended to transfer to multi-sig wallet after deployment
 * - Minter role managed by Owner, can grant/revoke minting permissions
 * - All critical operations have event logging for monitoring
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract BlueBeraToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, AccessControl {
    
    // ============================================================================
    // Constants Definition
    // ============================================================================
    
    /**
     * @notice Minter role identifier
     * @dev This role allows holders to mint new tokens, managed by Owner
     * Uses keccak256 hash to ensure uniqueness of role identifiers
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Total token supply (100,000,000 tokens)
     * @dev Fixed total supply based on allocation table
     */
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens with 18 decimals

    // ============================================================================
    // Token Allocation Ratio Constants (Based on Allocation Table)
    // ============================================================================
    
    /**
     * @notice Presale allocation ratio - 30%
     * @dev Fixed price $0.02, one-time release
     */
    uint256 public constant PRESALE_RATIO = 30; // 30%
    
    /**
     * @notice Initial DEX liquidity allocation ratio - 3%
     * @dev Paired with $BERA, partially locked LP
     */
    uint256 public constant DEX_LIQUIDITY_RATIO = 3; // 3%
    
    /**
     * @notice Holder airdrop allocation ratio - 5%
     * @dev Airdrop for NFT users
     */
    uint256 public constant HOLDER_AIRDROP_RATIO = 5; // 5%
    
    /**
     * @notice Community + ecosystem airdrop allocation ratio - 3%
     * @dev Galxe/Zealy tasks, partnership campaigns
     */
    uint256 public constant COMMUNITY_AIRDROP_RATIO = 3; // 3%
    
    /**
     * @notice Team incentives allocation ratio - 4%
     * @dev 12-month linear release (one-time mint in contract, actual release controlled by external contracts)
     */
    uint256 public constant TEAM_INCENTIVES_RATIO = 4; // 4%
    
    /**
     * @notice Staking incentives allocation ratio - 55%
     * @dev For staking and long-term protocol incentives
     */
    uint256 public constant STAKING_INCENTIVES_RATIO = 55; // 55%

    // ============================================================================
    // Event Definitions
    // ============================================================================

    /**
     * @notice Emitted when a new minter is added
     * @param account Address granted minting permissions
     */
    event MinterAdded(address indexed account);

    /**
     * @notice Emitted when minter permissions are revoked
     * @param account Address whose minting permissions were revoked
     */
    event MinterRemoved(address indexed account);

    /**
     * @notice Emitted when tokens are minted
     * @param to Address receiving the newly minted tokens
     * @param amount Amount of tokens minted
     */
    event Minted(address indexed to, uint256 amount);

    /**
     * @notice Emitted when all tokens are minted at once according to allocation ratios
     * @param presaleAddress Presale receiving address
     * @param dexLiquidityAddress DEX liquidity receiving address
     * @param holderAirdropAddress Holder airdrop receiving address
     * @param communityAirdropAddress Community airdrop receiving address
     * @param teamIncentivesAddress Team incentives receiving address
     * @param stakingIncentivesAddress Staking incentives receiving address
     */
    event AllTokensMinted(
        address indexed presaleAddress,
        address indexed dexLiquidityAddress,
        address indexed holderAirdropAddress,
        address communityAirdropAddress,
        address teamIncentivesAddress,
        address stakingIncentivesAddress
    );

    // ============================================================================
    // Constructor
    // ============================================================================

    /**
     * @notice Initialize BlueBera token contract
     * @dev Set token basic information and permission management during deployment
     * 
     * @param owner_ Initial owner address of the contract
     *               - Recommended to be deployer address, should transfer to multi-sig wallet after deployment
     *               - Has highest permissions: add/remove minters, transfer ownership, etc.
     *               - After deployment, need to call mintAllTokens to mint all tokens at once
     */
    constructor(
        address owner_
    )
        ERC20("BlueBera", "BLUEBERA")  // Token name and symbol
        ERC20Permit("BlueBera")        // EIP-2612 Permit functionality
        Ownable(owner_)                // Set contract owner
    {
        // Set access control permissions
        // Owner has both default admin role and minter role
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);  // Can manage all roles
        _grantRole(MINTER_ROLE, owner_);         // Can mint tokens
        
        // Note: After deployment, need to call mintAllTokens to mint all tokens at once
    }


    function addMinter(address account) external onlyOwner {
        _grantRole(MINTER_ROLE, account);
        emit MinterAdded(account);
    }


    function removeMinter(address account) external onlyOwner {
        _revokeRole(MINTER_ROLE, account);
        emit MinterRemoved(account);
    }

    function mintAllTokens(
        address presaleAddress,
        address dexLiquidityAddress,
        address holderAirdropAddress,
        address communityAirdropAddress,
        address teamIncentivesAddress,
        address stakingIncentivesAddress
    ) external onlyOwner {
 
        require(totalSupply() == 0, "Tokens already minted");
    
        require(presaleAddress != address(0), "Presale address cannot be zero");
        require(dexLiquidityAddress != address(0), "DEX liquidity address cannot be zero");
        require(holderAirdropAddress != address(0), "Holder airdrop address cannot be zero");
        require(communityAirdropAddress != address(0), "Community airdrop address cannot be zero");
        require(teamIncentivesAddress != address(0), "Team incentives address cannot be zero");
        require(stakingIncentivesAddress != address(0), "Staking incentives address cannot be zero");

        uint256 presaleAmount = (TOTAL_SUPPLY * PRESALE_RATIO) / 100;
        uint256 dexLiquidityAmount = (TOTAL_SUPPLY * DEX_LIQUIDITY_RATIO) / 100;
        uint256 holderAirdropAmount = (TOTAL_SUPPLY * HOLDER_AIRDROP_RATIO) / 100;
        uint256 communityAirdropAmount = (TOTAL_SUPPLY * COMMUNITY_AIRDROP_RATIO) / 100;
        uint256 teamIncentivesAmount = (TOTAL_SUPPLY * TEAM_INCENTIVES_RATIO) / 100;
        uint256 stakingIncentivesAmount = (TOTAL_SUPPLY * STAKING_INCENTIVES_RATIO) / 100;

        _mint(presaleAddress, presaleAmount);
        _mint(dexLiquidityAddress, dexLiquidityAmount);
        _mint(holderAirdropAddress, holderAirdropAmount);
        _mint(communityAirdropAddress, communityAirdropAmount);
        _mint(teamIncentivesAddress, teamIncentivesAmount);
        _mint(stakingIncentivesAddress, stakingIncentivesAmount);

    
        require(totalSupply() == TOTAL_SUPPLY, "Total supply mismatch");

        emit Minted(presaleAddress, presaleAmount);
        emit Minted(dexLiquidityAddress, dexLiquidityAmount);
        emit Minted(holderAirdropAddress, holderAirdropAmount);
        emit Minted(communityAirdropAddress, communityAirdropAmount);
        emit Minted(teamIncentivesAddress, teamIncentivesAmount);
        emit Minted(stakingIncentivesAddress, stakingIncentivesAmount);
        
        emit AllTokensMinted(
            presaleAddress,
            dexLiquidityAddress,
            holderAirdropAddress,
            communityAirdropAddress,
            teamIncentivesAddress,
            stakingIncentivesAddress
        );
    }

    function mint(address to, uint256 amount) external {
 
        if (msg.sender != owner() && !hasRole(MINTER_ROLE, msg.sender)) {
            revert("Not authorized to mint");
        }
        _mint(to, amount);
        emit Minted(to, amount);
    }


    function getTokenAllocation() external pure returns (
        uint256 presaleAmount,
        uint256 dexLiquidityAmount,
        uint256 holderAirdropAmount,
        uint256 communityAirdropAmount,
        uint256 teamIncentivesAmount,
        uint256 stakingIncentivesAmount
    ) {
        presaleAmount = (TOTAL_SUPPLY * PRESALE_RATIO) / 100;
        dexLiquidityAmount = (TOTAL_SUPPLY * DEX_LIQUIDITY_RATIO) / 100;
        holderAirdropAmount = (TOTAL_SUPPLY * HOLDER_AIRDROP_RATIO) / 100;
        communityAirdropAmount = (TOTAL_SUPPLY * COMMUNITY_AIRDROP_RATIO) / 100;
        teamIncentivesAmount = (TOTAL_SUPPLY * TEAM_INCENTIVES_RATIO) / 100;
        stakingIncentivesAmount = (TOTAL_SUPPLY * STAKING_INCENTIVES_RATIO) / 100;
    }


    function isInitialMintingComplete() external view returns (bool) {
        return totalSupply() > 0;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/**
 * ============================================================================
 * Usage Guide and Best Practices
 * ============================================================================
 * 
 * 1. Deployment Process:
 *    - Only need to set Owner address during deployment
 *    - Transfer ownership to multi-sig wallet immediately after deployment
 *    - Call mintAllTokens to mint all tokens at once
 * 
 * 2. Token Allocation (Based on Allocation Table):
 *    - Presale: 30% (30,000,000 tokens) - One-time release
 *    - Initial DEX Liquidity: 3% (3,000,000 tokens) - Paired with $BERA
 *    - Holder Airdrop: 5% (5,000,000 tokens) - For NFT users
 *    - Community + Ecosystem Airdrop: 3% (3,000,000 tokens) - Galxe/Zealy tasks
 *    - Team Incentives: 4% (4,000,000 tokens) - 12-month linear release (controlled by external contracts)
 *    - Staking Incentives: 55% (55,000,000 tokens) - Long-term protocol incentives
 * 
 * 3. Permission Management:
 *    - Owner: Has highest permissions, can manage all roles
 *    - MINTER_ROLE: Can only mint tokens, no other permissions
 *    - Recommended to use multi-sig wallet as Owner
 * 
 * 4. One-time Minting Features:
 *    - mintAllTokens can only be called once, ensuring fixed total supply
 *    - All tokens automatically allocated to specified addresses according to ratios
 *    - Supports additional minting through mint function if needed
 * 
 * 5. Security Considerations:
 *    - Transfer ownership to multi-sig wallet immediately after deployment
 *    - Carefully manage MINTER_ROLE permissions
 *    - Monitor large minting operations
 *    - Regularly audit minter list
 * 
 * 6. Integration with Other Contracts:
 *    - Supports standard ERC20 interface
 *    - Supports Permit functionality (gasless approval)
 *    - Supports token burning functionality
 *    - Provides allocation information query interface
 * 
 * 7. Event Monitoring:
 *    - AllTokensMinted: One-time minting completion event
 *    - MinterAdded/MinterRemoved: Permission changes
 *    - Minted: Token minting records
 *    - Transfer/Approval: Standard ERC20 events
 * 
 * 8. Query Functions:
 *    - getTokenAllocation(): Get token amounts for each allocation
 *    - isInitialMintingComplete(): Check if initial minting is complete
 *    - totalSupply(): Current total supply
 */
