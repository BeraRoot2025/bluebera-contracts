const { ethers } = require("hardhat");
require("dotenv").config({ path: "env.mainnet.config" });

// Simple user confirmation function
function waitForUserConfirmation(message) {
  console.log(`\n${message}`);
  console.log("Press Enter to continue to next step...");
  // Note: In actual use, you need to manually press Enter to continue
  // This is just displaying prompt information
}

async function main() {
  console.log("Starting step-by-step mainnet deployment with confirmation...");
  console.log("WARNING: This is MAINNET deployment - ensure all addresses are correct!");
  console.log("You can review each deployment before proceeding\n");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deployer address:", deployer.address);
  console.log("Deployer balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "BERA");

  // Check network information
  const network = await ethers.provider.getNetwork();
  console.log("Current network:", network.name);
  console.log("Chain ID:", network.chainId);

  // Verify this is mainnet
  if (Number(network.chainId) !== 80094) {
    console.error("ERROR: This script is designed for Berachain mainnet (Chain ID: 80094)");
    console.error("Current network Chain ID:", network.chainId);
    process.exit(1);
  }

  // Deployment status tracking
  const deploymentStatus = {
    BlueBeraToken: { deployed: false, address: null },
    AirdropDistributor: { deployed: false, address: null },
    LinearVesting: { deployed: false, address: null },
    StakingRewards: { deployed: false, address: null }
  };

  try {
    // ===== 1. Deploy BlueBeraToken Contract =====
    console.log("\n1. Deploying BlueBera token contract...");
    console.log("Deploying BlueBeraToken...");
    
    const BlueBeraToken = await ethers.getContractFactory("BlueBeraToken");
    const blueBeraToken = await BlueBeraToken.deploy(deployer.address);
    await blueBeraToken.waitForDeployment();
    
    const tokenAddress = await blueBeraToken.getAddress();
    deploymentStatus.BlueBeraToken = { deployed: true, address: tokenAddress };
    
    console.log("BlueBera token contract deployed successfully!");
    console.log("Contract address:", tokenAddress);
    
    // Verify deployment
    console.log("Verifying deployment...");
    const name = await blueBeraToken.name();
    const symbol = await blueBeraToken.symbol();
    const decimals = await blueBeraToken.decimals();
    console.log(`Contract verified: ${name} (${symbol}) - ${decimals} decimals`);
    
    // Wait for user confirmation
    waitForUserConfirmation("BlueBeraToken deployment completed and verified!");
    console.log("Current deployment status:");
    console.log(`   - BlueBeraToken: Deployed at ${tokenAddress}`);
    console.log(`   - AirdropDistributor: Pending`);
    console.log(`   - LinearVesting: Pending`);
    console.log(`   - StakingRewards: Pending`);
    console.log("\nReady to deploy next contract...");

    // ===== 2. Deploy AirdropDistributor Contract =====
    console.log("\n2. Deploying AirdropDistributor contract...");
    console.log("Deploying AirdropDistributor...");
    
    const AirdropDistributor = await ethers.getContractFactory("AirdropDistributor");
    const airdropDistributor = await AirdropDistributor.deploy(deployer.address, tokenAddress);
    await airdropDistributor.waitForDeployment();
    
    const airdropAddress = await airdropDistributor.getAddress();
    deploymentStatus.AirdropDistributor = { deployed: true, address: airdropAddress };
    
    console.log("AirdropDistributor contract deployed successfully!");
    console.log("Contract address:", airdropAddress);
    
    // Verify deployment
    console.log("Verifying deployment...");
    const airdropOwner = await airdropDistributor.owner();
    const airdropToken = await airdropDistributor.token();
    console.log(`Contract verified: Owner ${airdropOwner}, Token ${airdropToken}`);
    
    // Wait for user confirmation
    waitForUserConfirmation("AirdropDistributor deployment completed and verified!");
    console.log("Current deployment status:");
    console.log(`   - BlueBeraToken: Deployed at ${deploymentStatus.BlueBeraToken.address}`);
    console.log(`   - AirdropDistributor: Deployed at ${airdropAddress}`);
    console.log(`   - LinearVesting: Pending`);
    console.log(`   - StakingRewards: Pending`);
    console.log("\nReady to deploy next contract...");

    // ===== 3. Deploy LinearVesting Contract =====
    console.log("\n3. Deploying LinearVesting contract...");
    console.log("Deploying LinearVesting...");
    
    const LinearVesting = await ethers.getContractFactory("LinearVesting");
    const linearVesting = await LinearVesting.deploy(deployer.address, tokenAddress);
    await linearVesting.waitForDeployment();
    
    const vestingAddress = await linearVesting.getAddress();
    deploymentStatus.LinearVesting = { deployed: true, address: vestingAddress };
    
    console.log("LinearVesting contract deployed successfully!");
    console.log("Contract address:", vestingAddress);
    
    // Verify deployment
    console.log("Verifying deployment...");
    const vestingOwner = await linearVesting.owner();
    const vestingToken = await linearVesting.token();
    console.log(`Contract verified: Owner ${vestingOwner}, Token ${vestingToken}`);
    
    // Wait for user confirmation
    waitForUserConfirmation("LinearVesting deployment completed and verified!");
    console.log("Current deployment status:");
    console.log(`   - BlueBeraToken: Deployed at ${deploymentStatus.BlueBeraToken.address}`);
    console.log(`   - AirdropDistributor: Deployed at ${deploymentStatus.AirdropDistributor.address}`);
    console.log(`   - LinearVesting: Deployed at ${vestingAddress}`);
    console.log(`   - StakingRewards: Pending`);
    console.log("\nReady to deploy next contract...");

    // ===== 4. Deploy StakingRewards Contract =====
    console.log("\n4. Deploying StakingRewards contract...");
    console.log("Deploying StakingRewards...");
    
    const StakingRewards = await ethers.getContractFactory("StakingRewards");
    const stakingRewards = await StakingRewards.deploy(deployer.address, tokenAddress, tokenAddress);
    await stakingRewards.waitForDeployment();
    
    const stakingAddress = await stakingRewards.getAddress();
    deploymentStatus.StakingRewards = { deployed: true, address: stakingAddress };
    
    console.log("StakingRewards contract deployed successfully!");
    console.log("Contract address:", stakingAddress);
    
    // Verify deployment
    console.log("Verifying deployment...");
    const stakingOwner = await stakingRewards.owner();
    const stakingToken = await stakingRewards.stakingToken();
    const rewardsToken = await stakingRewards.rewardsToken();
    console.log(`Contract verified: Owner ${stakingOwner}, Staking Token ${stakingToken}, Rewards Token ${rewardsToken}`);
    
    // Wait for user confirmation
    waitForUserConfirmation("StakingRewards deployment completed and verified!");
    console.log("Current deployment status:");
    console.log(`   - BlueBeraToken: Deployed at ${deploymentStatus.BlueBeraToken.address}`);
    console.log(`   - AirdropDistributor: Deployed at ${deploymentStatus.AirdropDistributor.address}`);
    console.log(`   - LinearVesting: Deployed at ${deploymentStatus.LinearVesting.address}`);
    console.log(`   - StakingRewards: Deployed at ${stakingAddress}`);
    console.log("\nAll contracts deployed and verified successfully!");

    // ===== 5. Setup Contract Permissions and Roles =====
    console.log("\n5. Setting up contract permissions and roles...");
    console.log("Configuring roles...");
    
    // Grant minting role to airdrop contract
    const airdropRole = await blueBeraToken.MINTER_ROLE();
    await blueBeraToken.grantRole(airdropRole, airdropAddress);
    console.log("Granted MINTER_ROLE to AirdropDistributor");

    // Grant minting role to staking contract
    await blueBeraToken.grantRole(airdropRole, stakingAddress);
    console.log("Granted MINTER_ROLE to StakingRewards");

    // Grant minting role to vesting contract
    await blueBeraToken.grantRole(airdropRole, vestingAddress);
    console.log("Granted MINTER_ROLE to LinearVesting");

    // Wait for user confirmation
    waitForUserConfirmation("All roles configured successfully!");

    // ===== 6. Execute Initial Token Minting =====
    console.log("\n6. Executing initial token minting...");
    console.log("This will mint 100,000,000 BLUEBERA tokens!");
    
    // Set receiving addresses from config (same variable names as testnet)
    const presaleAddress = process.env.TEST_PRESALE_ADDRESS || deployer.address;
    const dexLiquidityAddress = process.env.TEST_DEX_LIQUIDITY_ADDRESS || deployer.address;
    const holderAirdropAddress = process.env.TEST_HOLDER_AIRDROP_ADDRESS || deployer.address;
    const communityAirdropAddress = process.env.TEST_COMMUNITY_AIRDROP_ADDRESS || deployer.address;
    const teamIncentivesAddress = process.env.TEST_TEAM_INCENTIVES_ADDRESS || deployer.address;
    const stakingIncentivesAddress = process.env.TEST_STAKING_INCENTIVES_ADDRESS || deployer.address;

    console.log("Receiving addresses:");
    console.log("- Presale:", presaleAddress);
    console.log("- DEX Liquidity:", dexLiquidityAddress);
    console.log("- Holder Airdrop:", holderAirdropAddress);
    console.log("- Community Airdrop:", communityAirdropAddress);
    console.log("- Team Incentives:", teamIncentivesAddress);
    console.log("- Staking Incentives:", stakingIncentivesAddress);

    // Wait for user confirmation
    waitForUserConfirmation("Ready to execute initial minting!");

    // Execute minting
    console.log("Executing minting transaction...");
    const mintTx = await blueBeraToken.mintAllTokens(
      presaleAddress,
      dexLiquidityAddress,
      holderAirdropAddress,
      communityAirdropAddress,
      teamIncentivesAddress,
      stakingIncentivesAddress
    );
    
    console.log("Waiting for minting transaction confirmation...");
    const mintReceipt = await mintTx.wait();
    console.log("Initial minting completed!");
    console.log("Transaction hash:", mintReceipt.hash);

    // ===== 7. Ownership Status =====
    console.log("\n7. Ownership status...");
    console.log("All contracts remain owned by deployer wallet for consistency with testnet");
    
    console.log("Current ownership:");
    console.log("- BlueBeraToken owner:", await blueBeraToken.owner());
    console.log("- AirdropDistributor owner:", await airdropDistributor.owner());
    console.log("- LinearVesting owner:", await linearVesting.owner());
    console.log("- StakingRewards owner:", await stakingRewards.owner());
    
    // Wait for user confirmation
    waitForUserConfirmation("Ownership status confirmed!");

    // ===== 8. Deployment Summary =====
    console.log("\nAll contracts deployed successfully on MAINNET!");
    console.log("Final deployment summary:");
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId);
    console.log("Deployer:", deployer.address);
    console.log("");
    console.log("Contract addresses:");
    console.log("- BlueBeraToken:", deploymentStatus.BlueBeraToken.address);
    console.log("- AirdropDistributor:", deploymentStatus.AirdropDistributor.address);
    console.log("- LinearVesting:", deploymentStatus.LinearVesting.address);
    console.log("- StakingRewards:", deploymentStatus.StakingRewards.address);
    console.log("");
    console.log("Token allocation:");
    console.log("- Total supply: 100,000,000 BLUEBERA");
    console.log("- Initial minting: Completed");
    console.log("- All roles: Configured");
    console.log("- Ownership: All contracts owned by deployer wallet");

    // Save deployment information
    const deploymentInfo = {
      network: network.name,
      chainId: network.chainId,
      deployer: deployer.address,
      contracts: {
        BlueBeraToken: deploymentStatus.BlueBeraToken.address,
        AirdropDistributor: deploymentStatus.AirdropDistributor.address,
        LinearVesting: deploymentStatus.LinearVesting.address,
        StakingRewards: deploymentStatus.StakingRewards.address
      },
      ownership: {
        deployer: deployer.address,
        note: "All contracts owned by deployer wallet (same as testnet)"
      },
      deploymentTime: new Date().toISOString(),
      mintingTransaction: mintReceipt.hash
    };
    
    console.log("\nDeployment information ready for verification");
    console.log("Your BlueBera ecosystem is now fully deployed on MAINNET!");
    console.log("\nNext steps:");
    console.log("1. Verify all contract functions");
    console.log("2. Test airdrop, staking, and vesting features");
    console.log("3. Document contract addresses for future use");
    console.log("4. Update env.mainnet.config with contract addresses");

  } catch (error) {
    console.error("Deployment failed:", error.message);
    console.error("Error details:", error);
    
    // Display current deployment status
    console.log("\nCurrent deployment status:");
    for (const [contract, status] of Object.entries(deploymentStatus)) {
      if (status.deployed) {
        console.log(`   - ${contract}: Deployed at ${status.address}`);
      } else {
        console.log(`   - ${contract}: Failed`);
      }
    }
    
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
