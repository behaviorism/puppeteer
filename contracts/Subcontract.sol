// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

error NotOwner();

contract Subcontract {
    address private constant owner = 0x1c91347f2A44538ce62453BEBd9Aa907C662b4bD;
    bool private autoTransfer;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function execute(
        address contractAddress,
        bytes calldata contractPayload,
        uint256 iterations
    ) external payable onlyOwner {
        for (uint256 i; i < iterations;) {
            (bool success, bytes memory returnData) = contractAddress.call{value: msg.value}(contractPayload);
            if (!success) {
                assembly { revert(add(32, returnData), mload(returnData)) }
            }
            unchecked { ++i; }
        }
    }

    function setAutoTransfer(bool _autoTransfer) external onlyOwner {
       autoTransfer = _autoTransfer;
    }

    function getAutoTransfer() external view onlyOwner returns (bool) {
        return autoTransfer;
    }

    function withdrawERC721(
        address contractAddress,
        address receiver,
        uint256 startToken,
        uint256 endToken
    ) external onlyOwner {
        for (uint256 i = startToken; i < endToken;) {
            IERC721(contractAddress).transferFrom(address(this), receiver, i);
            unchecked { ++i; }
        }
    }

    function withdrawERC1155(address contractAddress, address receiver, uint256 tokenId, uint256 tokensAmount) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(address(this), receiver, tokenId, tokensAmount, "0x0");
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if (autoTransfer) {
            IERC721(msg.sender).transferFrom(operator, tx.origin, tokenId);
        }

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 tokenId,
        uint256 tokensAmount,
        bytes calldata
    ) external returns (bytes4) {
        if (autoTransfer) {
            IERC1155(msg.sender).safeTransferFrom(operator, tx.origin, tokenId, tokensAmount, "0x0");
        }
        
        return this.onERC1155Received.selector;
    }
}