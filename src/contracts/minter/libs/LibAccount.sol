// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {MinterState} from "../MinterState.sol";
import {KrAsset, CollateralAsset} from "../MinterTypes.sol";
import {RebaseMath, Rebase} from "../../shared/Rebase.sol";
import {IKreskoAsset} from "../../kreskoasset/IKreskoAsset.sol";
import {IKreskoAssetAnchor} from "../../kreskoasset/IKreskoAssetAnchor.sol";
import {irs} from "../InterestRateState.sol";
import {FixedPoint} from "../../libs/FixedPoint.sol";
import {LibDecimals} from "../libs/LibDecimals.sol";
import {WadRay} from "../../libs/WadRay.sol";

library LibAccount {
    using FixedPoint for FixedPoint.Unsigned;
    using RebaseMath for uint256;
    using WadRay for uint256;
    using LibDecimals for FixedPoint.Unsigned;

    /**
     * @notice Gets an array of Kresko assets the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @return An array of addresses of Kresko assets the account has minted.
     */
    function getMintedKreskoAssets(MinterState storage self, address _account)
        internal
        view
        returns (address[] memory)
    {
        return self.mintedKreskoAssets[_account];
    }

    /**
     * @notice Gets an array of collateral assets the account has deposited.
     * @param _account The account to get the deposited collateral assets for.
     * @return An array of addresses of collateral assets the account has deposited.
     */
    function getDepositedCollateralAssets(MinterState storage self, address _account)
        internal
        view
        returns (address[] memory)
    {
        return self.depositedCollateralAssets[_account];
    }

    /**
     * @notice Get `_account` collateral amount for `_asset`
     * @notice Performs rebasing conversion for KreskoAssets
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return Amount of collateral for `_asset`
     */
    function getCollateralDeposits(
        MinterState storage self,
        address _account,
        address _asset
    ) internal view returns (uint256) {
        return self.collateralAssets[_asset].toRebasingAmount(self.collateralDeposits[_account][_asset]);
    }

    /**
     * @notice Calculates if an account's current collateral value is under its minimum collateral value.
     * @dev Returns true if the account's current collateral value is below the minimum collateral value.
     * required to consider the position healthy.
     * @param _account The account to check.
     * @return A boolean indicating if the account can be liquidated.
     */
    function isAccountLiquidatable(MinterState storage self, address _account) internal view returns (bool) {
        return
            self.getAccountCollateralValue(_account).isLessThan(
                self.getAccountMinimumCollateralValueAtRatio(_account, self.liquidationThreshold)
            );
    }

    /**
     * @notice Overload function for calculating liquidatable status with a future liquidated collateral value
     * @param _account The account to check.
     * @param _valueLiquidated Value liquidated, eg. in a batch liquidation
     * @return A boolean indicating if the account can be liquidated.
     */
    function isAccountLiquidatable(
        MinterState storage self,
        address _account,
        FixedPoint.Unsigned memory _valueLiquidated
    ) internal view returns (bool) {
        return
            self.getAccountCollateralValue(_account).sub(_valueLiquidated).isLessThan(
                self.getAccountMinimumCollateralValueAtRatio(_account, self.liquidationThreshold)
            );
    }

    /**
     * @notice Gets the collateral value of a particular account.
     * @dev O(# of different deposited collateral assets by account) complexity.
     * @param _account The account to calculate the collateral value for.
     * @return totalCollateralValue The collateral value of a particular account.
     */
    function getAccountCollateralValue(MinterState storage self, address _account)
        internal
        view
        returns (FixedPoint.Unsigned memory totalCollateralValue)
    {
        address[] memory assets = self.depositedCollateralAssets[_account];
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            (FixedPoint.Unsigned memory collateralValue, ) = self.getCollateralValueAndOraclePrice(
                asset,
                self.getCollateralDeposits(_account, asset),
                false // Take the collateral factor into consideration.
            );
            totalCollateralValue = totalCollateralValue.add(collateralValue);
        }

        return totalCollateralValue;
    }

    /**
     * @notice Get an account's minimum collateral value required
     *         to back a Kresko asset amount at a given collateralization ratio.
     * @dev Accounts that have their collateral value under the minimum collateral value are considered unhealthy,
     *      accounts with their collateral value under the liquidation threshold are considered liquidatable.
     * @param _account The account to calculate the minimum collateral value for.
     * @param _ratio The collateralization ratio required: higher ratio = more collateral required
     * @return The minimum collateral value at a given collateralization ratio for a given account.
     */
    function getAccountMinimumCollateralValueAtRatio(
        MinterState storage self,
        address _account,
        FixedPoint.Unsigned memory _ratio
    ) internal view returns (FixedPoint.Unsigned memory) {
        return self.getAccountKrAssetValue(_account).mul(_ratio);
    }

    /**
     * @notice Gets the Kresko asset value in USD of a particular account.
     * @param _account The account to calculate the Kresko asset value for.
     * @return value The Kresko asset value of a particular account.
     */
    function getAccountKrAssetValue(MinterState storage self, address _account)
        internal
        view
        returns (FixedPoint.Unsigned memory value)
    {
        address[] memory assets = self.mintedKreskoAssets[_account];
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            value = value.add(self.getKrAssetValue(asset, self.getKreskoAssetDebtScaled(_account, asset), false));
        }
        return value;
    }

    /**
     * @notice Get `_account` scaled debt amount for `_asset`
     * @notice debt amount of an account has one external effects
     * * Effect #1: Stability rate accrual through debt index
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return Amount of scaled debt for `_asset`
     */
    function getKreskoAssetDebtScaled(
        MinterState storage self,
        address _account,
        address _asset
    ) internal view returns (uint256) {
        uint256 debt = self.kreskoAssets[_asset].toRebasingAmount(irs().srUserInfo[_account][_asset].debtScaled);
        if (debt == 0) {
            return 0;
        }

        return debt.rayMul(irs().srAssets[_asset].getNormalizedDebtIndex()).rayToWad();
    }

    /**
     * @notice Get `_account` principal debt amount for `_asset`
     * @notice Principal debt amount of an account has one external effects
     * * Effect #1: Asset is rebased due to stock split/reverse split
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return Amount of principal debt for `_asset`
     */
    function getKreskoAssetDebtPrincipal(
        MinterState storage self,
        address _account,
        address _asset
    ) internal view returns (uint256) {
        return self.kreskoAssets[_asset].toRebasingAmount(self.kreskoAssetDebt[_account][_asset]);
    }

    /**
     * @notice Get the total interest accrued on top of debt
     * * eg: scaled debt - principal debt
     * @return assetAmount the interest denominated in _asset
     * @return kissAmount the interest denominated in KISS, ignores K-factor
     **/
    function getKreskoAssetDebtInterest(
        MinterState storage self,
        address _account,
        address _asset
    ) internal view returns (uint256 assetAmount, uint256 kissAmount) {
        assetAmount =
            self.getKreskoAssetDebtScaled(_account, _asset) -
            self.getKreskoAssetDebtPrincipal(_account, _asset);
        kissAmount = self.getKrAssetValue(_asset, assetAmount, true).fromFixedPointPriceToWad();
    }

    /**
     * @notice Gets an index for the Kresko asset the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @param _kreskoAsset The asset lookup address.
     * @return i = index of the minted Kresko asset.
     */
    function getMintedKreskoAssetsIndex(
        MinterState storage self,
        address _account,
        address _kreskoAsset
    ) internal view returns (uint256 i) {
        for (i; i < self.mintedKreskoAssets[_account].length; i++) {
            if (self.mintedKreskoAssets[_account][i] == _kreskoAsset) {
                break;
            }
        }
    }

    /**
     * @notice Gets an index for the collateral asset the account has deposited.
     * @param _account The account to get the index for.
     * @param _collateralAsset The asset lookup address.
     * @return i = index of the minted collateral asset.
     */
    function getDepositedCollateralAssetIndex(
        MinterState storage self,
        address _account,
        address _collateralAsset
    ) internal view returns (uint256 i) {
        for (i; i < self.depositedCollateralAssets[_account].length; i++) {
            if (self.depositedCollateralAssets[_account][i] == _collateralAsset) {
                break;
            }
        }
    }
}
