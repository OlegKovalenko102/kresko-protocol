// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import {DS} from "./storage/DS.sol";
import {LibMeta} from "./libraries/LibMeta.sol";

import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IOwnership} from "./interfaces/IOwnership.sol";
import {IERC165} from "./interfaces/IERC165.sol";

import "hardhat/console.sol";

contract MainDiamondInit {
    function initialize() external {
        DS.DsStorage storage s = DS.ds();
        require(!s.initialized, "DS: Already initialized");
        require(msg.sender == s.contractOwner, "DS: !Owner");

        s.domainSeparator = LibMeta.domainSeparator("Kresko Diamond", "V1");
        s.initialized = true;
    }
}
