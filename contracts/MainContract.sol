// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Subcontract.sol";
import "./Withdraws.sol";
import "./Proxy.sol";
import "./Developer.sol";
import "./Membership.sol";
import "./Subcontract.sol";
import "./Subcontracts.sol";

error InsufficientSubcontracts();
error InsufficientPayloads();

contract MainContract is MainContractModule, Membership, Developer, Withdraws, Proxy, Subcontracts, SubcontractDeployer {
    function callSubcontracts(
        address contractAddress,
        uint256 subcontractsAmount,
        uint256 iterationsPerContract,
        uint256 transactionValue,
        bytes calldata callPayload,
        bytes[] calldata callPayloads,
        bool revertOnFail
    ) external payable notLocked hasOwnership {
        unchecked {
            if (msg.value != subcontractsAmount * transactionValue * iterationsPerContract) {
                revert IncorrectAmount();
            }
        }

        // Switches to specific payloads for each wallet if callPayloads is not empty
        // Also checks if there are enough payloads for all subcontracts
        if (callPayloads.length != 0) {
            if (subcontractsAmount != callPayloads.length) {
                revert InsufficientPayloads();
            }
        }

        if (subcontractsCounts[msg.sender] < subcontractsAmount) {
            revert InsufficientSubcontracts();
        }

        if (callPayloads.length != 0) {
            for (uint256 i; i < subcontractsAmount;) {
                try Subcontract(getSubcontract(i)).execute(
                    contractAddress,
                    callPayloads[i],
                    iterationsPerContract
                ) {} catch(bytes memory error) {
                    if (revertOnFail) {
                        assembly { revert(add(32, error), mload(error)) }
                    }

                    return;
                }
                unchecked { ++i; }
            }
        } else {
            for (uint256 i; i < subcontractsAmount;) {
                try Subcontract(getSubcontract(i)).execute(
                    contractAddress,
                    callPayload,
                    iterationsPerContract
                ) {} catch(bytes memory error) {
                    if (revertOnFail) {
                        assembly { revert(add(32, error), mload(error)) }
                    }

                    return;
                }
                unchecked { ++i; }
            }
        }
    }
}