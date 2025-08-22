// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * Linear vesting (for team, etc.): Non-revocable; Owner responsible for creating plans and funding
 * - Each beneficiary has independent plan: start/cliff/duration/total
 * - Beneficiaries call claim() to receive vested portions
 * - For simplicity and security, removed complex "multi-plan aggregation recovery" functions to avoid accidental recovery risks
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LinearVesting is Ownable {
    using SafeERC20 for IERC20;

    struct Schedule {
        uint128 total;     // Total amount
        uint128 released;  // Already released
        uint64  start;     // Start time
        uint32  cliff;     // Cliff period (seconds)
        uint32  duration;  // Linear duration (seconds)
        bool    exists;
    }

    IERC20 public immutable token;
    mapping(address => Schedule) public schedules;

    event ScheduleCreated(address indexed beneficiary, uint256 total, uint64 start, uint32 cliff, uint32 duration);
    event Claimed(address indexed beneficiary, uint256 amount);
    event Funded(uint256 amount);

    constructor(address owner_, IERC20 token_) Ownable(owner_) { token = token_; }

    function createSchedule(
        address beneficiary,
        uint128 total,
        uint64 start,
        uint32 cliff,
        uint32 duration
    ) external onlyOwner {
        require(beneficiary != address(0), "bad beneficiary");
        require(!schedules[beneficiary].exists, "already exists");
        require(total > 0 && duration > 0, "bad params");
        schedules[beneficiary] = Schedule({
            total: total,
            released: 0,
            start: start,
            cliff: cliff,
            duration: duration,
            exists: true
        });
        emit ScheduleCreated(beneficiary, total, start, cliff, duration);
    }

    function fund(uint256 amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(amount);
    }

    function claim() external {
        Schedule storage s = schedules[msg.sender];
        require(s.exists, "no schedule");

        uint256 vested = _vestedAmount(s);
        uint256 releasable = vested - s.released;
        require(releasable > 0, "nothing to claim");

        s.released += uint128(releasable);
        token.safeTransfer(msg.sender, releasable);
        emit Claimed(msg.sender, releasable);
    }

    function _vestedAmount(Schedule memory s) internal view returns (uint256) {
        uint256 t = block.timestamp;
        if (t < s.start + s.cliff) return 0;
        if (t >= s.start + s.duration) return s.total;
        uint256 elapsed = t - s.start;
        return (uint256(s.total) * elapsed) / s.duration;
    }
}
