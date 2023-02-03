// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MainContractState.sol";

error AlreadyPurchased();
error IncorrectAmount();

contract Membership is MainContractModule {
    function purchase() external payable {
        if (isOwner[msg.sender]) {
            revert AlreadyPurchased();
        }

        if (msg.value != price) {
            revert IncorrectAmount();
        }

        grantOwnership(msg.sender, false);
    }

    function grantOwnership(address _address, bool checked) internal {
        if (!checked || !isOwner[_address]) {
            if (ownersIndexes[_address] == 0) {
                owners.push(_address);
                unchecked { ownersIndexes[_address] = owners.length - 1; }
            }

            isOwner[_address] = true;
        }
    }

    function removeOwnership(address _address, bool checked) internal {
        if (!checked || isOwner[_address]) {
            delete isOwner[_address];
        }
    }
}