// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * Batch airdrop distributor:
 * - First transfer BLUEBERA to this contract
 * - Owner performs batch transfers (in batches to avoid high gas costs)
 * - Configurable maximum batch size
 * - Can recover unused balance
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirdropDistributor is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public maxBatch = 300;

    event Distributed(address indexed to, uint256 amount);
    event MaxBatchUpdated(uint256 newMaxBatch);
    event Swept(address indexed to, uint256 amount);

    constructor(address owner_, IERC20 token_) Ownable(owner_) {
        token = token_;
    }

    function setMaxBatch(uint256 newMax) external onlyOwner {
        require(newMax > 0 && newMax <= 1000, "unreasonable");
        maxBatch = newMax;
        emit MaxBatchUpdated(newMax);
    }

    function batchDistribute(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
    {
        uint256 len = recipients.length;
        require(len == amounts.length, "length mismatch");
        require(len <= maxBatch, "exceeds maxBatch");

        for (uint256 i; i < len; ) {
            token.safeTransfer(recipients[i], amounts[i]);
            emit Distributed(recipients[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    function sweep(address to) external onlyOwner {
        uint256 bal = token.balanceOf(address(this));
        token.safeTransfer(to, bal);
        emit Swept(to, bal);
    }
}