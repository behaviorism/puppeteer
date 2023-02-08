// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

error MissingPurchase();
error ContractLocked();

contract MainContractModule is OwnableUpgradeable {
    bool public locked;
    uint256 public price = 0.05 ether;

    address[] internal owners;
    mapping(address => uint256) internal ownersIndexes;
    mapping(address => bool) internal isOwner;

    mapping(address => uint256) internal subcontractsCounts;

    modifier hasOwnership() {
        if (!isOwner[msg.sender]) {
            revert MissingPurchase();
        }
        _;
    }

    modifier notLocked() {
        if (locked) {
            revert ContractLocked();
        }
        _;
    }

    function getImplementationAddress(address creatorAddress) internal pure returns (address) {
        return address(uint160(uint(keccak256(
            abi.encodePacked(
                hex"ff",
                creatorAddress,
                uint(0),
                keccak256(abi.encodePacked(hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"))
            )
        ))));
    }

    function getSubcontract(uint256 i) internal view returns (address) {
        return Clones.predictDeterministicAddress(getImplementationAddress(address(this)), keccak256(abi.encodePacked(msg.sender, i)));
    }
}