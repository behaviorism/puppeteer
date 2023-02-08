// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./MainContractState.sol";

error NotOwner();
error DeploymentError();

contract SubcontractDeployer is MainContractModule {
    address internal implementationAddress;

    function getImplementation() external view returns (address) {
        return implementationAddress;
    }

    function devDestroySubcontractImplementation() external onlyOwner {
        Subcontract(getImplementationAddress(address(this))).destroy();
    }

    function devUpgradeSubcontractImplementation(address newImplementation) external onlyOwner {
        implementationAddress = newImplementation;

        bytes memory metamorphicBytecode = hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";
        address deployedMetamorphicContract;

        assembly {
            deployedMetamorphicContract := create2(
                0,
                add(metamorphicBytecode, 0x20),
                mload(metamorphicBytecode),
                0
            )
        }

        if (deployedMetamorphicContract != getImplementationAddress(address(this))) {
            revert DeploymentError();
        }
    }
}

contract Subcontract {
    address private constant owner = 0xaE036c65C649172b43ef7156b009c6221B596B8b;
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

    function withdrawERC1155Batch(
        address contractAddress,
        address receiver,
        uint256[] calldata tokensIds,
        uint256[] calldata tokensAmounts
    ) external onlyOwner {
        IERC1155(contractAddress).safeBatchTransferFrom(address(this), receiver, tokensIds, tokensAmounts, "0x0");
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

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata tokensIds,
        uint256[] calldata tokensAmounts,
        bytes calldata
    ) external returns (bytes4) {
        if (autoTransfer) {
            IERC1155(msg.sender).safeBatchTransferFrom(operator, tx.origin, tokensIds, tokensAmounts, "0x0");
        }

        return this.onERC1155BatchReceived.selector;
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(tx.origin));
    }
}