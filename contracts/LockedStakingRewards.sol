// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LockedStakingRewards is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    uint256 public constant LOCK_PERIOD = 90 days;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public constant REWARDS_DURATION = 90 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    struct StakeInfo {
        uint256 amount;
        uint256 lockEndTime;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
        bool exists;
        uint256 stakeId; // New: Stake ID
    }

    struct UserStakes {
        StakeInfo[] stakes;
        uint256 totalStaked;
        uint256 totalRewards;
    }

    mapping(address => UserStakes) public userStakes;
    mapping(address => mapping(uint256 => uint256)) public userStakeIndex; // User stake ID to array index mapping
    
    uint256 private _totalSupply;
    uint256 private _nextStakeId = 1; // Global stake ID counter

    event Staked(address indexed user, uint256 stakeId, uint256 amount, uint256 lockEndTime);
    event Withdrawn(address indexed user, uint256 stakeId, uint256 amount);
    event RewardPaid(address indexed user, uint256 stakeId, uint256 reward);
    event RewardAdded(uint256 reward);

    constructor(
        address owner_, 
        IERC20 _stakingToken, 
        IERC20 _rewardsToken
    ) Ownable(owner_) {
        require(owner_ != address(0), "Owner cannot be zero address");
        require(address(_stakingToken) != address(0), "Staking token cannot be zero address");
        require(address(_rewardsToken) != address(0), "Rewards token cannot be zero address");
        
        stakingToken = _stakingToken;
        rewardsToken = _rewardsToken;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _updateUserRewards(account);
        }
        _;
    }

    function _updateUserRewards(address account) internal {
        UserStakes storage userStake = userStakes[account];
        for (uint256 i = 0; i < userStake.stakes.length; i++) {
            if (userStake.stakes[i].exists) {
                userStake.stakes[i].rewards = earned(account, i);
                userStake.stakes[i].rewardPerTokenPaid = rewardPerTokenStored;
            }
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) return rewardPerTokenStored;
        
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        if (timeDelta == 0) return rewardPerTokenStored;
        
        uint256 rewardDelta = (timeDelta * rewardRate * 1e18);
        return rewardPerTokenStored + (rewardDelta / _totalSupply);
    }

    function earned(address account, uint256 stakeIndex) public view returns (uint256) {
        UserStakes storage userStake = userStakes[account];
        if (stakeIndex >= userStake.stakes.length || !userStake.stakes[stakeIndex].exists) {
            return 0;
        }
        
        StakeInfo memory stakeInfo = userStake.stakes[stakeIndex];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 rewardDelta = currentRewardPerToken - stakeInfo.rewardPerTokenPaid;
        return (stakeInfo.amount * rewardDelta / 1e18) + stakeInfo.rewards;
    }

    function totalEarned(address account) public view returns (uint256) {
        UserStakes storage userStake = userStakes[account];
        uint256 total = 0;
        for (uint256 i = 0; i < userStake.stakes.length; i++) {
            if (userStake.stakes[i].exists) {
                total += earned(account, i);
            }
        }
        return total;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return userStakes[account].totalStaked;
    }

    function getStakeCount(address account) external view returns (uint256) {
        return userStakes[account].stakes.length;
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 stakeId = _nextStakeId++;
        uint256 stakeIndex = userStakes[msg.sender].stakes.length;
        
        userStakes[msg.sender].stakes.push(StakeInfo({
            amount: amount,
            lockEndTime: block.timestamp + LOCK_PERIOD,
            rewardPerTokenPaid: rewardPerTokenStored,
            rewards: 0,
            exists: true,
            stakeId: stakeId
        }));
        
        userStakeIndex[msg.sender][stakeId] = stakeIndex;
        userStakes[msg.sender].totalStaked += amount;
        _totalSupply += amount;
        
        emit Staked(msg.sender, stakeId, amount, block.timestamp + LOCK_PERIOD);
    }

    function withdraw(uint256 stakeId) external nonReentrant updateReward(msg.sender) {
        uint256 stakeIndex = userStakeIndex[msg.sender][stakeId];
        require(stakeIndex < userStakes[msg.sender].stakes.length, "Stake not found");
        
        StakeInfo storage stakeInfo = userStakes[msg.sender].stakes[stakeIndex];
        require(stakeInfo.exists && stakeInfo.stakeId == stakeId, "Invalid stake");
        require(block.timestamp >= stakeInfo.lockEndTime, "Lock period not expired");
        
        uint256 amount = stakeInfo.amount;
        uint256 reward = stakeInfo.rewards;
        
        require(amount > 0, "No tokens to withdraw");
        
        // Delete stake record
        delete userStakes[msg.sender].stakes[stakeIndex];
        delete userStakeIndex[msg.sender][stakeId];
        userStakes[msg.sender].totalStaked -= amount;
        _totalSupply -= amount;
        
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, stakeId, amount);
        
        if (reward > 0) {
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, stakeId, reward);
        }
    }

    function getReward(uint256 stakeId) external nonReentrant updateReward(msg.sender) {
        uint256 stakeIndex = userStakeIndex[msg.sender][stakeId];
        require(stakeIndex < userStakes[msg.sender].stakes.length, "Stake not found");
        
        StakeInfo storage stakeInfo = userStakes[msg.sender].stakes[stakeIndex];
        require(stakeInfo.exists && stakeInfo.stakeId == stakeId, "Invalid stake");
        require(block.timestamp >= stakeInfo.lockEndTime, "Lock period not expired");
        
        uint256 reward = earned(msg.sender, stakeIndex);
        if (reward > 0) {
            stakeInfo.rewards = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, stakeId, reward);
        }
    }

    function getAllRewards() external nonReentrant updateReward(msg.sender) {
        UserStakes storage userStake = userStakes[msg.sender];
        uint256 totalReward = 0;
        
        for (uint256 i = 0; i < userStake.stakes.length; i++) {
            if (userStake.stakes[i].exists && block.timestamp >= userStake.stakes[i].lockEndTime) {
                uint256 reward = earned(msg.sender, i);
                if (reward > 0) {
                    userStake.stakes[i].rewards = 0;
                    totalReward += reward;
                }
            }
        }
        
        if (totalReward > 0) {
            rewardsToken.safeTransfer(msg.sender, totalReward);
            emit RewardPaid(msg.sender, 0, totalReward); // stakeId 0 means batch claim
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        require(reward > 0, "No reward");
        require(block.timestamp >= periodFinish, "Cannot notify new reward when old reward period has not finished");
        
        uint256 newRewardRate = reward / REWARDS_DURATION;
        require(newRewardRate > 0, "Reward rate is 0");
        
        rewardRate = newRewardRate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARDS_DURATION;
        
        emit RewardAdded(reward);
    }

    function getStakeInfo(address account, uint256 stakeId) external view returns (
        uint256 amount,
        uint256 lockEndTime,
        uint256 earnedRewards,
        bool isLocked,
        uint256 stakeIndex
    ) {
        uint256 stakeIndex_ = userStakeIndex[account][stakeId];
        if (stakeIndex_ >= userStakes[account].stakes.length) {
            return (0, 0, 0, false, 0);
        }
        
        StakeInfo memory stakeInfo = userStakes[account].stakes[stakeIndex_];
        if (!stakeInfo.exists || stakeInfo.stakeId != stakeId) {
            return (0, 0, 0, false, 0);
        }
        
        return (
            stakeInfo.amount,
            stakeInfo.lockEndTime,
            earned(account, stakeIndex_),
            block.timestamp < stakeInfo.lockEndTime,
            stakeIndex_
        );
    }

    function getUserStakes(address account) external view returns (
        uint256[] memory stakeIds,
        uint256[] memory amounts,
        uint256[] memory lockEndTimes,
        bool[] memory isLocked,
        uint256 totalStaked,
        uint256 totalEarned
    ) {
        UserStakes storage userStake = userStakes[account];
        uint256 activeCount = 0;
        
        // Calculate active stake count
        for (uint256 i = 0; i < userStake.stakes.length; i++) {
            if (userStake.stakes[i].exists) {
                activeCount++;
            }
        }
        
        stakeIds = new uint256[](activeCount);
        amounts = new uint256[](activeCount);
        lockEndTimes = new uint256[](activeCount);
        isLocked = new bool[](activeCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < userStake.stakes.length; i++) {
            if (userStake.stakes[i].exists) {
                stakeIds[index] = userStake.stakes[i].stakeId;
                amounts[index] = userStake.stakes[i].amount;
                lockEndTimes[index] = userStake.stakes[i].lockEndTime;
                isLocked[index] = block.timestamp < userStake.stakes[i].lockEndTime;
                index++;
            }
        }
        
        return (
            stakeIds,
            amounts,
            lockEndTimes,
            isLocked,
            userStake.totalStaked,
            this.totalEarned(account)
        );
    }

    function getTimeUntilUnlock(address account, uint256 stakeId) external view returns (uint256) {
        uint256 stakeIndex = userStakeIndex[account][stakeId];
        if (stakeIndex >= userStakes[account].stakes.length) {
            return 0;
        }
        
        StakeInfo memory stakeInfo = userStakes[account].stakes[stakeIndex];
        if (!stakeInfo.exists || stakeInfo.stakeId != stakeId || block.timestamp >= stakeInfo.lockEndTime) {
            return 0;
        }
        return stakeInfo.lockEndTime - block.timestamp;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = rewardsToken.balanceOf(address(this));
        if (balance > 0) {
            rewardsToken.safeTransfer(owner(), balance);
        }
    }

    function exit(uint256 stakeId) external {
        // One-time withdrawal of specified stake tokens and rewards
        uint256 stakeIndex = userStakeIndex[msg.sender][stakeId];
        require(stakeIndex < userStakes[msg.sender].stakes.length, "Stake not found");
        
        StakeInfo storage stakeInfo = userStakes[msg.sender].stakes[stakeIndex];
        require(stakeInfo.exists && stakeInfo.stakeId == stakeId, "Invalid stake");
        require(block.timestamp >= stakeInfo.lockEndTime, "Lock period not expired");
        
        uint256 amount = stakeInfo.amount;
        uint256 reward = earned(msg.sender, stakeIndex);
        
        require(amount > 0, "No tokens to withdraw");
        
        // Clear stake information
        delete userStakes[msg.sender].stakes[stakeIndex];
        delete userStakeIndex[msg.sender][stakeId];
        userStakes[msg.sender].totalStaked -= amount;
        _totalSupply -= amount;
        
        // Transfer staked tokens
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, stakeId, amount);
        
        // Transfer rewards
        if (reward > 0) {
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, stakeId, reward);
        }
    }
}
