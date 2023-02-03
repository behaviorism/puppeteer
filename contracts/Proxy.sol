// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./MainContractState.sol";

contract Proxy is Initializable, UUPSUpgradeable, MainContractModule {
    function initialize() external initializer {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}