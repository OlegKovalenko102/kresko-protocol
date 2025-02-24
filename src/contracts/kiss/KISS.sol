// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import {IKreskoAssetIssuer} from "../kreskoasset/IKreskoAssetIssuer.sol";
import {IKISS} from "./interfaces/IKISS.sol";
import {Role} from "../libs/Authorization.sol";

/* solhint-disable not-rely-on-time */

/**
 * @title Kresko Integrated Stable System
 * @author Kresko
 */
contract KISS is IKISS, IKreskoAssetIssuer, ERC20PresetMinterPauser {
    bytes32 public constant OPERATOR_ROLE = 0x112e48a576fb3a75acc75d9fcf6e0bc670b27b1dbcd2463502e10e68cf57d6fd;
    uint256 public constant OPERATOR_ROLE_PERIOD = 1 minutes; // testnet

    /* -------------------------------------------------------------------------- */
    /*                                   Layout                                   */
    /* -------------------------------------------------------------------------- */

    // AccessControl
    uint256 public operatorRoleTimestamp;
    address public pendingOperator;
    address public kresko;

    // ERC20
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */
    event NewMinterInitiated(address pendingNewMinter, uint256 unlockTimestamp);
    event NewMinter(address newMinter);

    /* -------------------------------------------------------------------------- */
    /*                                   Writes                                   */
    /* -------------------------------------------------------------------------- */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 dec_,
        address kresko_
    ) ERC20PresetMinterPauser(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = dec_;
        kresko = kresko_;

        // AccessControl
        // 1. Setup admin
        // 2. Kresko protocol can mint
        // 3. Remove unnecessary MINTER_ROLE from multisig
        _setupRole(Role.ADMIN, _msgSender());
        _setupRole(Role.OPERATOR, kresko_);
        _revokeRole(MINTER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId != 0xffffffff &&
            (interfaceId == type(IKISS).interfaceId ||
                interfaceId == type(IKreskoAssetIssuer).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07);
    }

    /**
     * @notice Allows OPERATOR_ROLE to mint tokens
     *
     * @param _to address to mint tokens to
     * @param _amount amount to mint
     */
    function issue(uint256 _amount, address _to) public override onlyRole(Role.OPERATOR) returns (uint256) {
        require(msg.sender.code.length > 0, "KISS: EOA");
        _mint(_to, _amount);
        return _amount;
    }

    /**
     * @notice Allows OPERATOR_ROLE to burn tokens
     *
     * @param _from address to burn tokens from
     * @param _amount amount to burn
     */
    function destroy(uint256 _amount, address _from) external onlyRole(Role.OPERATOR) returns (uint256) {
        require(msg.sender.code.length > 0, "KISS: EOA");
        _burn(_from, _amount);
        return _amount;
    }

    /**
     * @notice Overrides `AccessControl.grantRole` for following:
     * * Implement a cooldown period of `OPERATOR_ROLE_PERIOD` minutes for setting a new OPERATOR_ROLE
     * * EOA cannot be granted the operator role
     *
     * @notice OPERATOR_ROLE can still be revoked without this cooldown period
     * @notice PAUSER_ROLE can still be granted without this cooldown period
     * @param _role role to grant
     * @param _to address to grant role for
     */
    function grantRole(bytes32 _role, address _to)
        public
        override(AccessControl, IAccessControl)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Default behavior
        if (_role != Role.OPERATOR) {
            _grantRole(_role, _to);
            return;
        }

        // Handle operator role
        require(_to.code.length > 0, "KISS: EOA");
        if (pendingOperator != address(0)) {
            // Ensure cooldown period
            require(operatorRoleTimestamp < block.timestamp, "KISS: !OPERATOR_ROLE_PERIOD");
            // Grant role
            _grantRole(Role.OPERATOR, pendingOperator);
            emit NewMinter(_msgSender());
            // Reset pending owner
            // No need to touch the timestamp (next call will just trigger the cooldown period)
            pendingOperator = address(0);
        } else if (operatorRoleTimestamp != 0) {
            // Do not allow more than 2 minters
            require(getRoleMemberCount(Role.OPERATOR) <= 1, "KISS: !minterRevoked");
            // Set the timestamp for the cooldown period
            operatorRoleTimestamp = block.timestamp + OPERATOR_ROLE_PERIOD;
            // Set the pending minter, execution to upper clause next call
            pendingOperator = _to;
            emit NewMinterInitiated(_to, operatorRoleTimestamp);
        } else {
            // Initialize converter
            _grantRole(Role.OPERATOR, _to);
            emit NewMinter(_to);
            // Set the timestamp, execution is not coming here again
            operatorRoleTimestamp = block.timestamp;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   TESTNET                                  */
    /* -------------------------------------------------------------------------- */
    function setMetadata(string memory _newName, string memory _newSymbol) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _name = _newSymbol;
        _symbol = _newName;
    }

    function convertToShares(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    function convertToAssets(uint256 shares) external pure returns (uint256) {
        return shares;
    }
}
