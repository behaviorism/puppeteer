// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MainContractState.sol";
import "./Membership.sol";

contract Developer is MainContractModule, Membership {
    function devWithdraw() external onlyOwner {
        (bool success, bytes memory returnData) = owner().call{value: address(this).balance}("");
        if (!success) {
            assembly { revert(add(32, returnData), mload(returnData)) }
        }
    }

    function devSetOwners(address[] memory addresses, bool status) external onlyOwner {
        uint256 length = addresses.length;

        unchecked {
            if (status) {
                for (uint256 i; i < length; ++i) {
                    grantOwnership(addresses[i], true);
                }
            } else {
                for (uint256 i; i < length; ++i) {
                    removeOwnership(addresses[i], true);
                }
            }
        }
    }

    function devGetOwners() external view onlyOwner returns (address[] memory) {
        return owners;
    }

    function devSetPrice(uint256 newPrice) external onlyOwner {
        price = newPrice * 1 wei;
    }

    function devSetLocked(bool status) external onlyOwner {
        locked = status;
    }
}