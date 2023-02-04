// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MainContractState.sol";
import "./Subcontract.sol";

contract Subcontracts is MainContractModule {
    function deploySubcontracts(uint256 amount) external notLocked hasOwnership {
        uint256 currentCount = subcontractsCounts[msg.sender];
        
        unchecked {
            uint256 length = currentCount + amount;
            for (uint256 i = currentCount; i < length; ++i) {
                Clones.cloneDeterministic(
                    getSubcontractImplementation(),
                    keccak256(abi.encodePacked(msg.sender, i))
                );
            }

            subcontractsCounts[msg.sender] += amount;
        }
    }

    function setAutotransfer(bool autoTransfer) external notLocked hasOwnership {
        uint256 length = subcontractsCounts[msg.sender];
        for (uint256 i; i < length;) {
            Subcontract subcontract = Subcontract(getSubcontract(i));
            if (subcontract.getAutoTransfer() != autoTransfer) {
                subcontract.setAutoTransfer(autoTransfer);
            }
            unchecked { ++i; }
        }
    }

    function getSubcontracts() external view returns (address[] memory addresses) {
        uint256 length = subcontractsCounts[msg.sender];

        addresses = new address[](length);

        for (uint256 i; i < length;) {
            addresses[i] = address(getSubcontract(i));
            unchecked { ++i; }
        }
    }


    function getAutotransfers() external view returns (bool[] memory bools) {
        uint256 length = subcontractsCounts[msg.sender];

        bools = new bool[](length);

        for (uint256 i; i < length;) {
            bools[i] = Subcontract(getSubcontract(i)).getAutoTransfer();
            unchecked { ++i; }
        }
    }
}