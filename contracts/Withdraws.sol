// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MainContractState.sol";
import "./Subcontract.sol";

error IncorrectSubcontractsAmount();

contract Withdraws is MainContractModule {
    function withdrawERC721(
        address contractAddress,
        address receiver,
        uint256 firstTokenId,
        uint256 lastTokenId,
        uint256 startingSubcontractIndex,
        uint256 subcontractsAmount
    ) external hasOwnership {        
        // startingSubcontractIndex is 1 index based (not 0)
        uint256 startSubcontract = startingSubcontractIndex - 1;
        
        uint256 tokensAmount = lastTokenId - firstTokenId + 1;
    
        uint256 mod;
        unchecked { mod = tokensAmount % subcontractsAmount; }

        if (mod != 0) {
            revert IncorrectSubcontractsAmount();
        }

        uint256 tokensPerSubcontract = tokensAmount / subcontractsAmount;

        unchecked {
            for (uint256 i = startSubcontract; i < subcontractsAmount; ++i) {
                uint256 startToken = firstTokenId + i * tokensPerSubcontract;
                uint256 endToken = startToken + tokensPerSubcontract - 1;

                Subcontract(getSubcontract(i)).withdrawERC721(contractAddress, receiver, startToken, endToken);
            }
        }
    }

    function withdrawERC1511(
        address contractAddress,
        address receiver,
        uint256 tokenId,
        uint256 tokensPerSubcontract,
        uint256 startingSubcontractIndex,
        uint256 subcontractsAmount
    ) external onlyOwner {
        // startingSubcontractIndex is 1 index based (not 0)
        uint256 startSubcontract = startingSubcontractIndex - 1;
        for (uint256 i = startSubcontract; i < subcontractsAmount;) {
            Subcontract(getSubcontract(i)).withdrawERC1155(contractAddress, receiver, tokenId, tokensPerSubcontract);
            unchecked { ++i; }
        }
    }
}