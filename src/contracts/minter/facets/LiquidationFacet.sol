// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

// solhint-disable not-rely-on-time

import {ILiquidationFacet} from "../interfaces/ILiquidationFacet.sol";
import {IKreskoAssetIssuer} from "../../kreskoasset/IKreskoAssetIssuer.sol";

import {Arrays} from "../../libs/Arrays.sol";
import {Error} from "../../libs/Errors.sol";
import {LibDecimals, FixedPoint} from "../libs/LibDecimals.sol";
import {LibCalculation} from "../libs/LibCalculation.sol";
import {WadRay} from "../../libs/WadRay.sol";
import {MinterEvent} from "../../libs/Events.sol";

import {SafeERC20Upgradeable, IERC20Upgradeable} from "../../shared/SafeERC20Upgradeable.sol";
import {DiamondModifiers} from "../../shared/Modifiers.sol";

import {Constants, KrAsset} from "../MinterTypes.sol";
import {ms, MinterState} from "../MinterStorage.sol";
import {irs} from "../InterestRateState.sol";

/**
 * @author Kresko
 * @title LiquidationFacet
 * @notice Main end-user functionality concerning liquidations within the Kresko protocol
 */
contract LiquidationFacet is DiamondModifiers, ILiquidationFacet {
    using Arrays for address[];
    using LibDecimals for uint8;
    using LibDecimals for FixedPoint.Unsigned;
    using LibDecimals for uint256;
    using WadRay for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint256;
    using FixedPoint for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Attempts to liquidate an account by repaying the portion of the account's Kresko asset
     *         princpal debt, receiving in return a portion of the account's collateral at a discounted rate.
     * @param _account The account to attempt to liquidate.
     * @param _repayKreskoAsset The address of the Kresko asset to be repaid.
     * @param _repayAmount The amount of the Kresko asset to be repaid.
     * @param _collateralAssetToSeize The address of the collateral asset to be seized.
     * @param _mintedKreskoAssetIndex The index of the Kresko asset in the account's minted assets array.
     * @param _depositedCollateralAssetIndex Index of the collateral asset in the account's collateral assets array.
     */

    function liquidate(
        address _account,
        address _repayKreskoAsset,
        uint256 _repayAmount,
        address _collateralAssetToSeize,
        uint256 _mintedKreskoAssetIndex,
        uint256 _depositedCollateralAssetIndex
    ) external nonReentrant {
        MinterState storage s = ms();
        {
            // No zero repays
            require(_repayAmount > 0, Error.ZERO_REPAY);
            // Borrower cannot liquidate themselves
            require(msg.sender != _account, Error.SELF_LIQUIDATION);
            // krAsset exists
            require(s.kreskoAssets[_repayKreskoAsset].exists, Error.KRASSET_DOESNT_EXIST);
            // Check that this account is below its minimum collateralization ratio and can be liquidated.
            require(s.isAccountLiquidatable(_account), Error.NOT_LIQUIDATABLE);
            // Collateral exists
            require(s.collateralAssets[_collateralAssetToSeize].exists, Error.COLLATERAL_DOESNT_EXIST);
        }

        // Repay amount USD = repay amount * KR asset USD exchange rate.

        FixedPoint.Unsigned memory repayAmountUSD = s.kreskoAssets[_repayKreskoAsset].fixedPointUSD(_repayAmount);
        // Get the scaled debt amount
        uint256 krAssetDebt = s.getKreskoAssetDebtPrincipal(_account, _repayKreskoAsset);
        // Avoid stack too deep error
        {
            // Liquidator may not repay more value than what the liquidation pair allows
            // Nor repay more tokens than the account holds debt for the asset
            FixedPoint.Unsigned memory maxLiquidation = s.calculateMaxLiquidatableValueForAssets(
                _account,
                _repayKreskoAsset,
                _collateralAssetToSeize
            );
            require(krAssetDebt >= _repayAmount, Error.KRASSET_BURN_AMOUNT_OVERFLOW);
            require(repayAmountUSD.isLessThanOrEqual(maxLiquidation), Error.LIQUIDATION_OVERFLOW);
        }

        // Charge burn fee from the liquidated user
        s.chargeCloseFee(_account, _repayKreskoAsset, _repayAmount);

        // Perform the liquidation by burning KreskoAssets from msg.sender
        // Get the amount of collateral to seize
        uint256 seizedAmount = _liquidateAssets(
            _account,
            _repayAmount,
            s.collateralAssets[_collateralAssetToSeize].decimals.fromCollateralFixedPointAmount(
                LibCalculation.calculateAmountToSeize(
                    s.liquidationIncentiveMultiplier,
                    s.collateralAssets[_collateralAssetToSeize].fixedPointPrice(),
                    repayAmountUSD
                )
            ),
            _repayKreskoAsset,
            _mintedKreskoAssetIndex,
            _collateralAssetToSeize,
            _depositedCollateralAssetIndex
        );

        // Send liquidator the seized collateral.
        IERC20Upgradeable(_collateralAssetToSeize).safeTransfer(msg.sender, seizedAmount);

        emit MinterEvent.LiquidationOccurred(
            _account,
            // solhint-disable-next-line avoid-tx-origin
            tx.origin,
            _repayKreskoAsset,
            _repayAmount,
            _collateralAssetToSeize,
            seizedAmount
        );
    }

    /**
     * @notice Burns KreskoAssets from the liquidator, calculates collateral assets to send to liquidator.
     * @param _account The account to attempt to liquidate.
     * @param _repayAmount The amount of the Kresko asset to be repaid.
     * @param _seizeAmount The calculated amount of collateral assets to be seized.
     * @param _repayKreskoAsset The address of the Kresko asset to be repaid.
     * @param _mintedKreskoAssetIndex The index of the Kresko asset in the user's minted assets array.
     * @param _collateralAssetToSeize The address of the collateral asset to be seized.
     * @param _depositedCollateralAssetIndex The index of the collateral asset in the account's collateral assets array.
     */
    function _liquidateAssets(
        address _account,
        uint256 _repayAmount,
        uint256 _seizeAmount,
        address _repayKreskoAsset,
        uint256 _mintedKreskoAssetIndex,
        address _collateralAssetToSeize,
        uint256 _depositedCollateralAssetIndex
    ) internal returns (uint256) {
        MinterState storage s = ms();
        KrAsset memory krAsset = s.kreskoAssets[_repayKreskoAsset];

        {
            // Subtract repaid Kresko assets from liquidated user's recorded debt.
            uint256 destroyed = IKreskoAssetIssuer(krAsset.anchor).destroy(_repayAmount, msg.sender);
            s.kreskoAssetDebt[_account][_repayKreskoAsset] -= destroyed;

            // Update stability rate values
            uint256 newDebtIndex = irs().srAssets[_repayKreskoAsset].updateDebtIndex();
            uint256 amountScaled = destroyed.wadToRay().rayDiv(newDebtIndex);

            // Update scaled values for the user
            irs().srUserInfo[_account][_repayKreskoAsset].debtScaled -= uint128(amountScaled);
            irs().srUserInfo[_account][_repayKreskoAsset].lastDebtIndex = uint128(newDebtIndex);

            // Update the global stability rate
            irs().srAssets[_repayKreskoAsset].updateStabilityRate();
        }

        // If the liquidation repays the user's entire Kresko asset balance, remove it from minted assets array.
        if (s.kreskoAssetDebt[_account][_repayKreskoAsset] == 0) {
            s.mintedKreskoAssets[_account].removeAddress(_repayKreskoAsset, _mintedKreskoAssetIndex);
        }

        // Get users collateral deposit amount
        uint256 collateralDeposit = s.getCollateralDeposits(_account, _collateralAssetToSeize);

        if (collateralDeposit > _seizeAmount) {
            s.collateralDeposits[_account][_collateralAssetToSeize] -= ms()
                .collateralAssets[_collateralAssetToSeize]
                .toNonRebasingAmount(_seizeAmount);
        } else {
            // This clause means user either has collateralDeposits equal or less than the _seizeAmount
            _seizeAmount = collateralDeposit;
            // So we set the collateralDeposits to 0
            s.collateralDeposits[_account][_collateralAssetToSeize] = 0;
            // And remove the asset from the deposits array.
            s.depositedCollateralAssets[_account].removeAddress(
                _collateralAssetToSeize,
                _depositedCollateralAssetIndex
            );
        }

        // Return the actual amount seized
        return _seizeAmount;
    }

    /**
     * @notice Calculates if an account's current collateral value is under its minimum collateral value
     * @dev Returns true if the account's current collateral value is below the minimum collateral value
     * required to consider the position healthy.
     * @param _account The account to check.
     * @return A boolean indicating if the account can be liquidated.
     */
    function isAccountLiquidatable(address _account) external view returns (bool) {
        return ms().isAccountLiquidatable(_account);
    }

    /**
     * @dev Calculates the total value that can be liquidated for a liquidation pair
     * @param _account address to liquidate
     * @param _repayKreskoAsset address of the kreskoAsset being repaid on behalf of the liquidatee
     * @param _collateralAssetToSeize address of the collateral asset being seized from the liquidatee
     * @return maxLiquidatableUSD USD value that can be liquidated, 0 if the pair has no liquidatable value
     */
    function calculateMaxLiquidatableValueForAssets(
        address _account,
        address _repayKreskoAsset,
        address _collateralAssetToSeize
    ) public view returns (FixedPoint.Unsigned memory maxLiquidatableUSD) {
        return ms().calculateMaxLiquidatableValueForAssets(_account, _repayKreskoAsset, _collateralAssetToSeize);
    }
}
