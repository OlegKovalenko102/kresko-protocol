// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Constants.sol";
import {FixedPoint, CollateralAsset, KrAsset, Action, SafetyState} from "./Structs.sol";
import "./Functions.sol";

using {
    isAccountLiquidatable,
    calculateMaxLiquidatableValueForAssets,
    getAccountMinimumCollateralValue,
    getAccountCollateralValue,
    getMinimumCollateralValue,
    getCollateralValueAndOraclePrice,
    krAssetExists,
    getMintedKreskoAssets,
    getMintedKreskoAssetsIndex,
    getAccountKrAssetValue,
    getKrAssetValue,
    chargeBurnFee,
    calcBurnFee,
    recordCollateralDeposit,
    verifyAndRecordCollateralWithdrawal
} for MinterState global;

struct MinterState {
    /* -------------------------------------------------------------------------- */
    /*                               Initialization                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Initializations
    uint256 initializations;
    /// @notice Domain field separator
    bytes32 domainSeparator;
    /* -------------------------------------------------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                           Configurable Parameters                          */
    /* -------------------------------------------------------------------------- */

    /// @notice The recipient of burn fees.
    address feeRecipient;
    /// @notice The percent fee imposed upon the value of burned krAssets, taken as collateral and sent to feeRecipient.
    FixedPoint.Unsigned burnFee;
    /// @notice The factor used to calculate the incentive a liquidator receives in the form of seized collateral.
    FixedPoint.Unsigned liquidationIncentiveMultiplier;
    /// @notice The absolute minimum ratio of collateral value to debt value used to calculate collateral requirements.
    FixedPoint.Unsigned minimumCollateralizationRatio;
    /// @notice The minimum USD value of an individual synthetic asset debt position.
    FixedPoint.Unsigned minimumDebtValue;
    /// @notice The number of seconds until a price is considered stale
    uint256 secondsUntilStalePrice;
    /* -------------------------------------------------------------------------- */

    /// @notice Flag tells if there is a need to perform safety checks on user actions
    bool safetyStateSet;
    /// @notice asset -> action -> state
    mapping(address => mapping(Action => SafetyState)) safetyState;
    /* -------------------------------------------------------------------------- */
    /*                              Collateral Assets                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Mapping of collateral asset token address to information on the collateral asset.
    mapping(address => CollateralAsset) collateralAssets;
    /**
     * @notice Mapping of account address to a mapping of collateral asset token address to the amount of the collateral
     * asset the account has deposited.
     * @dev Collateral assets must not rebase.
     */
    mapping(address => mapping(address => uint256)) collateralDeposits;
    /// @notice Mapping of account address to an array of the addresses of each collateral asset the account
    /// has deposited.
    mapping(address => address[]) depositedCollateralAssets;
    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Mapping of Kresko asset token address to information on the Kresko asset.
    mapping(address => KrAsset) kreskoAssets;
    /// @notice Mapping of Kresko asset symbols to whether the symbol is used by an existing Kresko asset.
    /// @notice Mapping of account address to a mapping of Kresko asset token address to the amount of the Kresko asset
    /// the account has minted and therefore owes to the protocol.
    mapping(address => mapping(address => uint256)) kreskoAssetDebt;
    /// @notice Mapping of account address to an array of the addresses of each Kresko asset the account has minted.
    mapping(address => address[]) mintedKreskoAssets;
}
