// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {IBurnFacet} from "../interfaces/IBurnFacet.sol";
import {IKreskoAsset} from "../../kreskoasset/IKreskoAsset.sol";

import {Arrays} from "../../libs/Arrays.sol";
import {Error} from "../../libs/Errors.sol";
import {Role} from "../../libs/Authorization.sol";
import {MinterEvent} from "../../libs/Events.sol";

import {DiamondModifiers, MinterModifiers} from "../../shared/Modifiers.sol";
import {Action, FixedPoint, KrAsset} from "../MinterTypes.sol";
import {ms, MinterState} from "../MinterStorage.sol";
import {irs} from "../InterestRateState.sol";

/**
 * @author Kresko
 * @title BurnFacet
 * @notice Main end-user functionality concerning burning of kresko assets
 */
contract BurnFacet is DiamondModifiers, MinterModifiers, IBurnFacet {
    using FixedPoint for FixedPoint.Unsigned;
    using Arrays for address[];

    /**
     * @notice Burns existing Kresko assets.
     * @param _account The address to burn kresko assets for
     * @param _kreskoAsset The address of the Kresko asset.
     * @param _burnAmount The amount of the Kresko asset to be burned.
     * @param _mintedKreskoAssetIndex The index of the collateral asset in the user's minted assets array.
     * @notice Only needed if burning all principal debt of a particular collateral asset.
     */
    function burnKreskoAsset(
        address _account,
        address _kreskoAsset,
        uint256 _burnAmount,
        uint256 _mintedKreskoAssetIndex
    ) external nonReentrant kreskoAssetExists(_kreskoAsset) onlyRoleIf(_account != msg.sender, Role.MANAGER) {
        require(_burnAmount > 0, Error.ZERO_BURN);
        MinterState storage s = ms();

        if (s.safetyStateSet) {
            ensureNotPaused(_kreskoAsset, Action.Repay);
        }

        // Get accounts principal debt
        uint256 debtAmount = s.getKreskoAssetDebtPrincipal(_account, _kreskoAsset);

        if (_burnAmount != type(uint256).max) {
            require(_burnAmount <= debtAmount, Error.KRASSET_BURN_AMOUNT_OVERFLOW);
            // Ensure principal left is either 0 or >= minDebtValue
            _burnAmount = s.ensureNotDustPosition(_kreskoAsset, _burnAmount, debtAmount);
        } else {
            // _burnAmount of uint256 max, burn all principal debt
            _burnAmount = debtAmount;
        }

        // If sender repays all principal debt of asset with no stability rate, remove it from minted assets array.
        // For assets with stability rate the revomal is done when repaying interest
        if (irs().srAssets[_kreskoAsset].asset == address(0) && _burnAmount == debtAmount) {
            s.mintedKreskoAssets[_account].removeAddress(_kreskoAsset, _mintedKreskoAssetIndex);
        }
        // Charge the burn fee from collateral of _account
        s.chargeCloseFee(_account, _kreskoAsset, _burnAmount);

        // Record the burn
        s.repay(_kreskoAsset, s.kreskoAssets[_kreskoAsset].anchor, _burnAmount, _account);

        // Emit logs
        emit MinterEvent.KreskoAssetBurned(_account, _kreskoAsset, _burnAmount);
    }

    /// @dev Simple check for the enabled flag
    function ensureNotPaused(address _asset, Action _action) internal view {
        require(!ms().safetyState[_asset][_action].pause.enabled, Error.ACTION_PAUSED_FOR_ASSET);
    }
}
